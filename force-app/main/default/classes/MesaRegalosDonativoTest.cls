@IsTest
private class MesaRegalosDonativoTest {

    @TestSetup
    static void datos() {
        Campaign c = new Campaign(Name = 'México Dreaming TEST', IsActive = true, ExpectedRevenue = 10000);
        insert c;

        List<CampaignMemberStatus> estados = new List<CampaignMemberStatus>();
        Integer orden = 10;
        for (String etiqueta : MesaRegalosService.ORDEN_ESTADOS) {
            estados.add(new CampaignMemberStatus(
                CampaignId = c.Id,
                Label = etiqueta,
                SortOrder = orden++,
                HasResponded = etiqueta != 'Identificado' && etiqueta != 'Contactado'
            ));
        }
        insert estados;

        insert new Contact(FirstName = 'Ana', LastName = 'Prueba', Email = 'ana.prueba@example.com');
    }

    // ---------- Ayudas ----------

    private static Id campana() {
        return [SELECT Id FROM Campaign LIMIT 1].Id;
    }

    private static Map<String, Object> base() {
        return new Map<String, Object>{
            'paquete' => 'P3000',
            'visibilidad' => 'Publica',
            'nombre' => 'Luz',
            'apellidos' => 'Prueba',
            'correo' => 'luz.prueba@example.com',
            'consentimientoAvisos' => 'Si',
            'consentimientoPublicacion' => true,
            'aceptaAviso' => true,
            'versionAviso' => 'v1'
        };
    }

    // Igual que el sitio: los datos viajan como texto JSON.
    private static MesaRegalosController.RegistroDonativoResultado enviar(Map<String, Object> d) {
        return MesaRegalosController.guardarDonativo(campana(), JSON.serialize(d));
    }

    private static String errorAlEnviar(Map<String, Object> d) {
        try {
            enviar(d);
        } catch (AuraHandledException e) {
            return e.getMessage();
        }
        return null;
    }

    // ---------- Registro + donación ----------

    @IsTest
    static void personaNuevaCreaContactoMiembroYDonativo() {
        MesaRegalosController.RegistroDonativoResultado r = enviar(base());
        Assert.isTrue(r.exito);
        Contact c = [
            SELECT FirstName, Consentimiento_Avisos__c, Fecha_Consentimiento__c
            FROM Contact WHERE Email = 'luz.prueba@example.com'
        ];
        Assert.areEqual('Luz', c.FirstName);
        Assert.areEqual('Si', c.Consentimiento_Avisos__c);
        Assert.isNotNull(c.Fecha_Consentimiento__c);
        Opportunity o = [
            SELECT Amount, StageName, Nombre_Visible__c, Donacion_Empresa__c
            FROM Opportunity WHERE Id = :r.donativoId
        ];
        Assert.isTrue(o.Amount == 3000);
        Assert.areEqual('Prospecting', o.StageName);
        Assert.areEqual('Luz Prueba', o.Nombre_Visible__c);
        Assert.areEqual(false, o.Donacion_Empresa__c);
        Assert.areEqual('Redirigido a donar', [SELECT Status FROM CampaignMember WHERE ContactId = :c.Id].Status);
        Assert.areEqual(0, [SELECT COUNT() FROM Account]);
    }

    @IsTest
    static void correoExistenteSeReutilizaSinCambiarSusDatos() {
        Map<String, Object> d = base();
        d.put('correo', 'ANA.PRUEBA@example.com');
        d.put('nombre', 'Otra');
        d.put('apellidos', 'Persona');
        enviar(d);
        Assert.areEqual(1, [SELECT COUNT() FROM Contact]);
        Contact c = [SELECT FirstName, LastName, Consentimiento_Avisos__c FROM Contact];
        Assert.areEqual('Ana', c.FirstName);
        Assert.areEqual('Prueba', c.LastName);
        Assert.areEqual('Si', c.Consentimiento_Avisos__c); // estaba vacío
        // El nombre del muro es el que se escribió ahora, no el del Contacto.
        Assert.areEqual('Otra Persona', [SELECT Nombre_Visible__c FROM Opportunity].Nombre_Visible__c);
        Assert.areEqual(1, [SELECT COUNT() FROM CampaignMember]);
    }

    @IsTest
    static void unNoPrevioNoSeCambiaConUnRegistroNuevo() {
        update new Contact(Id = [SELECT Id FROM Contact].Id, Consentimiento_Avisos__c = 'No');
        Map<String, Object> d = base();
        d.put('correo', 'ana.prueba@example.com');
        enviar(d);
        Assert.areEqual('No', [SELECT Consentimiento_Avisos__c FROM Contact].Consentimiento_Avisos__c);
    }

