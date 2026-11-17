/** Pruebas del comprobante por correo (US-07, CA3 y CA4). En pruebas Salesforce no entrega correos. */
@IsTest
private class MesaComprobanteTest {

    @TestSetup
    static void datos() {
        insert new Campaign(Name = 'Becas <TEST>', IsActive = true, ExpectedRevenue = 10000);
    }

    private static Id donativo(String visibilidad, String paquete, String correo) {
        Map<String, Object> d = new Map<String, Object>{
            'paquete' => paquete,
            'visibilidad' => visibilidad,
            'nombre' => 'Luz',
            'apellidos' => 'Prueba',
            'correo' => correo,
            'consentimientoAvisos' => 'Si',
            'consentimientoPublicacion' => true,
            'aceptaAviso' => true,
            'versionAviso' => 'v1'
        };
        Id campana = [SELECT Id FROM Campaign LIMIT 1].Id;
        return MesaRegalosController.guardarDonativo(campana, JSON.serialize(d)).donativoId;
    }

    private static Opportunity donativoConEstado(Id id) {
        return [SELECT Comprobante_Estado__c FROM Opportunity WHERE Id = :id];
    }

    @IsTest
    static void confirmarPagoPublicaElAvisoYElTriggerEnviaUnSoloComprobante() {
        Id id = donativo('Publica', 'P1000', 'luz@example.com');

        Test.startTest();
        MesaRegalosService.confirmarPago(new List<Id>{ id });
        MesaRegalosService.confirmarPago(new List<Id>{ id });   // aviso repetido de Stripe
        Test.getEventBus().deliver();                           // corre ComprobantePagoTrigger
        Test.stopTest();

        Assert.areEqual(1, MesaComprobante.ultimosCorreos.size(), 'El segundo aviso no debe mandar otro correo');
        Assert.areEqual('luz@example.com', MesaComprobante.ultimosCorreos[0].getToAddresses()[0]);
        Assert.areEqual('Enviado', donativoConEstado(id).Comprobante_Estado__c);
    }

    @IsTest
    static void unComprobanteYaEnviadoNoSeVuelveAEnviar() {
        Id id = donativo('Publica', 'P1000', 'luz@example.com');
        MesaRegalosService.confirmarPago(new List<Id>{ id });

        Assert.areEqual(1, MesaComprobante.enviar(new List<Id>{ id }));
        Assert.areEqual(0, MesaComprobante.enviar(new List<Id>{ id }), 'Ya dice Enviado: no se repite');
        Assert.areEqual(0, MesaComprobante.ultimosCorreos.size());
    }

    @IsTest
    static void elCorreoTraeReferenciaMontoCampanaYLeyendaDeFactura() {
        Id id = donativo('Publica', 'P1000', 'luz@example.com');
        update new Opportunity(Id = id, Stripe_Pago_Id__c = 'pi_test_123');
        MesaRegalosService.confirmarPago(new List<Id>{ id });

        MesaComprobante.enviar(new List<Id>{ id });
        Messaging.SingleEmailMessage m = MesaComprobante.ultimosCorreos[0];
        String ref = MesaPagosStripe.referencia(id);

        Assert.isTrue(m.getSubject().contains(ref), 'El asunto lleva la referencia');
        String texto = m.getPlainTextBody();
        Assert.isTrue(texto.contains('Hola, Luz:'));
        Assert.isTrue(texto.contains('$1,000.00 MXN'));
        Assert.isTrue(texto.contains('Becas <TEST>'));
        Assert.isTrue(texto.contains('pi_test_123'));
        Assert.isTrue(texto.contains('Si necesitas factura, escribe a ' + System.Label.Mesa_Correo_Facturas), 'CA3: leyenda de factura');
        Assert.isTrue(texto.contains('(' + ref + ')'), 'CA3: la leyenda pide la referencia');
        Assert.isTrue(texto.contains('no es una factura'));
        // El HTML escapa lo que viene de los datos (aquí, el nombre de la campaña).
        Assert.isTrue(m.getHtmlBody().contains('Becas &lt;TEST&gt;'));
        Assert.isFalse(m.getHtmlBody().contains('Becas <TEST>'));
    }

