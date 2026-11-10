/**
 * Controlador de los componentes del sitio (Experience Cloud).
 *
 * SEGURIDAD: el usuario guest NO tiene permisos sobre Contact, CampaignMember ni Opportunity.
 * Solo tiene acceso a esta clase, que corre "without sharing". Por eso solo expone datos que ya
 * son públicos (muro y avance) o recibe datos con las protecciones de registrarDonativo y
 * darseDeBaja: campo trampa, topes por hora, validaciones y nada del sistema se devuelve al navegador.
 * Cualquier método nuevo debe validar primero.
 */
public without sharing class MesaRegalosController {

    // Montos. Si cambian, hay que cambiarlos también en mesaRegistro y mesaInicio. (A MEJORAR)
    private static final Decimal MONTO_MINIMO = 100.0;
    private static final Decimal MONTO_MAXIMO = 1000000.0;
    private static final Map<String, Decimal> PAQUETES = new Map<String, Decimal>{
        'P1000' => 1000.0,
        'P3000' => 3000.0,
        'P5000' => 5000.0
    };

    private static final Set<String> VISIBILIDADES = new Set<String>{ 'Publica', 'Anonima' };
    private static final Set<String> CONSENTIMIENTOS = new Set<String>{ 'Si', 'No' };
    private static final String NOMBRE_ANONIMO = 'Anónimo';

    // Topes por hora desde el sitio (freno contra abuso).
    @TestVisible private static Integer maxRegistrosPorHora = 30;
    @TestVisible private static Integer maxBajasPorHora = 60;

    // ---------- DTOs (lo único que viaja entre el sitio y Salesforce) ----------

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

    public class MuroItem {
        @AuraEnabled public String nombre;
        @AuraEnabled public Decimal monto;
        @AuraEnabled public Boolean esEmpresa;
    }

    public class AvanceDTO {
        @AuraEnabled public Decimal total;
        @AuraEnabled public Decimal meta;
        @AuraEnabled public Integer donativos;
        @AuraEnabled public Decimal porcentaje;
    }

    public class CampanaDTO {
        @AuraEnabled public Id id;
        @AuraEnabled public String nombre;
        @AuraEnabled public String descripcion;
        @AuraEnabled public Decimal meta;
        @AuraEnabled public Decimal total;
        @AuraEnabled public Integer donativos;
        @AuraEnabled public Decimal porcentaje;
        @AuraEnabled public Date fechaFin;
        @AuraEnabled public Boolean activa;     // false = ya cerró (se muestra en "Campañas pasadas")
        @AuraEnabled public String imagenUrl;   // null = la campaña no tiene imagen
    }

    // ---------- Datos públicos: muro y avance ----------

    @AuraEnabled(cacheable=true)
    public static List<MuroItem> obtenerMuro(Id campaignId) {
        List<MuroItem> resultado = new List<MuroItem>();
        if (campaignId == null) {
            return resultado;
        }
        for (Reconocimiento_Publico__c r : [
            SELECT Name, Monto__c, Es_Empresa__c
            FROM Reconocimiento_Publico__c
            WHERE Campana__c = :campaignId AND Mostrar_En_Muro__c = true
            ORDER BY CreatedDate DESC
            LIMIT 200
        ]) {
            MuroItem m = new MuroItem();
            m.nombre = r.Name;
            m.monto = r.Monto__c;   // el monto se muestra siempre, también en Anónimo
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

    // ---------- Campañas: lista y página de presentación ----------

    /**
     * Lista las campañas publicadas para el sitio central (US-01). Solo devuelve datos que ya son
     * públicos: nombre, descripción, meta, avance y fecha de cierre.
     *  - Una campaña se publica si está activa (IsActive) y ya empezó.
     *  - Está "activa" si no tiene fecha de cierre o esa fecha no ha pasado; si ya pasó, se
     *    devuelve con activa = false para la pestaña "Campañas pasadas".
     *  - Pausar una campaña (IsActive = false) la oculta en ambas vistas, sin tocar sus fechas.
     * El recaudado cuenta solo donativos pagados (Closed Won); las promesas pendientes no suman.
     */
    @AuraEnabled(cacheable=true)
    public static List<CampanaDTO> obtenerCampanas() {
        Date hoy = Date.today();
        List<Campaign> campanas = [
            SELECT Id, Name, Description, ExpectedRevenue, EndDate, Imagen_Url__c
            FROM Campaign
            WHERE IsActive = true AND (StartDate = null OR StartDate <= :hoy)
            ORDER BY StartDate DESC NULLS LAST, Name
            LIMIT 100
        ];

        Map<Id, AggregateResult> pagados = new Map<Id, AggregateResult>();
        for (AggregateResult ar : [
            SELECT CampaignId, SUM(Amount) total, COUNT(Id) donativos
            FROM Opportunity
            WHERE CampaignId IN :campanas AND StageName = 'Closed Won'
            GROUP BY CampaignId
        ]) {
            pagados.put((Id) ar.get('CampaignId'), ar);
        }

        List<CampanaDTO> resultado = new List<CampanaDTO>();
        for (Campaign c : campanas) {
            resultado.add(armarCampanaDTO(c, pagados.get(c.Id), hoy));
        }
        return resultado;
    }

    /**
     * Devuelve una sola campaña para su página de presentación (US-02), o null si el Id no es
     * válido, no existe o no está publicada (pausada o aún no empieza). Una campaña que ya cerró
     * SÍ se devuelve, con activa = false, para mostrarla en solo lectura. Recibe String para que un
     * Id mal escrito en la dirección no provoque un error técnico.
     */
    @AuraEnabled(cacheable=true)
    public static CampanaDTO obtenerCampana(String campaignId) {
        if (String.isBlank(campaignId) || (campaignId.length() != 15 && campaignId.length() != 18)) {
            return null;
        }
        Id cid;
        try {
            cid = Id.valueOf(campaignId);
        } catch (Exception e) {
            return null;
        }
        if (cid.getSobjectType() != Campaign.SObjectType) {
            return null;
        }
        Date hoy = Date.today();
        List<Campaign> campanas = [
            SELECT Id, Name, Description, ExpectedRevenue, EndDate, Imagen_Url__c
            FROM Campaign
            WHERE Id = :cid AND IsActive = true AND (StartDate = null OR StartDate <= :hoy)
            LIMIT 1
        ];
        if (campanas.isEmpty()) {
            return null;
        }
        AggregateResult pagado = [
            SELECT SUM(Amount) total, COUNT(Id) donativos
            FROM Opportunity
            WHERE CampaignId = :cid AND StageName = 'Closed Won'
        ];
        return armarCampanaDTO(campanas[0], pagado, hoy);
    }

    /** Arma el DTO público de una campaña. `pagado` puede ser nulo o traer total nulo (sin pagos). */
    private static CampanaDTO armarCampanaDTO(Campaign c, AggregateResult pagado, Date hoy) {
        CampanaDTO d = new CampanaDTO();
        d.id = c.Id;
        d.nombre = c.Name;
        d.descripcion = c.Description;
        d.meta = c.ExpectedRevenue == null ? 0 : c.ExpectedRevenue;
        d.total = 0;
        d.donativos = 0;
        if (pagado != null) {
            Decimal total = (Decimal) pagado.get('total');
            d.total = total == null ? 0 : total;
            d.donativos = (Integer) pagado.get('donativos');
        }
        d.porcentaje = 0;
        if (d.meta > 0) {
            Decimal pct = (d.total * 100 / d.meta).setScale(0);
            Decimal tope = 100;
            d.porcentaje = pct > tope ? tope : pct;
        }
        d.fechaFin = c.EndDate;
        d.activa = c.EndDate == null || c.EndDate >= hoy;
        // Solo se publica si es https; cualquier otro esquema se descarta.
        d.imagenUrl = (c.Imagen_Url__c != null && c.Imagen_Url__c.startsWithIgnoreCase('https://'))
            ? c.Imagen_Url__c : null;
        return d;
    }

    // ---------- Formulario único: registro + donación (sin token) ----------

    // Los datos llegan como texto JSON y se convierten aquí. Así no dependen de cómo el
    // sitio traduzca objetos al llegar a Apex.
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
        if (String.isBlank(datos.visibilidad) || !VISIBILIDADES.contains(datos.visibilidad)) {
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

    // ---------- Utilidades ----------

    private static Contact buscarContactoPorCorreo(String correo) {
        List<Contact> r = [
            SELECT Id, Consentimiento_Avisos__c FROM Contact
            WHERE Email = :correo ORDER BY CreatedDate ASC LIMIT 1
        ];
        return r.isEmpty() ? null : r[0];
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