    @IsTest
    static void donarEnNombreDeEmpresaGuardaElNombreEnNombreYApellido() {
        Map<String, Object> d = base();
        d.put('esEmpresa', true);
        d.put('nombreEmpresa', 'Acme SA');
        d.put('nombre', 'No');
        d.put('apellidos', 'Importa');
        d.put('correo', 'contacto@acme.example.com');
        MesaRegalosController.RegistroDonativoResultado r = enviar(d);
        Contact c = [SELECT FirstName, LastName FROM Contact WHERE Email = 'contacto@acme.example.com'];
        Assert.areEqual('Acme SA', c.FirstName);
        Assert.areEqual('Acme SA', c.LastName);
        Opportunity o = [SELECT Donacion_Empresa__c, Nombre_Visible__c FROM Opportunity WHERE Id = :r.donativoId];
        Assert.isTrue(o.Donacion_Empresa__c);
        Assert.areEqual('Acme SA', o.Nombre_Visible__c);
        Assert.areEqual(0, [SELECT COUNT() FROM Account]);
    }

    @IsTest
    static void anonimoFuerzaLosValoresAunqueElNavegadorEnvieOtros() {
        Map<String, Object> d = base();
        d.put('visibilidad', 'Anonima');
        d.put('esEmpresa', true);
        d.put('nombreEmpresa', 'Acme SA');
        d.put('linkedinUrl', 'https://www.linkedin.com/in/luz');
        d.put('correo', 'anon@example.com');
        MesaRegalosController.RegistroDonativoResultado r = enviar(d);
        Contact c = [SELECT FirstName, LastName FROM Contact WHERE Email = 'anon@example.com'];
        Assert.areEqual('Anónimo', c.FirstName);
        Assert.areEqual('Anónimo', c.LastName);
        Opportunity o = [
            SELECT Donacion_Empresa__c, Nombre_Visible__c, LinkedIn_URL__c
            FROM Opportunity WHERE Id = :r.donativoId
        ];
        Assert.areEqual(false, o.Donacion_Empresa__c);
        Assert.areEqual('Anónimo', o.Nombre_Visible__c);
        Assert.isNull(o.LinkedIn_URL__c);
    }

    // ---------- Monto ----------

    @IsTest
    static void paqueteFijaElMontoYElAbiertoTieneMinimo() {
        Map<String, Object> d = base();
        d.put('paquete', 'P1000');
        d.put('monto', 1); // el navegador no puede cambiar el precio de un paquete
        Id oppId = enviar(d).donativoId;
        Assert.isTrue([SELECT Amount FROM Opportunity WHERE Id = :oppId].Amount == 1000);

        Map<String, Object> bajo = base();
        bajo.put('paquete', 'Abierto');
        bajo.put('monto', 50);
        bajo.put('correo', 'bajo@example.com');
        Assert.areEqual('El monto mínimo es de $100 MXN.', errorAlEnviar(bajo));

        Map<String, Object> valido = base();
        valido.put('paquete', 'Abierto');
        valido.put('monto', 1500);
        valido.put('correo', 'valido@example.com');
        Id oppAbierto = enviar(valido).donativoId;
        Assert.isTrue([SELECT Amount FROM Opportunity WHERE Id = :oppAbierto].Amount == 1500);
    }

    // ---------- LinkedIn opcional ----------

    @IsTest
    static void linkedInEsOpcionalPeroSiVieneSeValida() {
        Assert.isTrue(enviar(base()).exito); // sin LinkedIn

        Map<String, Object> mal = base();
        mal.put('linkedinUrl', 'https://ejemplo.com/yo');
        mal.put('correo', 'mal@example.com');
        Assert.isNotNull(errorAlEnviar(mal));

        Map<String, Object> bien = base();
        bien.put('linkedinUrl', 'https://www.linkedin.com/in/luz');
        bien.put('correo', 'bien@example.com');
        Id oppId = enviar(bien).donativoId;
        Assert.areEqual(
            'https://www.linkedin.com/in/luz',
            [SELECT LinkedIn_URL__c FROM Opportunity WHERE Id = :oppId].LinkedIn_URL__c
        );
    }

    // ---------- Protecciones ----------

    @IsTest
    static void campoTrampaNoGuardaNada() {
        Map<String, Object> d = base();
        d.put('sitioWeb', 'http://spam.example.com');
        Assert.isTrue(enviar(d).exito);
        Assert.areEqual(0, [SELECT COUNT() FROM Opportunity]);
        Assert.areEqual(1, [SELECT COUNT() FROM Contact]); // solo Ana, la del setup
    }