    @IsTest
    static void elCorreoLlevaElBotonDelMuroDeLaCampanaSiElSitioEstaConfigurado() {
        insert new Stripe_Config__c(SetupOwnerId = UserInfo.getOrganizationId(), Url_Sitio__c = 'https://sitio.example.com/s/');
        Id id = donativo('Publica', 'P1000', 'luz@example.com');
        MesaRegalosService.confirmarPago(new List<Id>{ id });

        MesaComprobante.enviar(new List<Id>{ id });
        Messaging.SingleEmailMessage m = MesaComprobante.ultimosCorreos[0];
        String campanaId = [SELECT CampaignId FROM Opportunity WHERE Id = :id].CampaignId;
        Assert.isTrue(m.getHtmlBody().contains('https://sitio.example.com/s/muro?campana=' + campanaId));
        Assert.isTrue(m.getPlainTextBody().contains('muro?campana=' + campanaId));
    }

    @IsTest
    static void elAvisoDeFacturaEnlazaALaPaginaDeFacturas() {
        insert new Stripe_Config__c(SetupOwnerId = UserInfo.getOrganizationId(), Url_Sitio__c = 'https://sitio.example.com/s/');
        Id id = donativo('Publica', 'P1000', 'luz@example.com');
        MesaRegalosService.confirmarPago(new List<Id>{ id });

        MesaComprobante.enviar(new List<Id>{ id });
        Messaging.SingleEmailMessage m = MesaComprobante.ultimosCorreos[0];
        Assert.isTrue(m.getHtmlBody().contains('href="https://sitio.example.com/s/facturas"'));
        Assert.isTrue(m.getPlainTextBody().contains('Pasos para pedir tu factura: https://sitio.example.com/s/facturas'));
        Assert.isTrue(m.getHtmlBody().contains('https://sitio.example.com/s'), 'También enlaza al sitio con las demás campañas');
    }

    @IsTest
    static void sinSitioConfiguradoElCorreoVaSinBoton() {
        Id id = donativo('Publica', 'P1000', 'luz@example.com');
        MesaRegalosService.confirmarPago(new List<Id>{ id });

        MesaComprobante.enviar(new List<Id>{ id });
        Assert.isFalse(MesaComprobante.ultimosCorreos[0].getHtmlBody().contains('Ver el muro de agradecimiento'));
    }

    @IsTest
    static void elSaludoNoDiceAnonimoSiElContactoSeCreoEnUnDonativoAnonimo() {
        Id id = donativo('Publica', 'P1000', 'luz@example.com');
        update new Contact(Id = [SELECT Contacto_Donador__c FROM Opportunity WHERE Id = :id].Contacto_Donador__c, FirstName = 'Anónimo');
        MesaRegalosService.confirmarPago(new List<Id>{ id });

        MesaComprobante.enviar(new List<Id>{ id });
        String texto = MesaComprobante.ultimosCorreos[0].getPlainTextBody();
        Assert.isTrue(texto.contains('Hola, Luz:'), 'Usa el nombre público elegido para este donativo');
        Assert.isFalse(texto.contains('Hola, Anónimo'));
    }

    @IsTest
    static void donativoAnonimoDiceComoApareceEnElMuro() {
        Id id = donativo('Anonima', 'P3000', 'anon@example.com');
        MesaRegalosService.confirmarPago(new List<Id>{ id });

        MesaComprobante.enviar(new List<Id>{ id });
        String texto = MesaComprobante.ultimosCorreos[0].getPlainTextBody();
        Assert.isTrue(texto.contains('como «Anónimo»'));
        Assert.isTrue(texto.contains('$3,000.00 MXN'));
    }

    @IsTest
    static void donativoPendienteNoRecibeComprobante() {
        Id id = donativo('Publica', 'P1000', 'luz@example.com');
        Assert.areEqual(0, MesaComprobante.enviar(new List<Id>{ id }));
        Assert.areEqual(0, MesaComprobante.ultimosCorreos.size(), 'Solo los pagados reciben comprobante');
    }

    @IsTest
    static void montosConMilesYCentavos() {
        Assert.areEqual('$100.00', MesaComprobante.pesos(100));
        Assert.areEqual('$1,234.50', MesaComprobante.pesos(1234.5));
        Assert.areEqual('$1,000,000.00', MesaComprobante.pesos(1000000));
        Assert.areEqual('$0.00', MesaComprobante.pesos(null));
    }
}
