/**
 * Aviso de pagos de Stripe (webhook). Se publica en el dominio del sitio:
 *   https://<dominio-del-sitio>/services/apexrest/stripe/webhook
 * Lo llama Stripe como usuario guest, así que lo primero es validar la firma; sin firma válida no se
 * lee nada. Respuestas: 200 = recibido (aplicado o ignorado), 400 = firma inválida,
 * 500 = falta configuración o error inesperado (Stripe reintenta).
 */
@RestResource(urlMapping='/stripe/webhook')
global without sharing class MesaStripeWebhook {

    @HttpPost
    global static void recibir() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        String secreto = MesaPagosStripe.secretoWebhook();
        if (String.isBlank(secreto)) {
            System.debug(LoggingLevel.ERROR, 'Stripe: falta el secreto de firma en Stripe_Config__c');
            res.statusCode = 500;
            return;
        }
        String cuerpo = req.requestBody == null ? null : req.requestBody.toString();
        Long ahora = Datetime.now().getTime() / 1000;
        if (!MesaPagosStripe.firmaValida(cuerpo, encabezado(req, 'Stripe-Signature'), secreto, ahora)) {
            res.statusCode = 400;
            return;
        }
        try {
            MesaPagosStripe.Resultado r = MesaPagosStripe.procesarEvento(cuerpo);
            System.debug(LoggingLevel.INFO, 'Stripe: aviso procesado: ' + r);
            res.statusCode = 200;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Stripe: error al procesar el aviso: ' + e.getTypeName() + ' ' + e.getMessage());
            res.statusCode = 500;
        }
    }

    /** Los nombres de encabezado no distinguen mayúsculas. */
    private static String encabezado(RestRequest req, String nombre) {
        for (String k : req.headers.keySet()) {
            if (k.equalsIgnoreCase(nombre)) {
                return req.headers.get(k);
            }
        }
        return null;
    }
}