    @IsTest
    static void datosIncompletosSeRechazan() {
        Map<String, Object> sinAviso = base();
        sinAviso.put('aceptaAviso', false);
        Assert.isNotNull(errorAlEnviar(sinAviso));

        Map<String, Object> correoMalo = base();
        correoMalo.put('correo', 'no-es-correo');
        Assert.isNotNull(errorAlEnviar(correoMalo));

        Map<String, Object> sinConsentimiento = base();
        sinConsentimiento.put('consentimientoAvisos', '');
        Assert.isNotNull(errorAlEnviar(sinConsentimiento));

        Map<String, Object> privada = base();
        privada.put('visibilidad', 'Privada');
        Assert.isNotNull(errorAlEnviar(privada));

        Map<String, Object> sinPublicacion = base();
        sinPublicacion.put('consentimientoPublicacion', false);
        Assert.isNotNull(errorAlEnviar(sinPublicacion));

        Map<String, Object> sinNombre = base();
        sinNombre.put('nombre', '');
        Assert.isNotNull(errorAlEnviar(sinNombre));

        Assert.areEqual(0, [SELECT COUNT() FROM Opportunity]);
    }

    @IsTest
    static void topeDeRegistrosPorHoraFrenaElAbuso() {
        MesaRegalosController.maxRegistrosPorHora = 1;
        Assert.isTrue(enviar(base()).exito);
        Map<String, Object> otro = base();
        otro.put('correo', 'otro@example.com');
        Assert.isNotNull(errorAlEnviar(otro));
    }

    // ---------- Pago confirmado y muro ----------

    @IsTest
    static void confirmarPagoCreaElReconocimientoPublicoYAnonimo() {
        Map<String, Object> pub = base();
        pub.put('esEmpresa', true);
        pub.put('nombreEmpresa', 'Acme SA');
        pub.put('linkedinUrl', 'https://www.linkedin.com/company/acme');
        pub.put('correo', 'acme@example.com');
        Id oppPub = enviar(pub).donativoId;

        Map<String, Object> anon = base();
        anon.put('visibilidad', 'Anonima');
        anon.put('correo', 'anon@example.com');
        Id oppAnon = enviar(anon).donativoId;

        MesaRegalosService.confirmarPago(new List<Id>{ oppPub, oppAnon });
        MesaRegalosService.confirmarPago(new List<Id>{ oppPub, oppAnon }); // idempotente
        Assert.areEqual(2, [SELECT COUNT() FROM Reconocimiento_Publico__c]);

        Reconocimiento_Publico__c p = [
            SELECT Name, Es_Empresa__c, LinkedIn_URL__c, Monto__c, Mostrar_Monto__c
            FROM Reconocimiento_Publico__c WHERE Donativo__c = :oppPub
        ];
        Assert.areEqual('Acme SA', p.Name);
        Assert.isTrue(p.Es_Empresa__c);
        Assert.isNotNull(p.LinkedIn_URL__c);
        Assert.isTrue(p.Monto__c == 3000);
        Assert.isTrue(p.Mostrar_Monto__c);

        Reconocimiento_Publico__c a = [
            SELECT Name, Es_Empresa__c, LinkedIn_URL__c
            FROM Reconocimiento_Publico__c WHERE Donativo__c = :oppAnon
        ];
        Assert.areEqual('Anónimo', a.Name);
        Assert.areEqual(false, a.Es_Empresa__c);
        Assert.isNull(a.LinkedIn_URL__c);

        Assert.areEqual('Donó', [SELECT Status FROM CampaignMember WHERE Contact.Email = 'acme@example.com'].Status);

        List<MesaRegalosController.MuroItem> muro = MesaRegalosController.obtenerMuro(campana());
        Assert.areEqual(2, muro.size());
        for (MesaRegalosController.MuroItem m : muro) {
            Assert.isTrue(m.monto == 3000); // el monto se muestra siempre, también en Anónimo
            Assert.areEqual(m.nombre == 'Acme SA', m.esEmpresa);
        }
    }

    // ---------- Baja ----------

    @IsTest
    static void darseDeBajaMarcaElOptOutYNoRevelaSiElCorreoExiste() {
        MesaRegalosController.darseDeBaja('ana.prueba@example.com', null);
        Contact c = [SELECT HasOptedOutOfEmail, Consentimiento_Avisos__c FROM Contact];
        Assert.isTrue(c.HasOptedOutOfEmail);
        Assert.areEqual('No', c.Consentimiento_Avisos__c);

        MesaRegalosController.darseDeBaja('nadie@example.com', null); // no existe: sin error ni registros nuevos
        Assert.areEqual(1, [SELECT COUNT() FROM Contact]);

        MesaRegalosController.darseDeBaja('otro@example.com', 'bot'); // campo trampa: no hace nada

        Boolean lanzo = false;
        try {
            MesaRegalosController.darseDeBaja('no-es-correo', null);
        } catch (AuraHandledException e) {
            lanzo = true;
        }
        Assert.isTrue(lanzo);
    }
}