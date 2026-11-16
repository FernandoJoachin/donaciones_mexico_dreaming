@IsTest
private class MesaPagosStripeTest {

    private static final String SECRETO = 'whsec_prueba_123';
    private static final String SITIO = 'https://mesa.example.com/donaciones/s';

    @TestSetup
    static void datos() {
        Campaign c = new Campaign(Name = 'Campaña Stripe TEST', IsActive = true, ExpectedRevenue = 10000);
        insert c;
        List<CampaignMemberStatus> estados = new List<CampaignMemberStatus>();
        Integer orden = 10;
        for (String etiqueta : MesaRegalosService.ORDEN_ESTADOS) {
            estados.add(new CampaignMemberStatus(
                CampaignId = c.Id, Label = etiqueta, SortOrder = orden++,
                HasResponded = etiqueta != 'Identificado' && etiqueta != 'Contactado'
            ));
        }
        insert estados;
        insert new Stripe_Config__c(SetupOwnerId = UserInfo.getOrganizationId(), Webhook_Secret__c = SECRETO, Url_Sitio__c = SITIO + '/');
    }

    // ---------- Ayudas ----------

    private static Id campana() {
        return [SELECT Id FROM Campaign LIMIT 1].Id;
    }

    /** Registra un donativo como lo hace el sitio. paquete = P1000/P3000/P5000 o 'Abierto' con monto. */
    private static Id registrar(String paquete, Decimal monto, String correo) {
        Map<String, Object> d = new Map<String, Object>{
            'paquete' => paquete,
            'monto' => monto,
            'visibilidad' => 'Publica',
            'nombre' => 'Luz',
            'apellidos' => 'Prueba',
            'correo' => correo,
            'consentimientoAvisos' => 'Si',
            'consentimientoPublicacion' => true,
            'aceptaAviso' => true,
            'versionAviso' => 'v1'
        };
        return MesaRegalosController.guardarDonativo(campana(), JSON.serialize(d)).donativoId;
    }

    /** Simula la API de Stripe y guarda la última petición para revisarla. */
    private class StripeMock implements HttpCalloutMock {
        Integer estado;
        HttpRequest ultima;
        Integer llamadas = 0;
        StripeMock(Integer estado) {
            this.estado = estado;
        }
        public HttpResponse respond(HttpRequest req) {
            ultima = req;
            llamadas++;
            HttpResponse r = new HttpResponse();
            r.setStatusCode(estado);
            r.setBody(estado == 200
                ? '{"id":"cs_test_1","url":"https://checkout.stripe.com/c/pay/cs_test_1"}'
                : '{"error":{"type":"invalid_request_error","param":"payment_method_types","message":"Parametro no soportado"}}');
            return r;
        }
    }

    private static String error(Id donativoId, String exito, String regreso) {
        try {
            MesaRegalosController.iniciarPago(donativoId, exito, regreso);
        } catch (AuraHandledException e) {
            return e.getMessage();
        }
        return null;
    }

    private static Map<String, String> parametros(String cuerpo) {
        Map<String, String> m = new Map<String, String>();
        for (String par : cuerpo.split('&')) {
            List<String> kv = par.split('=', 2);
            m.put(EncodingUtil.urlDecode(kv[0], 'UTF-8'), kv.size() > 1 ? EncodingUtil.urlDecode(kv[1], 'UTF-8') : '');
        }
        return m;
    }

    private static Long ahora() {
        return Datetime.now().getTime() / 1000;
    }

    private static String firmar(String cuerpo, Long t, String secreto) {
        return 't=' + t + ',v1=' + EncodingUtil.convertToHex(
            Crypto.generateMac('hmacSHA256', Blob.valueOf(t + '.' + cuerpo), Blob.valueOf(secreto)));
    }

