/**
 * Comprobante por correo al confirmarse un pago (US-07, CA3 y CA4).
 *
 * Quién manda el correo: la confirmación del pago corre como el usuario guest del sitio, que no tiene
 * (ni debe tener) el permiso "Send Email". Por eso confirmarPago solo publica un evento de plataforma
 * (Comprobante_Pago__e) y el trigger que lo atiende corre como usuario interno (Automated Process).
 *  - El evento se publica después del commit: el trigger ve el donativo ya pagado.
 *  - Si el correo falla, el pago ya quedó confirmado; el motivo queda en Opportunity.Comprobante_Estado__c.
 *  - Solo se publica para donativos que confirmarPago acaba de pasar a pagados, y enviar() omite los que
 *    ya dicen "Enviado", así que un aviso repetido no manda un segundo correo.
 *
 * El correo de facturación sale de la etiqueta personalizada Mesa_Correo_Facturas
 * (Setup > Etiquetas personalizadas), para cambiarlo sin desplegar código.
 */
public without sharing class MesaComprobante {

    public static final String ESTADO_ENVIADO = 'Enviado';

    /** Correos armados en la última ejecución; las pruebas los revisan sin que se envíe nada. */
    @TestVisible private static List<Messaging.SingleEmailMessage> ultimosCorreos = new List<Messaging.SingleEmailMessage>();

    /** Publica el aviso. No lanza excepciones: un problema con el correo no debe deshacer el pago. */
    public static void programar(List<Id> donativoIds) {
        if (donativoIds == null || donativoIds.isEmpty()) {
            return;
        }
        try {
            List<Comprobante_Pago__e> eventos = new List<Comprobante_Pago__e>();
            for (Id donativoId : donativoIds) {
                eventos.add(new Comprobante_Pago__e(Donativo_Id__c = donativoId));
            }
            for (Database.SaveResult r : EventBus.publish(eventos)) {
                if (!r.isSuccess()) {
                    System.debug(LoggingLevel.ERROR, 'Comprobante: no se pudo publicar el aviso: ' + r.getErrors()[0].getStatusCode());
                }
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Comprobante: no se pudo programar el envío: ' + e.getTypeName() + ' ' + e.getMessage());
        }
    }

    /**
     * Arma y envía un comprobante por donativo pagado que tenga correo y no lo haya recibido ya.
     * Anota el resultado en Comprobante_Estado__c. Devuelve cuántos se enviaron.
     */
    public static Integer enviar(List<Id> ids) {
        ultimosCorreos = new List<Messaging.SingleEmailMessage>();
        List<Opportunity> porEnviar = new List<Opportunity>();
        Id remitenteId = remitenteVerificado();
        for (Opportunity o : [
            SELECT Id, Amount, CloseDate, StageName, Visibilidad__c, Nombre_Visible__c, Stripe_Pago_Id__c,
                   Comprobante_Estado__c, Campaign.Name, Contacto_Donador__r.FirstName, Contacto_Donador__r.Email
            FROM Opportunity
            WHERE Id IN :ids AND StageName = 'Closed Won'
        ]) {
            if (o.Comprobante_Estado__c == ESTADO_ENVIADO) {
                continue;
            }
            if (o.Contacto_Donador__r != null && String.isNotBlank(o.Contacto_Donador__r.Email)) {
                porEnviar.add(o);
                Messaging.SingleEmailMessage correo = armarCorreo(o);
                // Con dirección verificada el correo sale a nombre de la organización. Sin ella, el
                // remitente sería el de Automated Process (sin dominio) y algunos servidores lo rechazan.
                if (remitenteId != null) {
                    correo.setOrgWideEmailAddressId(remitenteId);
                } else {
                    correo.setSenderDisplayName('Mesa de regalos · México Dreamin');
                }
                ultimosCorreos.add(correo);
            }
        }
        if (ultimosCorreos.isEmpty()) {
            return 0;
        }
        Integer enviados = 0;
        List<Opportunity> resultado = new List<Opportunity>();
        try {
            List<Messaging.SendEmailResult> envios = Messaging.sendEmail(ultimosCorreos, false);
            for (Integer i = 0; i < envios.size(); i++) {
                Messaging.SendEmailResult r = envios[i];
                String estado = ESTADO_ENVIADO;
                if (r.isSuccess()) {
                    enviados++;
                } else {
                    // Solo el código: el mensaje de error podría incluir el correo del donante.
                    estado = 'Error: ' + r.getErrors()[0].getStatusCode();
                    System.debug(LoggingLevel.ERROR, 'Comprobante no enviado: ' + estado);
                }
                resultado.add(new Opportunity(Id = porEnviar[i].Id, Comprobante_Estado__c = estado));
            }
        } catch (Exception e) {
            // Típico en sandbox: "The organization is not permitted to send email" (Deliverability apagado).
            System.debug(LoggingLevel.ERROR, 'Comprobante: la org no pudo enviar correos: ' + e.getTypeName());
            for (Opportunity o : porEnviar) {
                resultado.add(new Opportunity(Id = o.Id, Comprobante_Estado__c = ('Error: ' + e.getTypeName()).left(255)));
            }
        }
        update resultado;
        return enviados;
    }

    /**
     * Dirección remitente verificada (Setup > Direcciones de correo de toda la organización) cuyo
     * correo está en la etiqueta Mesa_Correo_Remitente. Si no existe, devuelve null y se envía como antes.
     */
    private static Id remitenteVerificado() {
        String direccion = System.Label.Mesa_Correo_Remitente;
        List<OrgWideEmailAddress> encontradas = [SELECT Id FROM OrgWideEmailAddress WHERE Address = :direccion LIMIT 1];
        return encontradas.isEmpty() ? null : encontradas[0].Id;
    }

    @TestVisible
    private static Messaging.SingleEmailMessage armarCorreo(Opportunity o) {
        String referencia = MesaPagosStripe.referencia(o.Id);
        String campana = o.Campaign == null || String.isBlank(o.Campaign.Name) ? 'Donación general' : o.Campaign.Name;
        String nombre = o.Contacto_Donador__r.FirstName;
        String saludo = String.isBlank(nombre) ? 'Hola:' : 'Hola, ' + nombre + ':';
        String monto = pesos(o.Amount);
        String fecha = o.CloseDate == null ? '' : fechaTexto(o.CloseDate);
        String enMuro = o.Visibilidad__c == 'Anonima'
            ? 'como «Anónimo», junto con el monto'
            : 'con el nombre que elegiste' + (String.isBlank(o.Nombre_Visible__c) ? '' : ' (' + o.Nombre_Visible__c + ')');
        String correoFacturas = System.Label.Mesa_Correo_Facturas;

        List<String[]> filas = new List<String[]>{
            new String[]{ 'Referencia', referencia },
            new String[]{ 'Campaña', campana },
            new String[]{ 'Monto', monto + ' MXN' },
            new String[]{ 'Fecha de pago', fecha }
        };
        if (String.isNotBlank(o.Stripe_Pago_Id__c)) {
            filas.add(new String[]{ 'Pago en Stripe', o.Stripe_Pago_Id__c });
        }

        String texto = saludo + '\n\n'
            + '¡Gracias por tu donativo! Este es tu comprobante.\n\n';
        String tabla = '';
        for (String[] f : filas) {
            texto += f[0] + ': ' + f[1] + '\n';
            tabla += '<tr><td style="padding:6px 12px 6px 0;color:#5b6475">' + f[0].escapeHtml4()
                + '</td><td style="padding:6px 0;font-weight:700">' + f[1].escapeHtml4() + '</td></tr>';
        }
        String muro = 'Tu aportación aparece en el muro de agradecimiento de la campaña ' + enMuro + '.';
        String factura = 'Si necesitas factura, escribe a ' + correoFacturas
            + ' con tus datos fiscales y tu referencia (' + referencia + '). Este comprobante no es una factura (CFDI).';
        texto += '\n' + muro + '\n\n' + factura + '\n\nCon cariño,\nComunidad Salesforce · Facultad de Matemáticas, UADY';

        String html = '<div style="font-family:Arial,Helvetica,sans-serif;color:#1d2433;max-width:560px">'
            + '<p>' + saludo.escapeHtml4() + '</p>'
            + '<p><strong>¡Gracias por tu donativo!</strong> Este es tu comprobante.</p>'
            + '<table style="border-collapse:collapse;margin:12px 0">' + tabla + '</table>'
            + '<p>' + muro.escapeHtml4() + '</p>'
            + '<p style="background:#f2f5fb;padding:12px;border-radius:8px">' + factura.escapeHtml4() + '</p>'
            + '<p>Con cariño,<br/>Comunidad Salesforce · Facultad de Matemáticas, UADY</p></div>';

        Messaging.SingleEmailMessage m = new Messaging.SingleEmailMessage();
        m.setToAddresses(new List<String>{ o.Contacto_Donador__r.Email });
        m.setSubject('Tu comprobante de donativo · Ref. ' + referencia);
        m.setPlainTextBody(texto);
        m.setHtmlBody(html);
        m.setSaveAsActivity(false);
        m.setUseSignature(false);
        return m;
    }

    /** 1234.5 -> "$1,234.50" (sin depender del idioma del usuario que corre el envío). */
    @TestVisible
    private static String pesos(Decimal monto) {
        Decimal v = (monto == null ? 0 : monto).setScale(2, RoundingMode.HALF_UP);
        String[] partes = String.valueOf(v.abs()).split('\\.');
        String entero = partes[0];
        String conComas = '';
        while (entero.length() > 3) {
            conComas = ',' + entero.right(3) + conComas;
            entero = entero.left(entero.length() - 3);
        }
        return (v < 0 ? '-' : '') + '$' + entero + conComas + '.' + partes[1];
    }

    private static final List<String> MESES = new List<String>{
        'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
        'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    };

    private static String fechaTexto(Date d) {
        return d.day() + ' de ' + MESES[d.month() - 1] + ' de ' + d.year();
    }
}
