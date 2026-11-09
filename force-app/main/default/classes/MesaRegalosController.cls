/**
 * Controlador de los componentes del sitio (Experience Cloud).
 *
 * SEGURIDAD: el usuario guest NO tiene permisos sobre Contact, CampaignMember ni Opportunity.
 * Solo tiene acceso a esta clase, y esta clase solo opera con un token aleatorio de 64 caracteres
 * o con datos que ya son públicos (muro y avance) o, en el caso del
 * registro, con las protecciones descritas en registrarDonador.
 * Por eso corre "without sharing". Cualquier método nuevo debe validar primero.
 */
public without sharing class MesaRegalosController {

    // Montos. Si cambian, hay que cambiarlos también en el componente mesaDonacion. (A MEJORAR)
    private static final Decimal MONTO_MINIMO = 100.0;
    private static final Decimal MONTO_MAXIMO = 1000000.0;
    private static final Map<String, Decimal> PAQUETES = new Map<String, Decimal>{
        'P1000' => 1000.0,
        'P3000' => 3000.0,
        'P5000' => 5000.0
    };

    // Registros nuevos que se aceptan por hora desde el sitio (freno contra abuso).
    @TestVisible private static Integer maxRegistrosPorHora = 30;

    private static final String MSG_ENLACE = 'Este enlace no es válido. Revisa que lo hayas copiado completo.';
    private static final String MSG_VISIBILIDAD = 'La visibilidad debe ser "Publica" o "Privada".';
    private static final String MSG_REGISTRO_DUPLICADO =
        'No pudimos completar el registro en línea. Si ya participaste en la materia, usa el enlace '
        + 'personal que te enviamos; si no, el equipo se pondrá en contacto contigo.';
    private static final Set<String> VISIBILIDADES = new Set<String>{ 'Publica', 'Privada' };
    
    // ---- Formulario único sin token: visibilidad, consentimiento y límites ----
    private static final Set<String> VISIBILIDADES_NUEVAS = new Set<String>{ 'Publica', 'Anonima' };
    private static final Set<String> CONSENTIMIENTOS = new Set<String>{ 'Si', 'No' };
    private static final String NOMBRE_ANONIMO = 'Anónimo';
    // Bajas que se aceptan por hora desde el sitio (freno contra abuso).
    @TestVisible private static Integer maxBajasPorHora = 60;

    // ---------- DTOs (lo único que viaja entre el sitio y Salesforce) ----------

    public class InvitacionDTO {
        @AuraEnabled public String nombre;
        @AuraEnabled public String campana;
        @AuraEnabled public String generacion;
        @AuraEnabled public String cuentaTrailhead;
        @AuraEnabled public String certificaciones;
        @AuraEnabled public Boolean consentimientoContacto;
        @AuraEnabled public Boolean esEmpresa;
        @AuraEnabled public String empresa;
    }

    public class ReencuentroInput {
        @AuraEnabled public String generacion;
        @AuraEnabled public String cuentaTrailhead;
        @AuraEnabled public String certificaciones;
        @AuraEnabled public Boolean consentimientoContacto;
        @AuraEnabled public Boolean darseDeBaja;
        @AuraEnabled public String versionAviso;
    }

    public class DonativoInput {
        @AuraEnabled public Decimal monto;      // solo se usa con paquete = 'Abierto'
        @AuraEnabled public String paquete;     // P1000, P3000, P5000 o Abierto
        @AuraEnabled public String visibilidad;
        @AuraEnabled public String linkedinUrl;
        @AuraEnabled public Boolean consentimientoPublicacion;
        @AuraEnabled public Boolean mostrarMonto;
        @AuraEnabled public Boolean aceptaAviso;
        @AuraEnabled public String versionAviso;
    }

    public class RegistroInput {
        @AuraEnabled public String nombre;
        @AuraEnabled public String apellidos;
        @AuraEnabled public String correo;
        @AuraEnabled public Boolean esEmpresa;
        @AuraEnabled public String empresa;
        @AuraEnabled public Boolean aceptaAviso;
        @AuraEnabled public String versionAviso;
        @AuraEnabled public String sitioWeb;    // campo trampa: una persona nunca lo llena
    }

    public class RegistroResultado {
        @AuraEnabled public Boolean exito;
        @AuraEnabled public String mensaje;
        @AuraEnabled public String token;       // solo cuando la persona se registra a sí misma
    }

    public class MuroItem {
        @AuraEnabled public String nombre;
        @AuraEnabled public String generacion;
        @AuraEnabled public Decimal monto;
        @AuraEnabled public Boolean esEmpresa;
    }

    public class AvanceDTO {
        @AuraEnabled public Decimal total;
        @AuraEnabled public Decimal meta;
        @AuraEnabled public Integer donativos;
        @AuraEnabled public Decimal porcentaje;
    }

    public class RegistroDonativoInput {
        @AuraEnabled public String paquete;      // P1000, P3000, P5000 o Abierto
        @AuraEnabled public Decimal monto;       // solo con paquete = 'Abierto'
        @AuraEnabled public String visibilidad;  // Publica o Anonima
        @AuraEnabled public String nombre;
        @AuraEnabled public String apellidos;
        @AuraEnabled public String correo;
        @AuraEnabled public Boolean esEmpresa;
        @AuraEnabled public String nombreEmpresa;
        @AuraEnabled public String linkedinUrl;
        @AuraEnabled public String consentimientoAvisos;  // Si o No
        @AuraEnabled public Boolean consentimientoPublicacion;
        @AuraEnabled public Boolean aceptaAviso;
        @AuraEnabled public String versionAviso;
        @AuraEnabled public String sitioWeb;     // campo trampa: una persona nunca lo llena
    }

    public class RegistroDonativoResultado {
        @AuraEnabled public Boolean exito;
        @AuraEnabled public String mensaje;
        @AuraEnabled public Id donativoId;       // se usa como client_reference_id del pago
    }

    // ---------- Entrada: formulario de reencuentro ----------

    @AuraEnabled
    public static InvitacionDTO obtenerInvitacion(String token) {
        CampaignMember cm = buscarMiembro(token);
        InvitacionDTO d = new InvitacionDTO();
        d.nombre = cm.Contact.Name;
        d.campana = cm.Campaign.Name;
        d.generacion = cm.Contact.Generacion__c;
        d.cuentaTrailhead = cm.Contact.Cuenta_Trailhead__c;
        d.certificaciones = cm.Contact.Certificaciones__c;
        d.consentimientoContacto = cm.Contact.Consentimiento_Contacto__c;
        d.esEmpresa = esEmpresa(cm);
        d.empresa = d.esEmpresa ? cm.Contact.Account.Name : null;
        return d;
    }

    //@AuraEnabled
    public static void actualizarDatos(String token, ReencuentroInput datos) {
        CampaignMember cm = buscarMiembro(token);
        System.debug('DATOS RECIBIDOS actualizarDatos: ' + JSON.serialize(datos));
        if (datos == null) {
            throw crearError('No recibimos tus datos.');
        }
        Boolean yaConsentia = cm.Contact.Consentimiento_Contacto__c == true;
        Contact c = new Contact(
            Id = cm.ContactId,
            Generacion__c = limpiar(datos.generacion, 20),
            Cuenta_Trailhead__c = limpiar(datos.cuentaTrailhead, 255),
            Certificaciones__c = limpiar(datos.certificaciones, 255)
        );
        if (datos.darseDeBaja == true) {
            c.HasOptedOutOfEmail = true;
            c.Consentimiento_Contacto__c = false;
        } else {
            c.Consentimiento_Contacto__c = datos.consentimientoContacto == true;
            if (c.Consentimiento_Contacto__c) {
                c.HasOptedOutOfEmail = false;
                if (!yaConsentia) {
                    c.Fecha_Consentimiento__c = System.now();
                    c.Version_Aviso_Privacidad__c = limpiar(datos.versionAviso, 20);
                }
            }
        }
        update c;
        MesaRegalosService.avanzarEstado(cm, 'Respondió');
    }

    // ---------- Registro de donadores nuevos o invitados ----------

    /**
     * Crea un contacto (y su empresa, si aplica) y lo agrega a la campaña con su propio token.
     *
     * Dos modos:
     *  - Sin tokenInvitador: la persona se registra a sí misma. Se le devuelve su token para que
     *    pueda continuar a donar.
     *  - Con tokenInvitador: un ex-alumno invita a otra persona. NO se devuelve el token de la
     *    persona invitada (el equipo le hará llegar su enlace); solo se guarda quién la invitó.
     *
     * Protecciones: campo trampa, tope de registros por hora, no se actualiza ningún contacto
     * existente (si el correo ya existe se responde un mensaje genérico) y nada se lee del
     * sistema salvo el token propio recién creado.
     */
    //@AuraEnabled
    public static RegistroResultado registrarDonador(Id campaignId, String tokenInvitador, RegistroInput datos) {
        RegistroResultado res = new RegistroResultado();
        res.exito = false;
        if (datos == null) {
            throw crearError('No recibimos tus datos.');
        }
        if (!String.isBlank(datos.sitioWeb)) {
            // Un bot llenó el campo trampa: se responde "bien" sin guardar nada.
            res.exito = true;
            res.mensaje = 'Listo.';
            return res;
        }

        String nombre = limpiar(datos.nombre, 40);
        String apellidos = limpiar(datos.apellidos, 80);
        String correo = limpiar(datos.correo, 80);
        Boolean conEmpresa = datos.esEmpresa == true;
        String empresa = conEmpresa ? limpiar(datos.empresa, 120) : null;
        if (nombre == null || apellidos == null) {
            throw crearError('Escribe nombre y apellidos.');
        }
        if (correo == null || !esCorreoValido(correo)) {
            throw crearError('Escribe un correo válido.');
        }
        if (conEmpresa && empresa == null) {
            throw crearError('Escribe el nombre de la empresa.');
        }
        if (datos.aceptaAviso != true) {
            throw crearError('Para continuar debes aceptar el aviso de privacidad.');
        }

        Id campana = campaignId;
        Id invitadoPor = null;
        String origen = 'Sitio';
        if (!String.isBlank(tokenInvitador)) {
            CampaignMember invitador = buscarMiembro(tokenInvitador);
            campana = invitador.CampaignId;
            invitadoPor = invitador.ContactId;
            origen = 'Invitacion';
        }
        if (campana == null || [SELECT COUNT() FROM Campaign WHERE Id = :campana AND IsActive = true] == 0) {
            throw crearError('No pudimos identificar la campaña.');
        }

        Datetime desde = Datetime.now().addHours(-1);
        Integer recientes = [
            SELECT COUNT() FROM Contact
            WHERE Origen_Registro__c IN ('Sitio', 'Invitacion') AND CreatedDate >= :desde
        ];
        if (recientes >= maxRegistrosPorHora) {
            throw crearError('Estamos recibiendo muchas solicitudes. Intenta de nuevo más tarde.');
        }

        if (![SELECT Id FROM Contact WHERE Email = :correo LIMIT 1].isEmpty()) {
            res.mensaje = MSG_REGISTRO_DUPLICADO;
            return res;
        }

        Id cuentaId = null;
        if (conEmpresa) {
            List<Account> existentes = [SELECT Id FROM Account WHERE Name = :empresa LIMIT 1];
            if (existentes.isEmpty()) {
                Account a = new Account(Name = empresa);
                insertarSinBloqueoDeDuplicados(a);
                cuentaId = a.Id;
            } else {
                cuentaId = existentes[0].Id;
            }
        }

        Contact c = new Contact(
            FirstName = nombre,
            LastName = apellidos,
            Email = correo,
            AccountId = cuentaId,
            Registro_Como_Empresa__c = conEmpresa,
            Origen_Registro__c = origen,
            Invitado_Por__c = invitadoPor,
            Version_Aviso_Privacidad__c = limpiar(datos.versionAviso, 20)
        );
        insertarSinBloqueoDeDuplicados(c);

        CampaignMember cm = new CampaignMember(CampaignId = campana, ContactId = c.Id);
        String estado = MesaRegalosService.estadoSiExiste(
            campana, origen == 'Sitio' ? 'Interesado' : 'Identificado'
        );
        if (estado != null) {
            cm.Status = estado;
        }
        insert cm;

        res.exito = true;
        if (origen == 'Sitio') {
            res.token = [SELECT Token_Acceso__c FROM CampaignMember WHERE Id = :cm.Id].Token_Acceso__c;
            res.mensaje = '¡Listo! Ya puedes continuar.';
        } else {
            res.mensaje = 'Listo. El equipo hará llegar la invitación a ' + nombre + '.';
        }
        return res;
    }

    // ---------- Salida: promesa de donativo (el pago se confirma aparte) ----------

    /**
     * Registra el donativo como "Prospecting" (promesa). Pasa a "Closed Won" solo cuando se
     * confirma el pago (MesaRegalosService.confirmarPago). Devuelve el Id para enlazar con el pago.
     * El monto de un paquete lo fija el servidor; el navegador no puede cambiarlo.
     */
    //@AuraEnabled
    public static Id registrarPromesa(String token, DonativoInput datos) {
        CampaignMember cm = buscarMiembro(token);
        if (datos == null) {
            throw crearError('No recibimos tu donativo.');
        }

        System.debug('DATOS RECIBIDOS registrarPromesa: ' + JSON.serialize(datos));

        String paquete = datos.paquete;
        Decimal monto;
        if (paquete != null && PAQUETES.containsKey(paquete)) {
            monto = PAQUETES.get(paquete);
        } else {
            paquete = 'Abierto';
            monto = datos.monto;
            if (monto == null || monto <= 0) {
                throw crearError('Indica un monto válido.');
            }
            if (monto < MONTO_MINIMO) {
                throw crearError('El monto mínimo es de $100 MXN.');
            }
            if (monto > MONTO_MAXIMO) {
                throw crearError('Para montos mayores, ponte en contacto con el equipo organizador.');
            }
            monto = monto.setScale(2);
        }

        if (datos.aceptaAviso != true) {
            throw crearError('Para continuar debes aceptar el aviso de privacidad.');
        }
        if (String.isBlank(datos.visibilidad) || !VISIBILIDADES.contains(datos.visibilidad)) {
            throw crearError('Elige si tu donativo será público o privado.');
        }
        Boolean esPublico = datos.visibilidad == 'Publica';
        if (esPublico) {
            if (datos.consentimientoPublicacion != true) {
                throw crearError('Para hacer público tu donativo necesitamos tu autorización.');
            }
            if (!esUrlLinkedIn(datos.linkedinUrl)) {
                throw crearError('Escribe la dirección de LinkedIn (https://www.linkedin.com/in/... o /company/...).');
            }
        }

        Boolean comoEmpresa = esEmpresa(cm);
        String quien = comoEmpresa ? cm.Contact.Account.Name : cm.Contact.Name;
        Opportunity o = new Opportunity(
            Name = ('Donativo - ' + quien + ' - ' + Date.today().format()).abbreviate(120),
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Amount = monto,
            CampaignId = cm.CampaignId,
            AccountId = comoEmpresa ? cm.Contact.AccountId : null,
            Contacto_Donador__c = cm.ContactId,
            Visibilidad__c = datos.visibilidad,
            LinkedIn_URL__c = esPublico ? limpiar(datos.linkedinUrl, 255) : null,
            Consentimiento_Publicacion__c = esPublico,
            Mostrar_Monto__c = esPublico && datos.mostrarMonto == true,
            Version_Aviso_Privacidad__c = limpiar(datos.versionAviso, 20)
        );
        insert o;
        MesaRegalosService.avanzarEstado(cm, 'Redirigido a donar');
        return o.Id;
    }

    // ---------- Datos públicos: muro y avance ----------

    @AuraEnabled(cacheable=true)
    public static List<MuroItem> obtenerMuro(Id campaignId) {
        List<MuroItem> resultado = new List<MuroItem>();
        if (campaignId == null) {
            return resultado;
        }
        for (Reconocimiento_Publico__c r : [
            SELECT Name, Generacion__c, Monto__c, Mostrar_Monto__c, Es_Empresa__c
            FROM Reconocimiento_Publico__c
            WHERE Campana__c = :campaignId AND Mostrar_En_Muro__c = true
            ORDER BY CreatedDate DESC
            LIMIT 200
        ]) {
            MuroItem m = new MuroItem();
            m.nombre = r.Name;
            m.generacion = r.Generacion__c;
            m.monto = r.Mostrar_Monto__c == true ? r.Monto__c : null;
            m.esEmpresa = r.Es_Empresa__c == true;
            resultado.add(m);
        }
        return resultado;
    }

    /** La meta es el campo "Ingreso esperado" (ExpectedRevenue) de la campaña. */
    @AuraEnabled(cacheable=true)
    public static AvanceDTO obtenerAvance(Id campaignId) {
        AvanceDTO a = new AvanceDTO();
        a.total = 0;
        a.meta = 0;
        a.donativos = 0;
        a.porcentaje = 0;
        if (campaignId == null) {
            return a;
        }
        List<Campaign> camp = [SELECT ExpectedRevenue FROM Campaign WHERE Id = :campaignId LIMIT 1];
        if (camp.isEmpty()) {
            return a;
        }
        AggregateResult ar = [
            SELECT SUM(Amount) total, COUNT(Id) donativos
            FROM Opportunity
            WHERE CampaignId = :campaignId AND StageName = 'Closed Won'
        ];
        Decimal total = (Decimal) ar.get('total');
        if (total != null) {
            a.total = total;
        }
        a.donativos = (Integer) ar.get('donativos');
        Decimal meta = camp[0].ExpectedRevenue;
        if (meta != null) {
            a.meta = meta;
        }
        if (a.meta > 0) {
            Decimal pct = (a.total * 100 / a.meta).setScale(0);
            Decimal tope = 100;
            a.porcentaje = pct > tope ? tope : pct;
        }
        return a;
    }

        // ---------- Formulario único: registro + donación (sin token) ----------

    @AuraEnabled
    public static RegistroDonativoResultado guardarDonativo(Id campaignId, String datosJson) {
        return registrarDonativo(campaignId, (RegistroDonativoInput) leerJson(datosJson, RegistroDonativoInput.class));
    }

    /**
     * Registro y donación en un paso. Sin token: la persona se identifica con su correo.
     *  - Si el correo ya existe se usa ese Contacto y NO se modifica (salvo el consentimiento de
     *    avisos, y solo si estaba vacío). Nada del sistema se devuelve al navegador.
     *  - Anónima: se ignora lo que el navegador envíe de nombre, empresa y LinkedIn.
     *  - Empresa: el nombre de la empresa se guarda en nombre y apellido. No se crean Accounts.
     *  - El monto de un paquete lo fija el servidor.
     */
    public static RegistroDonativoResultado registrarDonativo(Id campaignId, RegistroDonativoInput datos) {
        RegistroDonativoResultado res = new RegistroDonativoResultado();
        res.exito = false;
        if (datos == null) {
            throw crearError('No recibimos tus datos.');
        }
        if (!String.isBlank(datos.sitioWeb)) {
            // Un bot llenó el campo trampa: se responde "bien" sin guardar nada.
            res.exito = true;
            res.mensaje = 'Listo.';
            return res;
        }

        // Monto
        Decimal monto;
        if (datos.paquete != null && PAQUETES.containsKey(datos.paquete)) {
            monto = PAQUETES.get(datos.paquete);
        } else {
            monto = datos.monto;
            if (monto == null || monto <= 0) {
                throw crearError('Indica un monto válido.');
            }
            if (monto < MONTO_MINIMO) {
                throw crearError('El monto mínimo es de $100 MXN.');
            }
            if (monto > MONTO_MAXIMO) {
                throw crearError('Para montos mayores, ponte en contacto con el equipo organizador.');
            }
            monto = monto.setScale(2);
        }

        // Visibilidad, correo y consentimientos
        if (String.isBlank(datos.visibilidad) || !VISIBILIDADES_NUEVAS.contains(datos.visibilidad)) {
            throw crearError('Elige si tu donativo será público o anónimo.');
        }
        Boolean esAnonimo = datos.visibilidad == 'Anonima';
        String correo = limpiar(datos.correo, 80);
        if (correo == null || !esCorreoValido(correo)) {
            throw crearError('Escribe un correo válido.');
        }
        if (String.isBlank(datos.consentimientoAvisos) || !CONSENTIMIENTOS.contains(datos.consentimientoAvisos)) {
            throw crearError('Indica si quieres recibir avisos de próximos eventos y donaciones.');
        }
        if (datos.consentimientoPublicacion != true) {
            throw crearError('Para continuar necesitamos tu autorización para publicar tu donativo.');
        }
        if (datos.aceptaAviso != true) {
            throw crearError('Para continuar debes aceptar el aviso de privacidad.');
        }

        // Identidad: anónima, empresa o persona
        Boolean comoEmpresa = !esAnonimo && datos.esEmpresa == true;
        String nombre;
        String apellidos;
        String nombreVisible;
        if (esAnonimo) {
            nombre = NOMBRE_ANONIMO;
            apellidos = NOMBRE_ANONIMO;
            nombreVisible = NOMBRE_ANONIMO;
        } else if (comoEmpresa) {
            String empresa = limpiar(datos.nombreEmpresa, 80);
            if (empresa == null) {
                throw crearError('Escribe el nombre de la empresa.');
            }
            nombre = limpiar(empresa, 40);
            apellidos = empresa;
            nombreVisible = empresa;
        } else {
            nombre = limpiar(datos.nombre, 40);
            apellidos = limpiar(datos.apellidos, 80);
            if (nombre == null || apellidos == null) {
                throw crearError('Escribe tu nombre y apellidos.');
            }
            nombreVisible = (nombre + ' ' + apellidos).abbreviate(80);
        }

        // LinkedIn: opcional, solo en Pública, y si viene se valida
        String linkedin = null;
        if (!esAnonimo && !String.isBlank(datos.linkedinUrl)) {
            if (!esUrlLinkedIn(datos.linkedinUrl)) {
                throw crearError('La dirección de LinkedIn no es válida (https://www.linkedin.com/in/... o /company/...).');
            }
            linkedin = limpiar(datos.linkedinUrl, 255);
        }

        // Campaña y freno contra abuso
        if (campaignId == null || [SELECT COUNT() FROM Campaign WHERE Id = :campaignId AND IsActive = true] == 0) {
            throw crearError('No pudimos identificar la campaña.');
        }
        Datetime desde = Datetime.now().addHours(-1);
        Integer recientes = [
            SELECT COUNT() FROM Opportunity WHERE Nombre_Visible__c != null AND CreatedDate >= :desde
        ];
        if (recientes >= maxRegistrosPorHora) {
            throw crearError('Estamos recibiendo muchas solicitudes. Intenta de nuevo más tarde.');
        }

        // Contacto: se reutiliza el del correo; si no existe, se crea
        Contact c = buscarContactoPorCorreo(correo);
        if (c == null) {
            c = new Contact(FirstName = nombre, LastName = apellidos, Email = correo);
            Database.SaveResult r = Database.insert(c, false);
            if (!r.isSuccess()) {
                // Una regla de duplicados pudo bloquearlo: si el correo ya existe, se usa ese Contacto.
                Contact existente = buscarContactoPorCorreo(correo);
                if (existente != null) {
                    c = existente;
                } else {
                    insertarSinBloqueoDeDuplicados(c);
                }
            }
        }
        // El consentimiento solo se guarda si estaba vacío: un "No" previo no se cambia aquí.
        if (c.Consentimiento_Avisos__c == null) {
            update new Contact(
                Id = c.Id,
                Consentimiento_Avisos__c = datos.consentimientoAvisos,
                Fecha_Consentimiento__c = System.now(),
                Version_Aviso_Privacidad__c = limpiar(datos.versionAviso, 20)
            );
        }

        // Miembro de campaña: se reutiliza si ya está; si no, se crea
        CampaignMember cm = null;
        for (CampaignMember m : [
            SELECT Id, CampaignId, Status FROM CampaignMember
            WHERE CampaignId = :campaignId AND ContactId = :c.Id LIMIT 1
        ]) {
            cm = m;
        }
        if (cm == null) {
            cm = new CampaignMember(CampaignId = campaignId, ContactId = c.Id);
            String estado = MesaRegalosService.estadoSiExiste(campaignId, 'Registrado');
            if (estado != null) {
                cm.Status = estado;
            }
            insert cm;
        } else {
            MesaRegalosService.avanzarEstado(cm, 'Registrado');
        }

        // Donativo (promesa): pasa a Closed Won cuando se confirma el pago
        Opportunity o = new Opportunity(
            Name = ('Donativo - ' + nombreVisible + ' - ' + Date.today().format()).abbreviate(120),
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Amount = monto,
            CampaignId = campaignId,
            Contacto_Donador__c = c.Id,
            Visibilidad__c = datos.visibilidad,
            Nombre_Visible__c = nombreVisible,
            Donacion_Empresa__c = comoEmpresa,
            LinkedIn_URL__c = linkedin,
            Consentimiento_Publicacion__c = true,
            Version_Aviso_Privacidad__c = limpiar(datos.versionAviso, 20)
        );
        insert o;
        MesaRegalosService.avanzarEstado(cm, 'Redirigido a donar');

        res.exito = true;
        res.mensaje = 'Listo.';
        res.donativoId = o.Id;
        return res;
    }

    // ---------- Baja de avisos (página /baja) ----------

    /**
     * Da de baja el correo indicado. Responde siempre lo mismo, exista o no el correo,
     * para no revelar quién está registrado.
     */
    @AuraEnabled
    public static void darseDeBaja(String correo, String sitioWeb) {
        if (!String.isBlank(sitioWeb)) {
            return;
        }
        String mail = limpiar(correo, 80);
        if (mail == null || !esCorreoValido(mail)) {
            throw crearError('Escribe un correo válido.');
        }
        Datetime desde = Datetime.now().addHours(-1);
        Integer recientes = [
            SELECT COUNT() FROM Contact
            WHERE HasOptedOutOfEmail = true AND Consentimiento_Avisos__c = 'No' AND LastModifiedDate >= :desde
        ];
        if (recientes >= maxBajasPorHora) {
            throw crearError('Estamos recibiendo muchas solicitudes. Intenta de nuevo más tarde.');
        }
        List<Contact> lista = [SELECT Id FROM Contact WHERE Email = :mail];
        for (Contact ct : lista) {
            ct.HasOptedOutOfEmail = true;
            ct.Consentimiento_Avisos__c = 'No';
            ct.Fecha_Consentimiento__c = System.now();
        }
        if (!lista.isEmpty()) {
            update lista;
        }
    }

    private static Contact buscarContactoPorCorreo(String correo) {
        List<Contact> r = [
            SELECT Id, Consentimiento_Avisos__c FROM Contact
            WHERE Email = :correo ORDER BY CreatedDate ASC LIMIT 1
        ];
        return r.isEmpty() ? null : r[0];
    }

    // ---------- Utilidades ----------

    private static CampaignMember buscarMiembro(String token) {
        if (String.isBlank(token) || token.length() != 64) {
            throw crearError(MSG_ENLACE);
        }
        List<CampaignMember> r = [
            SELECT Id, CampaignId, Status, ContactId, Campaign.Name, Contact.Name,
                   Contact.AccountId, Contact.Account.Name, Contact.Registro_Como_Empresa__c,
                   Contact.Generacion__c, Contact.Cuenta_Trailhead__c,
                   Contact.Certificaciones__c, Contact.Consentimiento_Contacto__c
            FROM CampaignMember
            WHERE Token_Acceso__c = :token AND ContactId != null
            LIMIT 1
        ];
        if (r.isEmpty()) {
            throw crearError(MSG_ENLACE);
        }
        return r[0];
    }

    /** Verdadero si la persona se registró en representación de una empresa con nombre. */
    private static Boolean esEmpresa(CampaignMember cm) {
        return cm.Contact.Registro_Como_Empresa__c == true
            && cm.Contact.AccountId != null
            && !String.isBlank(cm.Contact.Account.Name);
    }

    /** Inserta aun si una regla de duplicados de la org marcaría una alerta (en API bloquearía). */
    private static void insertarSinBloqueoDeDuplicados(SObject registro) {
        Database.DMLOptions opciones = new Database.DMLOptions();
        opciones.DuplicateRuleHeader.allowSave = true;
        Database.SaveResult r = Database.insert(registro, opciones);
        if (!r.isSuccess()) {
            throw crearError('No pudimos guardar el registro. Intenta de nuevo.');
        }
    }

        // ---------- Puntos de entrada del sitio ----------
    // Los datos llegan como texto JSON y se convierten aquí. Así no dependen de cómo el
    // sitio traduzca objetos al llegar a Apex.

    @AuraEnabled
    public static void guardarReencuentro(String token, String datosJson) {
        actualizarDatos(token, (ReencuentroInput) leerJson(datosJson, ReencuentroInput.class));
    }

    @AuraEnabled
    public static Id guardarPromesa(String token, String datosJson) {
        return registrarPromesa(token, (DonativoInput) leerJson(datosJson, DonativoInput.class));
    }

    @AuraEnabled
    public static RegistroResultado guardarRegistro(Id campaignId, String tokenInvitador, String datosJson) {
        return registrarDonador(campaignId, tokenInvitador, (RegistroInput) leerJson(datosJson, RegistroInput.class));
    }

    private static Object leerJson(String texto, Type tipo) {
        if (String.isBlank(texto)) {
            return null;
        }
        try {
            return JSON.deserialize(texto, tipo);
        } catch (JSONException e) {
            throw crearError('No pudimos leer tus datos. Intenta de nuevo.');
        }
    }

    private static AuraHandledException crearError(String mensaje) {
        AuraHandledException e = new AuraHandledException(mensaje);
        e.setMessage(mensaje);
        return e;
    }

    private static String limpiar(String valor, Integer maximo) {
        if (valor == null) {
            return null;
        }
        String t = valor.trim();
        if (t.length() > maximo) {
            t = t.substring(0, maximo);
        }
        return String.isBlank(t) ? null : t;
    }

    @TestVisible
    private static Boolean esUrlLinkedIn(String url) {
        if (String.isBlank(url)) {
            return false;
        }
        return Pattern.matches('^https://([a-z]{2,3}\\.)?linkedin\\.com/(in|company)/[^\\s]+$', url.trim().toLowerCase());
    }

    @TestVisible
    private static Boolean esCorreoValido(String correo) {
        return Pattern.matches('^[A-Za-z0-9._%+\\-]+@[A-Za-z0-9.\\-]+\\.[A-Za-z]{2,}$', correo);
    }
}