    /** Evento de Checkout como lo envía Stripe (solo los campos que se usan). */
    private static String evento(String tipo, String ref, String refMeta, Long centavos, String moneda, String estadoPago, String pago) {
        Map<String, Object> sesion = new Map<String, Object>{
            'id' => 'cs_test_1',
            'object' => 'checkout.session',
            'client_reference_id' => ref,
            'metadata' => new Map<String, Object>{ 'donativo_id' => refMeta },
            'amount_total' => centavos,
            'currency' => moneda,
            'payment_status' => estadoPago,
            'payment_intent' => pago
        };
        return JSON.serialize(new Map<String, Object>{
            'id' => 'evt_test_1',
            'type' => tipo,
            'data' => new Map<String, Object>{ 'object' => sesion }
        });
    }

    private static String pagoCompletado(Id donativoId, Long centavos, String pago) {
        return evento('checkout.session.completed', donativoId, donativoId, centavos, 'mxn', 'paid', pago);
    }

    /** Llama al webhook como lo haría Stripe y devuelve el código HTTP. */
    private static Integer enviarAviso(String cuerpo, String firma) {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/stripe/webhook';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(cuerpo);
        if (firma != null) {
            req.headers.put('Stripe-Signature', firma);
        }
        RestContext.request = req;
        RestContext.response = new RestResponse();
        MesaStripeWebhook.recibir();
        return RestContext.response.statusCode;
    }

    private static Opportunity donativo(Id id) {
        return [SELECT StageName, Amount, Stripe_Pago_Id__c FROM Opportunity WHERE Id = :id];
    }

    // ---------- Abrir la pasarela (CA1, CA2, CA3, CA4) ----------

    @IsTest
    static void montoLibreSeCobraExactoDesdeLoGuardadoConSuReferencia() {
        Id d = registrar('Abierto', 1500.5, 'libre@example.com');
        Assert.areEqual('Prospecting', donativo(d).StageName); // CA1: existe antes de abrir la pasarela
        StripeMock mock = new StripeMock(200);
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        String url = MesaRegalosController.iniciarPago(d, 'muro', 'registro');
        Test.stopTest();

        Assert.areEqual('https://checkout.stripe.com/c/pay/cs_test_1', url);
        Assert.areEqual('callout:Stripe/v1/checkout/sessions', mock.ultima.getEndpoint());
        Assert.areEqual('mesa-donativo-' + d, mock.ultima.getHeader('Idempotency-Key'));
        Map<String, String> p = parametros(mock.ultima.getBody());
        Assert.areEqual('150050', p.get('line_items[0][price_data][unit_amount]')); // CA4: centavos exactos
        Assert.areEqual('mxn', p.get('line_items[0][price_data][currency]'));
        Assert.areEqual('1', p.get('line_items[0][quantity]'));
        Assert.areEqual('false', p.get('adaptive_pricing[enabled]')); // siempre en pesos
        Assert.areEqual(String.valueOf(d), p.get('client_reference_id'));          // CA2
        Assert.areEqual(String.valueOf(d), p.get('metadata[donativo_id]'));
        Assert.areEqual(String.valueOf(d), p.get('payment_intent_data[metadata][donativo_id]'));
        Assert.areEqual('Donativo REF ' + MesaPagosStripe.referencia(d), p.get('payment_intent_data[description]'));
        Assert.areEqual('libre@example.com', p.get('customer_email'));
        Assert.areEqual(SITIO + '/muro?campana=' + campana(), p.get('success_url'));
        Assert.areEqual(SITIO + '/registro?campana=' + campana() + '&pago=cancelado&donativo=' + d, p.get('cancel_url'));
        Assert.isTrue(donativo(d).Amount == 1500.5);
    }

    @IsTest
    static void paqueteSeCobraPorElMontoDelPaquete() {
        Id d = registrar('P3000', 999, 'paquete@example.com'); // el monto del navegador se ignora
        StripeMock mock = new StripeMock(200);
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        MesaRegalosController.iniciarPago(d, 'muro', 'registro');
        Test.stopTest();
        Assert.areEqual('300000', parametros(mock.ultima.getBody()).get('line_items[0][price_data][unit_amount]')); // CA3
        Assert.isTrue(donativo(d).Amount == 3000);
    }

