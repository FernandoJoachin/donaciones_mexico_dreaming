/**
 * Comunicación con Stripe (US-05): crea la sesión de Checkout y procesa el aviso de pago (webhook).
 *
 * SEGURIDAD:
 *  - La clave secreta vive en la credencial con nombre "Stripe" (External Credential). Apex no puede
 *    leerla y nunca aparece en el código, en el repositorio ni en los registros.
 *  - El secreto de firma del webhook y la dirección del sitio viven en la configuración protegida
 *    Stripe_Config__c (sus datos no son metadata: no viajan al repositorio).
 *  - El monto que se cobra sale siempre de la Opportunity guardada, nunca del navegador.
 *  - Solo un aviso firmado por Stripe marca un donativo como pagado; la página de regreso no.
 */
public without sharing class MesaPagosStripe {

    public static final String MONEDA = 'mxn';
    public static final String ETAPA_PENDIENTE = 'Prospecting';
    public static final String ETAPA_PAGADO = 'Closed Won';
    @TestVisible private static final Long TOLERANCIA_SEGUNDOS = 300;
    private static final String EVENTO_PAGO_COMPLETADO = 'checkout.session.completed';

    /** Resultado de procesar un aviso. Sirve para pruebas y para el registro de depuración. */
    public enum Resultado { CONFIRMADO, DUPLICADO, IGNORADO, RECHAZADO }

    public class StripeException extends Exception {}

    // ---------- Configuración ----------

    private static Stripe_Config__c config() {
        Stripe_Config__c c = Stripe_Config__c.getOrgDefaults();
        return c == null ? new Stripe_Config__c() : c;
    }

    public static String secretoWebhook() {
        return config().Webhook_Secret__c;
    }

    /** Dirección base del sitio, sin diagonal final (por ejemplo https://xxx.my.site.com/donaciones/s). */
    public static String urlSitio() {
        String url = config().Url_Sitio__c;
        if (String.isBlank(url) || !url.trim().startsWithIgnoreCase('https://')) {
            return null;
        }
        return url.trim().removeEnd('/');
    }

    /** Stripe trabaja en la unidad menor de la moneda: centavos. Amount ya se guarda con 2 decimales. */
    public static Long enCentavos(Decimal monto) {
        return (monto.setScale(2, RoundingMode.HALF_UP) * 100).longValue();
    }

    /** Referencia corta que ve el donante y que staff busca en Stripe (últimos 8 caracteres del Id). */
    public static String referencia(Id donativoId) {
        return String.valueOf(donativoId).right(8).toUpperCase();
    }

    // ---------- Sesión de Checkout ----------

    /**
     * Crea (o recupera, por idempotencia) la sesión de Checkout del donativo y devuelve su URL.
     * Requiere: Id, Amount, Campaign.Name y Contacto_Donador__r.Email.
     * Se llama sin DML pendiente en la transacción (Apex no permite callouts después de un DML).
     */
    public static String crearSesion(Opportunity o, String urlExito, String urlCancelacion) {
        String id = String.valueOf(o.Id);
        String correo = o.Contacto_Donador__r == null ? null : o.Contacto_Donador__r.Email;
        String nombreCampana = o.Campaign == null ? null : o.Campaign.Name;

        Map<String, String> p = new Map<String, String>{
            'mode' => 'payment',
            'submit_type' => 'donate',
            'locale' => 'es-419',
            // Siempre en pesos: con Adaptive Pricing Stripe podría cobrar en la moneda del donante
            // y el webhook rechazaría la confirmación por moneda distinta.
            'adaptive_pricing[enabled]' => 'false',
            'line_items[0][quantity]' => '1',
            'line_items[0][price_data][currency]' => MONEDA,
            'line_items[0][price_data][unit_amount]' => String.valueOf(enCentavos(o.Amount)),
            'line_items[0][price_data][product_data][name]' =>
                ('Donativo' + (String.isBlank(nombreCampana) ? '' : ' a ' + nombreCampana)).abbreviate(250),
            'client_reference_id' => id,
            'metadata[donativo_id]' => id,
            'payment_intent_data[metadata][donativo_id]' => id,
            'payment_intent_data[description]' => 'Donativo REF ' + referencia(o.Id),
            'success_url' => urlExito,
            'cancel_url' => urlCancelacion
        };
        if (String.isNotBlank(correo)) {
            p.put('customer_email', correo);
            // En producción Stripe envía el recibo a este correo; en modo de prueba no lo envía solo.
            p.put('payment_intent_data[receipt_email]', correo);
        }

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Stripe/v1/checkout/sessions');
        req.setMethod('POST');
        req.setTimeout(20000);
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        // Mismo donativo = misma sesión durante 24 h: reintentar no abre un segundo cobro.
        req.setHeader('Idempotency-Key', 'mesa-donativo-' + id);
        req.setBody(codificar(p));

        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() != 200) {
            String detalle = detalleError(res.getBody());
            System.debug(LoggingLevel.ERROR, 'Stripe rechazó la sesión del donativo ' + id + ': HTTP ' + res.getStatusCode() + ' ' + detalle);
            throw new StripeException('Stripe respondió ' + res.getStatusCode() + ' ' + detalle);
        }
        Map<String, Object> sesion = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        String url = (String) sesion.get('url');
        if (String.isBlank(url)) {
            throw new StripeException('La sesión no trae URL');
        }
        return url;
    }

    /**
     * Resume el error que devuelve Stripe para el registro de depuración: tipo, código, parámetro y
     * mensaje. Son datos técnicos de la petición (el mensaje explica qué parámetro falló); no se
     * registra el cuerpo completo.
     */
    @TestVisible
    private static String detalleError(String cuerpo) {
        try {
            Map<String, Object> e = (Map<String, Object>) ((Map<String, Object>) JSON.deserializeUntyped(cuerpo)).get('error');
            if (e == null) {
                return '';
            }
            return ('[tipo=' + e.get('type') + ', código=' + e.get('code') + ', parámetro=' + e.get('param')
                + '] ' + e.get('message')).abbreviate(500);
        } catch (Exception ex) {
            return '(respuesta sin formato de error de Stripe)';
        }
    }

    private static String codificar(Map<String, String> parametros) {
        List<String> partes = new List<String>();
        for (String k : parametros.keySet()) {
            partes.add(EncodingUtil.urlEncode(k, 'UTF-8') + '=' + EncodingUtil.urlEncode(parametros.get(k), 'UTF-8'));
        }
        return String.join(partes, '&');
    }

    // ---------- Webhook: firma ----------

    /**
     * Valida el encabezado Stripe-Signature (t=<segundos>,v1=<firma>[,v1=...]) sobre el cuerpo sin procesar:
     * HMAC-SHA256 de "<t>.<cuerpo>" con el secreto whsec_. Rechaza avisos con más de 5 minutos (repetición).
     */
    public static Boolean firmaValida(String cuerpo, String encabezado, String secreto, Long ahoraSegundos) {
        if (String.isBlank(cuerpo) || String.isBlank(encabezado) || String.isBlank(secreto)) {
            return false;
        }
        String t;
        List<String> firmas = new List<String>();
        for (String parte : encabezado.split(',')) {
            String limpia = parte.trim();
            if (limpia.startsWith('t=')) {
                t = limpia.substring(2);
            } else if (limpia.startsWith('v1=')) {
                firmas.add(limpia.substring(3));
            }
        }
        if (t == null || !t.isNumeric() || firmas.isEmpty()) {
            return false;
        }
        Long marca = Long.valueOf(t);
        if (Math.abs(ahoraSegundos - marca) > TOLERANCIA_SEGUNDOS) {
            return false;
        }
        String esperada = EncodingUtil.convertToHex(
            Crypto.generateMac('hmacSHA256', Blob.valueOf(t + '.' + cuerpo), Blob.valueOf(secreto))
        );
        for (String f : firmas) {
            if (igualesEnTiempoConstante(esperada, f)) {
                return true;
            }
        }
        return false;
    }

    private static Boolean igualesEnTiempoConstante(String a, String b) {
        if (a == null || b == null || a.length() != b.length()) {
            return false;
        }
        Integer diferencia = 0;
        for (Integer i = 0; i < a.length(); i++) {
            diferencia |= a.charAt(i) ^ b.charAt(i);
        }
        return diferencia == 0;
    }

    // ---------- Webhook: evento ----------

    /**
     * Procesa un evento ya autenticado. Solo checkout.session.completed con payment_status = paid
     * cambia algo; los demás eventos se ignoran (cancelar o fallar deja el donativo pendiente).
     * Antes de confirmar comprueba la referencia, el monto y la moneda contra lo guardado.
     */
    public static Resultado procesarEvento(String cuerpo) {
        Map<String, Object> evento = (Map<String, Object>) JSON.deserializeUntyped(cuerpo);
        if ((String) evento.get('type') != EVENTO_PAGO_COMPLETADO) {
            return Resultado.IGNORADO;
        }
        Map<String, Object> datos = (Map<String, Object>) evento.get('data');
        Map<String, Object> sesion = datos == null ? null : (Map<String, Object>) datos.get('object');
        if (sesion == null || (String) sesion.get('payment_status') != 'paid') {
            return Resultado.IGNORADO;
        }

        // Referencia: la de la sesión y la de sus metadatos deben coincidir y ser un donativo.
        String ref = (String) sesion.get('client_reference_id');
        Map<String, Object> meta = (Map<String, Object>) sesion.get('metadata');
        String refMeta = meta == null ? null : (String) meta.get('donativo_id');
        Id donativoId = aIdDeOportunidad(ref);
        if (donativoId == null || !ref.equals(refMeta)) {
            return rechazar(ref, 'referencia inválida');
        }

        // FOR UPDATE: si Stripe entrega el mismo aviso dos veces a la vez, el segundo espera y sale como DUPLICADO.
        List<Opportunity> ops = [
            SELECT Id, Amount, StageName, Stripe_Pago_Id__c
            FROM Opportunity WHERE Id = :donativoId LIMIT 1 FOR UPDATE
        ];
        if (ops.isEmpty()) {
            return rechazar(ref, 'donativo inexistente');
        }
        Opportunity o = ops[0];
        String pago = (String) sesion.get('payment_intent');
        if (String.isBlank(pago)) {
            pago = (String) sesion.get('id');
        }
        if (o.StageName == ETAPA_PAGADO) {
            if (o.Stripe_Pago_Id__c != pago) {
                // Un segundo cobro del mismo donativo: staff debe revisarlo (y reembolsarlo) en Stripe.
                System.debug(LoggingLevel.WARN, 'Stripe: el donativo ' + o.Id + ' ya estaba pagado con otro pago: ' + pago);
            }
            return Resultado.DUPLICADO;
        }
        if (o.StageName != ETAPA_PENDIENTE) {
            return rechazar(ref, 'el donativo no está pendiente');
        }
        if (o.Amount == null || aLong(sesion.get('amount_total')) != enCentavos(o.Amount)
                || !MONEDA.equalsIgnoreCase((String) sesion.get('currency'))) {
            return rechazar(ref, 'monto o moneda no coinciden');
        }
        if ([SELECT COUNT() FROM Opportunity WHERE Stripe_Pago_Id__c = :pago] > 0) {
            return rechazar(ref, 'el pago ya confirmó otro donativo');
        }

        update new Opportunity(Id = o.Id, Stripe_Pago_Id__c = pago);
        MesaRegalosService.confirmarPago(new List<Id>{ o.Id });
        return Resultado.CONFIRMADO;
    }

    /** No se confirma; se deja en el registro para staff. Se responde 200: reintentar no lo arreglaría. */
    private static Resultado rechazar(String ref, String motivo) {
        System.debug(LoggingLevel.WARN, 'Stripe: aviso no aplicado (' + motivo + '). Referencia: ' + ref);
        return Resultado.RECHAZADO;
    }

    public static Id aIdDeOportunidad(String valor) {
        if (String.isBlank(valor) || (valor.length() != 15 && valor.length() != 18)) {
            return null;
        }
        try {
            Id i = Id.valueOf(valor);
            return i.getSobjectType() == Opportunity.SObjectType ? i : null;
        } catch (Exception e) {
            return null;
        }
    }

    private static Long aLong(Object valor) {
        if (valor == null) {
            return null;
        }
        try {
            return Long.valueOf(String.valueOf(valor));
        } catch (Exception e) {
            return null;
        }
    }
}
