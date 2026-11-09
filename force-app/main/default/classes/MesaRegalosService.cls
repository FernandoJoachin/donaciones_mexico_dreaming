/**
 * Lógica de negocio de la mesa de regalos.
 * Corre "without sharing" porque la usa el controlador del sitio público (usuario guest),
 * que no tiene acceso directo a Contact, CampaignMember ni Opportunity.
 */
public without sharing class MesaRegalosService {

    // Orden del embudo. Solo se avanza, nunca se retrocede.
    public static final List<String> ORDEN_ESTADOS = new List<String>{
        'Identificado', 'Contactado', 'Registrado', 'Respondió', 'Interesado', 'Redirigido a donar', 'Donó'
    };

    /** 32 bytes aleatorios en hexadecimal = 64 caracteres. */
    public static String nuevoToken() {
        return EncodingUtil.convertToHex(Crypto.generateAesKey(256));
    }

    /**
     * Avanza el estado del miembro en el embudo, si el nuevo estado es posterior
     * y existe como estado de esa campaña. Si no existe, no hace nada (no rompe el flujo).
     */
    public static void avanzarEstado(CampaignMember cm, String nuevoEstado) {
        Integer actual = ORDEN_ESTADOS.indexOf(cm.Status);
        Integer nuevo = ORDEN_ESTADOS.indexOf(nuevoEstado);
        if (nuevo < 0 || nuevo <= actual) {
            return;
        }
        Set<String> disponibles = new Set<String>();
        for (CampaignMemberStatus s : [SELECT Label FROM CampaignMemberStatus WHERE CampaignId = :cm.CampaignId]) {
            disponibles.add(s.Label);
        }
        if (!disponibles.contains(nuevoEstado)) {
            return;
        }
        update new CampaignMember(Id = cm.Id, Status = nuevoEstado);
    }

    /** Devuelve la etiqueta si ese estado existe en la campaña; si no, null. */
    public static String estadoSiExiste(Id campaignId, String etiqueta) {
        for (CampaignMemberStatus s : [SELECT Label FROM CampaignMemberStatus WHERE CampaignId = :campaignId]) {
            if (s.Label == etiqueta) {
                return etiqueta;
            }
        }
        return null;
    }

    /**
     * Marca donativos como pagados. Es idempotente: si el donativo ya estaba pagado
     * (por ejemplo, un webhook que llega dos veces) no hace nada.
     * Se puede invocar desde un Flow (botón para el equipo) o desde un futuro webhook de pagos.
     */
    @InvocableMethod(
        label='Confirmar pago de donativo'
        description='Marca el donativo como pagado, avanza el embudo y crea el reconocimiento público si hubo consentimiento.'
    )
    public static void confirmarPago(List<Id> opportunityIds) {
        if (opportunityIds == null || opportunityIds.isEmpty()) {
            return;
        }
        List<Opportunity> pendientes = [
            SELECT Id, Amount, CampaignId, StageName, AccountId, Account.Name, Contacto_Donador__c,
                   Contacto_Donador__r.Name, Contacto_Donador__r.Generacion__c,
                   Visibilidad__c, LinkedIn_URL__c, Consentimiento_Publicacion__c, Mostrar_Monto__c, Nombre_Visible__c, Donacion_Empresa__c
            FROM Opportunity
            WHERE Id IN :opportunityIds AND StageName != 'Closed Won'
        ];
        if (pendientes.isEmpty()) {
            return;
        }

        List<Reconocimiento_Publico__c> reconocimientos = new List<Reconocimiento_Publico__c>();
        Set<Id> contactos = new Set<Id>();
        Set<Id> campanas = new Set<Id>();
        Set<String> pares = new Set<String>();

        for (Opportunity o : pendientes) {
            o.StageName = 'Closed Won';
            o.CloseDate = Date.today();
            if (o.Contacto_Donador__c != null && o.CampaignId != null) {
                contactos.add(o.Contacto_Donador__c);
                campanas.add(o.CampaignId);
                pares.add(o.CampaignId + '|' + o.Contacto_Donador__c);
            }
            if (o.Nombre_Visible__c != null) {
                // Formulario único (Pública o Anónima)
                if (o.Consentimiento_Publicacion__c == true) {
                    reconocimientos.add(armarReconocimientoNuevo(o));
                }
            } else if (o.Visibilidad__c == 'Publica'
                && o.Consentimiento_Publicacion__c == true
                && o.Contacto_Donador__c != null) {
                reconocimientos.add(armarReconocimiento(o));
            }
        }
        update pendientes;
        if (!reconocimientos.isEmpty()) {
            insert reconocimientos;
        }

        // Embudo: estos son pocos registros (un pago a la vez). Si algún día se cargan
        // pagos en lote, conviene agrupar las consultas de CampaignMemberStatus.
        if (!contactos.isEmpty()) {
            for (CampaignMember cm : [
                SELECT Id, CampaignId, ContactId, Status
                FROM CampaignMember
                WHERE ContactId IN :contactos AND CampaignId IN :campanas
            ]) {
                if (pares.contains(cm.CampaignId + '|' + cm.ContactId)) {
                    avanzarEstado(cm, 'Donó');
                }
            }
        }
    }

    /** Reconocimiento del formulario único: el monto se muestra siempre y la Anónima oculta todo lo demás. */
    private static Reconocimiento_Publico__c armarReconocimientoNuevo(Opportunity o) {
        Boolean anonimo = o.Visibilidad__c == 'Anonima';
        String nombre = (anonimo || String.isBlank(o.Nombre_Visible__c)) ? 'Anónimo' : o.Nombre_Visible__c;
        return new Reconocimiento_Publico__c(
            Name = nombre.abbreviate(80),
            Monto__c = o.Amount,
            Mostrar_Monto__c = true,
            Mostrar_En_Muro__c = true,
            LinkedIn_URL__c = anonimo ? null : o.LinkedIn_URL__c,
            Es_Empresa__c = !anonimo && o.Donacion_Empresa__c == true,
            Donativo__c = o.Id,
            Campana__c = o.CampaignId
        );
    }

    private static Reconocimiento_Publico__c armarReconocimiento(Opportunity o) {
        // Si el donativo es de una empresa, el reconocimiento va a nombre de la empresa
        // (y sin generación, que es un dato de la persona).
        Boolean esEmpresa = o.AccountId != null && !String.isBlank(o.Account.Name);
        String nombre = esEmpresa ? o.Account.Name : o.Contacto_Donador__r.Name;
        String gen = esEmpresa ? null : o.Contacto_Donador__r.Generacion__c;
        String texto = 'Gracias a ' + nombre
            + (String.isBlank(gen) ? '' : ' (generación ' + gen + ')')
            + ' por sumarse a la campaña de México Dreaming. #Ohana #MexicoDreaming';
        return new Reconocimiento_Publico__c(
            Name = nombre.abbreviate(80),
            Generacion__c = gen,
            Monto__c = o.Amount,
            Mostrar_Monto__c = o.Mostrar_Monto__c,
            Mostrar_En_Muro__c = true,
            LinkedIn_URL__c = o.LinkedIn_URL__c,
            Estado_Publicacion__c = 'Pendiente',
            Texto_Sugerido__c = texto,
            Donativo__c = o.Id,
            Campana__c = o.CampaignId
        );
    }
}