    @IsTest
    static void noSeAbrePagoDeDonativoPagadoNiDeOtroRegistro() {
        Id d = registrar('P1000', null, 'pagado@example.com');
        MesaRegalosService.confirmarPago(new List<Id>{ d });
        StripeMock mock = new StripeMock(200);
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        Assert.areEqual('Este donativo ya no está pendiente de pago.', error(d, 'muro', 'registro'));
        Assert.isNotNull(error(campana(), 'muro', 'registro')); // un Id que no es donativo
        Assert.isNotNull(error(null, 'muro', 'registro'));
        Test.stopTest();
        Assert.areEqual(0, mock.llamadas);
    }

    @IsTest
    static void paginasDeRegresoSoloDelSitio() {
        Id d = registrar('P1000', null, 'paginas@example.com');
        StripeMock mock = new StripeMock(200);
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        Assert.isNotNull(error(d, 'https://otro.example.com', 'registro'));
        Assert.isNotNull(error(d, 'muro', '../registro'));
        Assert.isNotNull(error(d, '', 'registro'));
        Test.stopTest();
        Assert.areEqual(0, mock.llamadas);
    }

    @IsTest
    static void sinConfiguracionNoSeLlamaAStripe() {
        Id d = registrar('P1000', null, 'sinconfig@example.com');
        delete [SELECT Id FROM Stripe_Config__c];
        StripeMock mock = new StripeMock(200);
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        Assert.areEqual('El pago en línea no está disponible por ahora. Intenta más tarde.', error(d, 'muro', 'registro'));
        Test.stopTest();
        Assert.areEqual(0, mock.llamadas);
    }

    @IsTest
    static void errorDeStripeSeMuestraComoMensajeComprensible() {
        Id d = registrar('P1000', null, 'error@example.com');
        Test.setMock(HttpCalloutMock.class, new StripeMock(500));
        Test.startTest();
        Assert.areEqual('No pudimos abrir la pasarela de pago. Intenta de nuevo en unos minutos.', error(d, 'muro', 'registro'));
        Test.stopTest();
        Assert.areEqual('Prospecting', donativo(d).StageName);
    }

    @IsTest
    static void elErrorDeStripeSeResumeParaElRegistro() {
        String d = MesaPagosStripe.detalleError('{"error":{"type":"invalid_request_error","param":"locale","message":"Valor inválido"}}');
        Assert.isTrue(d.contains('tipo=invalid_request_error'));
        Assert.isTrue(d.contains('parámetro=locale'));
        Assert.isTrue(d.contains('Valor inválido'));
        Assert.areEqual('(respuesta sin formato de error de Stripe)', MesaPagosStripe.detalleError('<html>no es json</html>'));
        Assert.areEqual('', MesaPagosStripe.detalleError('{"id":"cs_1"}'));
    }

    @IsTest
    static void montosEnCentavos() {
        Assert.areEqual(10000L, MesaPagosStripe.enCentavos(100));
        Assert.areEqual(150050L, MesaPagosStripe.enCentavos(1500.5));
        Assert.areEqual(100000000L, MesaPagosStripe.enCentavos(1000000));
        Assert.areEqual(12346L, MesaPagosStripe.enCentavos(123.455));
    }

    // ---------- Firma del aviso ----------

