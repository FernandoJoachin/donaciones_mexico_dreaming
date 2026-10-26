@IsTest
private class MesaRegalosTest {

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

        Contact ct = new Contact(FirstName = 'Ana', LastName = 'Prueba', Email = 'ana.prueba@example.com');
        insert ct;
        insert new CampaignMember(CampaignId = c.Id, ContactId = ct.Id, Status = 'Identificado');
    }

    private static String token() {
        return [SELECT Token_Acceso__c FROM CampaignMember LIMIT 1].Token_Acceso__c;
    }

    private static MesaRegalosController.DonativoInput donativoPublico() {
        MesaRegalosController.DonativoInput d = new MesaRegalosController.DonativoInput();
        d.monto = 1500;
        d.visibilidad = 'Publica';
        d.linkedinUrl = 'https://www.linkedin.com/in/ana-prueba';
        d.consentimientoPublicacion = true;
        d.mostrarMonto = true;
        d.aceptaAviso = true;
        d.versionAviso = 'v1';
        return d;
    }

    @IsTest
    static void tokenSeGeneraAlCrearMiembro() {
        Assert.areEqual(64, token().length());
    }

    @IsTest
    static void invitacionDevuelveDatosDelContacto() {
        MesaRegalosController.InvitacionDTO inv = MesaRegalosController.obtenerInvitacion(token());
        Assert.areEqual('Ana Prueba', inv.nombre);
        Assert.areEqual('México Dreaming TEST', inv.campana);
    }

    @IsTest
    static void tokenInvalidoLanzaError() {
        Boolean lanzo = false;
        try {
            MesaRegalosController.obtenerInvitacion('no-es-un-token');
        } catch (AuraHandledException e) {
            lanzo = true;
        }
        Assert.isTrue(lanzo, 'Un token inválido debe rechazarse');
    }

    @IsTest
    static void reencuentroActualizaContactoYEmbudo() {
        MesaRegalosController.ReencuentroInput i = new MesaRegalosController.ReencuentroInput();
        i.generacion = '2021';
        i.cuentaTrailhead = 'https://trailblazer.me/id/ana';
        i.consentimientoContacto = true;
        i.versionAviso = 'v1';
        MesaRegalosController.actualizarDatos(token(), i);

        Contact c = [SELECT Generacion__c, Consentimiento_Contacto__c, Fecha_Consentimiento__c, HasOptedOutOfEmail FROM Contact LIMIT 1];
        Assert.areEqual('2021', c.Generacion__c);
        Assert.isTrue(c.Consentimiento_Contacto__c);
        Assert.isNotNull(c.Fecha_Consentimiento__c);
        Assert.areEqual('Respondió', [SELECT Status FROM CampaignMember LIMIT 1].Status);
    }

    @IsTest
    static void darseDeBajaQuitaConsentimiento() {
        MesaRegalosController.ReencuentroInput i = new MesaRegalosController.ReencuentroInput();
        i.darseDeBaja = true;
        MesaRegalosController.actualizarDatos(token(), i);
        Contact c = [SELECT Consentimiento_Contacto__c, HasOptedOutOfEmail FROM Contact LIMIT 1];
        Assert.isFalse(c.Consentimiento_Contacto__c);
        Assert.isTrue(c.HasOptedOutOfEmail);
    }

    @IsTest
    static void donativoPublicoSinLinkedInSeRechaza() {
        MesaRegalosController.DonativoInput d = donativoPublico();
        d.linkedinUrl = 'https://ejemplo.com/perfil';
        Boolean lanzo = false;
        try {
            MesaRegalosController.registrarPromesa(token(), d);
        } catch (AuraHandledException e) {
            lanzo = true;
        }
        Assert.isTrue(lanzo, 'Un donativo público necesita un LinkedIn válido');
        Assert.areEqual(0, [SELECT COUNT() FROM Opportunity]);
    }

    @IsTest
    static void donativoPrivadoNoGuardaLinkedInNiCreaReconocimiento() {
        MesaRegalosController.DonativoInput d = donativoPublico();
        d.visibilidad = 'Privada';
        Id oppId = MesaRegalosController.registrarPromesa(token(), d);

        Opportunity o = [SELECT LinkedIn_URL__c, Consentimiento_Publicacion__c, Mostrar_Monto__c FROM Opportunity WHERE Id = :oppId];
        Assert.isNull(o.LinkedIn_URL__c);
        Assert.isFalse(o.Consentimiento_Publicacion__c);
        Assert.isFalse(o.Mostrar_Monto__c);

        MesaRegalosService.confirmarPago(new List<Id>{ oppId });
        Assert.areEqual(0, [SELECT COUNT() FROM Reconocimiento_Publico__c]);
        Assert.areEqual('Donó', [SELECT Status FROM CampaignMember LIMIT 1].Status);
    }

    @IsTest
    static void flujoPublicoCompletoEsIdempotente() {
        Id campanaId = [SELECT Id FROM Campaign LIMIT 1].Id;
        Id oppId = MesaRegalosController.registrarPromesa(token(), donativoPublico());
        Assert.areEqual('Redirigido a donar', [SELECT Status FROM CampaignMember LIMIT 1].Status);
        Assert.areEqual('Prospecting', [SELECT StageName FROM Opportunity WHERE Id = :oppId].StageName);

        // Antes del pago no hay avance ni muro
        Assert.isTrue(MesaRegalosController.obtenerAvance(campanaId).total == 0);
        Assert.areEqual(0, MesaRegalosController.obtenerMuro(campanaId).size());

        Test.startTest();
        MesaRegalosService.confirmarPago(new List<Id>{ oppId });
        MesaRegalosService.confirmarPago(new List<Id>{ oppId }); // un webhook puede llegar dos veces
        Test.stopTest();

        Assert.areEqual('Closed Won', [SELECT StageName FROM Opportunity WHERE Id = :oppId].StageName);
        Assert.areEqual('Donó', [SELECT Status FROM CampaignMember LIMIT 1].Status);
        Assert.areEqual(1, [SELECT COUNT() FROM Reconocimiento_Publico__c]);

        List<MesaRegalosController.MuroItem> muro = MesaRegalosController.obtenerMuro(campanaId);
        Assert.areEqual(1, muro.size());
        Assert.isTrue(muro[0].monto == 1500);

        MesaRegalosController.AvanceDTO avance = MesaRegalosController.obtenerAvance(campanaId);
        Assert.isTrue(avance.total == 1500);
        Assert.isTrue(avance.porcentaje == 15);
        Assert.areEqual(1, avance.donativos);
    }

    @IsTest
    static void montoOcultoNoSeExponeEnElMuro() {
        MesaRegalosController.DonativoInput d = donativoPublico();
        d.mostrarMonto = false;
        Id oppId = MesaRegalosController.registrarPromesa(token(), d);
        MesaRegalosService.confirmarPago(new List<Id>{ oppId });
        Id campanaId = [SELECT Id FROM Campaign LIMIT 1].Id;
        Assert.isNull(MesaRegalosController.obtenerMuro(campanaId)[0].monto);
    }

    // ---------- v2: paquetes y monto abierto ----------

    @IsTest
    static void paqueteFijaElMontoEnElServidor() {
        MesaRegalosController.DonativoInput d = donativoPublico();
        d.paquete = 'P3000';
        d.monto = 1; // el navegador no puede cambiar el precio de un paquete
        Id oppId = MesaRegalosController.registrarPromesa(token(), d);
        Opportunity o = [SELECT Amount FROM Opportunity WHERE Id = :oppId];
        Assert.isTrue(o.Amount == 3000);
    }

    @IsTest
    static void montoAbiertoPorDebajoDelMinimoSeRechaza() {
        MesaRegalosController.DonativoInput d = donativoPublico();
        d.paquete = 'Abierto';
        d.monto = 99;
        Boolean lanzo = false;
        try {
            MesaRegalosController.registrarPromesa(token(), d);
        } catch (AuraHandledException e) {
            lanzo = true;
        }
        Assert.isTrue(lanzo, 'El monto abierto no puede ser menor a 100');
        Assert.areEqual(0, [SELECT COUNT() FROM Opportunity]);
    }

    @IsTest
    static void montoAbiertoValidoSeGuardaComoAbierto() {
        MesaRegalosController.DonativoInput d = donativoPublico();
        d.paquete = 'Abierto';
        d.monto = 2500;
        Id oppId = MesaRegalosController.registrarPromesa(token(), d);
        Opportunity o = [SELECT Amount FROM Opportunity WHERE Id = :oppId];
        Assert.isTrue(o.Amount == 2500);
    }

    // ---------- v2: registro, invitaciones y empresas ----------

    private static MesaRegalosController.RegistroInput registro(String correo) {
        MesaRegalosController.RegistroInput r = new MesaRegalosController.RegistroInput();
        r.nombre = 'Luis';
        r.apellidos = 'Nuevo';
        r.correo = correo;
        r.esEmpresa = false;
        r.aceptaAviso = true;
        r.versionAviso = 'v1';
        return r;
    }

    @IsTest
    static void registroPropioCreaContactoMiembroYDevuelveToken() {
        Id campanaId = [SELECT Id FROM Campaign LIMIT 1].Id;
        MesaRegalosController.RegistroResultado res =
            MesaRegalosController.registrarDonador(campanaId, null, registro('luis.nuevo@example.com'));
        Assert.isTrue(res.exito);
        Assert.areEqual(64, res.token.length());

        Contact c = [SELECT Origen_Registro__c, Invitado_Por__c FROM Contact WHERE Email = 'luis.nuevo@example.com'];
        Assert.areEqual('Sitio', c.Origen_Registro__c);
        Assert.isNull(c.Invitado_Por__c);
        Assert.areEqual('Interesado', [SELECT Status FROM CampaignMember WHERE Token_Acceso__c = :res.token].Status);
    }

    @IsTest
    static void invitacionGuardaQuienInvitoYNoEntregaElToken() {
        Id campanaId = [SELECT Id FROM Campaign LIMIT 1].Id;
        Id invitadorId = [SELECT ContactId FROM CampaignMember LIMIT 1].ContactId;
        MesaRegalosController.RegistroResultado res =
            MesaRegalosController.registrarDonador(campanaId, token(), registro('invitado@example.com'));
        Assert.isTrue(res.exito);
        Assert.isNull(res.token, 'El token del invitado no se entrega a quien invita');

        Contact c = [SELECT Origen_Registro__c, Invitado_Por__c FROM Contact WHERE Email = 'invitado@example.com'];
        Assert.areEqual('Invitacion', c.Origen_Registro__c);
        Assert.areEqual(invitadorId, c.Invitado_Por__c);
        Assert.areEqual('Identificado', [SELECT Status FROM CampaignMember WHERE ContactId = :c.Id].Status);
    }

    @IsTest
    static void correoYaRegistradoNoCreaNiModificaNada() {
        Id campanaId = [SELECT Id FROM Campaign LIMIT 1].Id;
        Integer antes = [SELECT COUNT() FROM Contact];
        MesaRegalosController.RegistroResultado res =
            MesaRegalosController.registrarDonador(campanaId, null, registro('ana.prueba@example.com'));
        Assert.isFalse(res.exito);
        Assert.isNull(res.token);
        Assert.areEqual(antes, [SELECT COUNT() FROM Contact]);
    }

    @IsTest
    static void campoTrampaNoGuardaNada() {
        Id campanaId = [SELECT Id FROM Campaign LIMIT 1].Id;
        MesaRegalosController.RegistroInput r = registro('bot@example.com');
        r.sitioWeb = 'http://spam.example.com';
        MesaRegalosController.registrarDonador(campanaId, null, r);
        Assert.areEqual(0, [SELECT COUNT() FROM Contact WHERE Email = 'bot@example.com']);
    }

    @IsTest
    static void topeDeRegistrosPorHoraFrenaElAbuso() {
        Id campanaId = [SELECT Id FROM Campaign LIMIT 1].Id;
        MesaRegalosController.maxRegistrosPorHora = 0;
        Boolean lanzo = false;
        try {
            MesaRegalosController.registrarDonador(campanaId, null, registro('otro@example.com'));
        } catch (AuraHandledException e) {
            lanzo = true;
        }
        Assert.isTrue(lanzo);
    }

    @IsTest
    static void registroSinAvisoOSinCorreoValidoSeRechaza() {
        Id campanaId = [SELECT Id FROM Campaign LIMIT 1].Id;
        MesaRegalosController.RegistroInput sinAviso = registro('x@example.com');
        sinAviso.aceptaAviso = false;
        MesaRegalosController.RegistroInput malCorreo = registro('esto-no-es-un-correo');
        Integer rechazos = 0;
        for (MesaRegalosController.RegistroInput r : new List<MesaRegalosController.RegistroInput>{ sinAviso, malCorreo }) {
            try {
                MesaRegalosController.registrarDonador(campanaId, null, r);
            } catch (AuraHandledException e) {
                rechazos++;
            }
        }
        Assert.areEqual(2, rechazos);
    }

    @IsTest
    static void donativoDeEmpresaSeReconoceConElNombreDeLaEmpresa() {
        Id campanaId = [SELECT Id FROM Campaign LIMIT 1].Id;
        MesaRegalosController.RegistroInput r = registro('contacto@acme.example.com');
        r.esEmpresa = true;
        r.empresa = 'ACME Prueba SA';
        MesaRegalosController.RegistroResultado res = MesaRegalosController.registrarDonador(campanaId, null, r);

        MesaRegalosController.InvitacionDTO inv = MesaRegalosController.obtenerInvitacion(res.token);
        Assert.isTrue(inv.esEmpresa);
        Assert.areEqual('ACME Prueba SA', inv.empresa);

        MesaRegalosController.DonativoInput d = donativoPublico();
        d.paquete = 'P5000';
        d.linkedinUrl = 'https://www.linkedin.com/company/acme-prueba';
        Id oppId = MesaRegalosController.registrarPromesa(res.token, d);
        Assert.isNotNull([SELECT AccountId FROM Opportunity WHERE Id = :oppId].AccountId);

        MesaRegalosService.confirmarPago(new List<Id>{ oppId });
        Reconocimiento_Publico__c rec = [SELECT Name, Generacion__c FROM Reconocimiento_Publico__c];
        Assert.areEqual('ACME Prueba SA', rec.Name);
        Assert.isNull(rec.Generacion__c, 'La generación es un dato de la persona, no de la empresa');
    }

    @IsTest
    static void personaSinEmpresaSigueReconociendoseConSuNombre() {
        Id oppId = MesaRegalosController.registrarPromesa(token(), donativoPublico());
        Assert.isNull([SELECT AccountId FROM Opportunity WHERE Id = :oppId].AccountId);
        MesaRegalosService.confirmarPago(new List<Id>{ oppId });
        Assert.areEqual('Ana Prueba', [SELECT Name FROM Reconocimiento_Publico__c].Name);
    }

    @IsTest
    static void guardarPromesaAceptaJson() {
        String jsonPayload = '{"paquete":"P3000","monto":null,"visibilidad":"Privada","aceptaAviso":true,"versionAviso":"v1"}';
        Id oppId = MesaRegalosController.guardarPromesa(token(), jsonPayload);
        Opportunity o = [SELECT Amount FROM Opportunity WHERE Id = :oppId];
        Assert.isTrue(o.Amount == 3000);
    }

    @IsTest
    static void validacionDeCorreos() {
        Assert.isTrue(MesaRegalosController.esCorreoValido('a.b+c@dominio.com.mx'));
        Assert.isFalse(MesaRegalosController.esCorreoValido('sin-arroba.com'));
        Assert.isFalse(MesaRegalosController.esCorreoValido('a@b'));
    }

    @IsTest
    static void validacionDeUrlsDeLinkedIn() {
        Assert.isTrue(MesaRegalosController.esUrlLinkedIn('https://www.linkedin.com/in/alguien'));
        Assert.isTrue(MesaRegalosController.esUrlLinkedIn('https://mx.linkedin.com/in/alguien'));
        Assert.isTrue(MesaRegalosController.esUrlLinkedIn('https://www.linkedin.com/company/una-empresa'));
        Assert.isFalse(MesaRegalosController.esUrlLinkedIn('http://www.linkedin.com/in/alguien'));
        Assert.isFalse(MesaRegalosController.esUrlLinkedIn('https://linkedin.com.malo.com/in/x'));
        Assert.isFalse(MesaRegalosController.esUrlLinkedIn(null));
    }
}