    @IsTest
    static void firmaSoloValeConElSecretoYDentroDeTiempo() {
        String cuerpo = '{"type":"x"}';
        Long t = ahora();
        Assert.isTrue(MesaPagosStripe.firmaValida(cuerpo, firmar(cuerpo, t, SECRETO), SECRETO, t));
        Assert.isFalse(MesaPagosStripe.firmaValida(cuerpo, firmar(cuerpo, t, 'whsec_otro'), SECRETO, t));
        Assert.isFalse(MesaPagosStripe.firmaValida(cuerpo + ' ', firmar(cuerpo, t, SECRETO), SECRETO, t)); // cuerpo alterado
        Assert.isFalse(MesaPagosStripe.firmaValida(cuerpo, firmar(cuerpo, t - 301, SECRETO), SECRETO, t)); // repetición vieja
        Assert.isFalse(MesaPagosStripe.firmaValida(cuerpo, 'v1=abc', SECRETO, t));
        Assert.isFalse(MesaPagosStripe.firmaValida(cuerpo, null, SECRETO, t));
        // Al rotar el secreto Stripe manda varias firmas v1: basta con que una sea válida.
        String varias = firmar(cuerpo, t, SECRETO) + ',v1=' + '0'.repeat(64);
        Assert.isTrue(MesaPagosStripe.firmaValida(cuerpo, varias, SECRETO, t));
    }

    // ---------- Webhook (confirmación, duplicados, seguridad) ----------

    @IsTest
    static void avisoValidoConfirmaElPagoYUnoRepetidoNoDuplica() {
        Id d = registrar('P3000', null, 'webhook@example.com');
        String cuerpo = pagoCompletado(d, 300000, 'pi_test_1');
        Test.startTest();
        Assert.areEqual(200, enviarAviso(cuerpo, firmar(cuerpo, ahora(), SECRETO)));
        Assert.areEqual(200, enviarAviso(cuerpo, firmar(cuerpo, ahora(), SECRETO))); // Stripe lo reenvía
        Test.stopTest();

        Opportunity o = donativo(d);
        Assert.areEqual('Closed Won', o.StageName);
        Assert.areEqual('pi_test_1', o.Stripe_Pago_Id__c);
        Assert.areEqual(1, [SELECT COUNT() FROM Reconocimiento_Publico__c WHERE Donativo__c = :d]);
        Assert.isTrue(MesaRegalosController.obtenerAvance(campana()).total == 3000);
        Assert.areEqual('pagado', MesaRegalosController.estadoPago(d));
    }

    @IsTest
    static void firmaInvalidaOFaltanteResponde400YNoCambiaNada() {
        Id d = registrar('P1000', null, 'falso@example.com');
        String cuerpo = pagoCompletado(d, 100000, 'pi_falso');
        Test.startTest();
        Assert.areEqual(400, enviarAviso(cuerpo, firmar(cuerpo, ahora(), 'whsec_adivinado')));
        Assert.areEqual(400, enviarAviso(cuerpo, null)); // un "éxito" armado en el navegador no basta
        Test.stopTest();
        Assert.areEqual('Prospecting', donativo(d).StageName);
    }

    @IsTest
    static void sinSecretoConfiguradoResponde500ParaQueStripeReintente() {
        Id d = registrar('P1000', null, 'sinsecreto@example.com');
        delete [SELECT Id FROM Stripe_Config__c];
        String cuerpo = pagoCompletado(d, 100000, 'pi_1');
        Assert.areEqual(500, enviarAviso(cuerpo, firmar(cuerpo, ahora(), SECRETO)));
        Assert.areEqual('Prospecting', donativo(d).StageName);
    }

    @IsTest
    static void montoOMonedaDistintosNoConfirman() {
        Id d = registrar('P1000', null, 'monto@example.com');
        Assert.areEqual(MesaPagosStripe.Resultado.RECHAZADO, MesaPagosStripe.procesarEvento(pagoCompletado(d, 10000, 'pi_a')));
        Assert.areEqual(MesaPagosStripe.Resultado.RECHAZADO, MesaPagosStripe.procesarEvento(
            evento('checkout.session.completed', d, d, 100000, 'usd', 'paid', 'pi_b')));
        Assert.areEqual('Prospecting', donativo(d).StageName);
        Assert.isNull(donativo(d).Stripe_Pago_Id__c);
    }

    @IsTest
    static void unPagoNoSePuedeAsociarAOtroDonativo() {
        Id a = registrar('P1000', null, 'a@example.com');
        Id b = registrar('P1000', null, 'b@example.com');
        // Referencia y metadatos que no coinciden.
        Assert.areEqual(MesaPagosStripe.Resultado.RECHAZADO, MesaPagosStripe.procesarEvento(
            evento('checkout.session.completed', a, b, 100000, 'mxn', 'paid', 'pi_x')));
        // Referencia que no es un donativo.
        Assert.areEqual(MesaPagosStripe.Resultado.RECHAZADO, MesaPagosStripe.procesarEvento(
            evento('checkout.session.completed', campana(), campana(), 100000, 'mxn', 'paid', 'pi_y')));
        // El mismo pago no confirma un segundo donativo.
        Assert.areEqual(MesaPagosStripe.Resultado.CONFIRMADO, MesaPagosStripe.procesarEvento(pagoCompletado(a, 100000, 'pi_z')));
        Assert.areEqual(MesaPagosStripe.Resultado.RECHAZADO, MesaPagosStripe.procesarEvento(pagoCompletado(b, 100000, 'pi_z')));
        Assert.areEqual('Closed Won', donativo(a).StageName);
        Assert.areEqual('Prospecting', donativo(b).StageName);
    }

    @IsTest
    static void cancelarOFallarDejaElDonativoPendienteYFueraDelAvance() {
        Id d = registrar('P5000', null, 'cancela@example.com');
        Assert.areEqual(MesaPagosStripe.Resultado.IGNORADO, MesaPagosStripe.procesarEvento(
            evento('checkout.session.expired', d, d, 500000, 'mxn', 'unpaid', null)));
        Assert.areEqual(MesaPagosStripe.Resultado.IGNORADO, MesaPagosStripe.procesarEvento(
            evento('payment_intent.payment_failed', d, d, 500000, 'mxn', 'unpaid', 'pi_f')));
        Assert.areEqual(MesaPagosStripe.Resultado.IGNORADO, MesaPagosStripe.procesarEvento(
            evento('checkout.session.completed', d, d, 500000, 'mxn', 'unpaid', 'pi_f')));
        Assert.areEqual('Prospecting', donativo(d).StageName);
        Assert.areEqual('pendiente', MesaRegalosController.estadoPago(d));
        Assert.isTrue(MesaRegalosController.obtenerAvance(campana()).total == 0);
        Assert.areEqual(0, [SELECT COUNT() FROM Reconocimiento_Publico__c]);
    }

    @IsTest
    static void avisoAntiguoNoRevierteUnPagoConfirmado() {
        Id d = registrar('P1000', null, 'orden@example.com');
        MesaPagosStripe.procesarEvento(pagoCompletado(d, 100000, 'pi_1'));
        // Llega después un evento de fallo o de sesión vencida: no cambia el estado.
        MesaPagosStripe.procesarEvento(evento('checkout.session.expired', d, d, 100000, 'mxn', 'unpaid', null));
        Assert.areEqual(MesaPagosStripe.Resultado.DUPLICADO, MesaPagosStripe.procesarEvento(pagoCompletado(d, 100000, 'pi_2')));
        Opportunity o = donativo(d);
        Assert.areEqual('Closed Won', o.StageName);
        Assert.areEqual('pi_1', o.Stripe_Pago_Id__c);
    }

    @IsTest
    static void estadoPagoNoRevelaNadaDeOtrosRegistros() {
        Assert.isNull(MesaRegalosController.estadoPago(null));
        Assert.isNull(MesaRegalosController.estadoPago('no-es-un-id'));
        Assert.isNull(MesaRegalosController.estadoPago(campana()));
    }
}
