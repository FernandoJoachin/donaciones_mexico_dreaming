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
            SELECT Id, Amount, CloseDate, StageName, CampaignId, Visibilidad__c, Nombre_Visible__c, Donacion_Empresa__c, Stripe_Pago_Id__c,
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
        String nombre = primerNombre(o);
        String saludo = String.isBlank(nombre) ? 'Hola:' : 'Hola, ' + nombre + ':';
        String monto = pesos(o.Amount) + ' MXN';
        String fecha = o.CloseDate == null ? '' : fechaTexto(o.CloseDate);
        String enMuro = o.Visibilidad__c == 'Anonima'
            ? 'como «Anónimo», junto con el monto'
            : 'con el nombre que elegiste' + (String.isBlank(o.Nombre_Visible__c) ? '' : ' (' + o.Nombre_Visible__c + ')');
        String correoFacturas = System.Label.Mesa_Correo_Facturas;
        String urlMuro = urlMuro(o);

        List<String[]> filas = new List<String[]>{
            new String[]{ 'Referencia', referencia },
            new String[]{ 'Campaña', campana },
            new String[]{ 'Fecha de pago', fecha }
        };
        if (String.isNotBlank(o.Stripe_Pago_Id__c)) {
            filas.add(new String[]{ 'Pago en Stripe', o.Stripe_Pago_Id__c });
        }

        String muro = 'Tu aportación aparece en el muro de agradecimiento de la campaña ' + enMuro + '.';
        String factura = 'Si necesitas factura, escribe a ' + correoFacturas
            + ' con tus datos fiscales y tu referencia (' + referencia + '). Este comprobante no es una factura (CFDI).';

        String texto = saludo + '\n\n¡Gracias por tu donativo! Este es tu comprobante.\n\nMonto: ' + monto + '\n';
        for (String[] f : filas) {
            texto += f[0] + ': ' + f[1] + '\n';
        }
        texto += '\n' + muro + '\n';
        if (urlMuro != null) {
            texto += 'Míralo aquí: ' + urlMuro + '\n';
        }
        String urlSitio = MesaPagosStripe.urlSitio();
        if (urlSitio != null) {
            texto += 'Conoce las demás campañas: ' + urlSitio + '\n';
        }
        String urlFacturas = urlSitio == null ? null : urlSitio + '/facturas';
        texto += '\n' + factura + '\n';
        if (urlFacturas != null) {
            texto += 'Pasos para pedir tu factura: ' + urlFacturas + '\n';
        }
        texto += '\nCon cariño,\nComunidad Salesforce · Facultad de Matemáticas, UADY';

        // HTML de correo: tablas y estilos en línea, porque los clientes de correo no entienden CSS moderno.
        // Todo lo que viene de datos pasa por escapeHtml4.
        String filasHtml = '';
        for (Integer i = 0; i < filas.size(); i++) {
            String linea = i == filas.size() - 1 ? '' : 'border-bottom:1px solid #e6ebf3;';
            filasHtml += '<tr><td style="padding:11px 0;' + linea + 'color:#5b6475;font-size:14px;width:38%">' + filas[i][0].escapeHtml4()
                + '</td><td style="padding:11px 0;' + linea + 'color:#101828;font-size:14px;font-weight:700;text-align:right;word-break:break-all">'
                + filas[i][1].escapeHtml4() + '</td></tr>';
        }
        String boton = '';
        if (urlMuro != null) {
            boton = '<table role="presentation" cellpadding="0" cellspacing="0" border="0" align="center" style="margin:22px auto 0">'
                + '<tr><td bgcolor="#123a7a" style="border-radius:999px"><a href="' + urlMuro.escapeHtml4()
                + '" style="display:inline-block;padding:13px 26px;font-size:15px;font-weight:700;color:#ffffff;text-decoration:none;border-radius:999px">'
                + 'Ver el muro de agradecimiento</a></td></tr></table>';
        }
        String html = '<!DOCTYPE html><html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">'
            + '<meta name="color-scheme" content="light"><meta name="supported-color-schemes" content="light"></head>'
            + '<body style="margin:0;padding:0;background:#eef2f8">'
            + '<div style="display:none;max-height:0;overflow:hidden;opacity:0">Tu comprobante de donativo · Ref. ' + referencia.escapeHtml4() + '</div>'
            + '<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" bgcolor="#eef2f8"><tr><td align="center" style="padding:28px 12px">'
            + '<table role="presentation" width="600" cellpadding="0" cellspacing="0" border="0" style="width:100%;max-width:600px;font-family:Arial,Helvetica,sans-serif">'
            // Encabezado
            + '<tr><td bgcolor="#123a7a" style="background:#123a7a;background-image:linear-gradient(135deg,#123a7a,#2f80e6);border-radius:18px 18px 0 0;padding:30px 32px;text-align:center">'
            + '<div style="font-size:12px;letter-spacing:1.5px;text-transform:uppercase;color:#cfe3ff;font-weight:700">Mesa de regalos · México Dreamin</div>'
            + '<div style="font-size:26px;line-height:32px;color:#ffffff;font-weight:700;margin-top:10px">¡Gracias por tu donativo!</div>'
            + '</td></tr>'
            // Tarjeta
            + '<tr><td bgcolor="#ffffff" style="background:#ffffff;padding:30px 32px;border-radius:0 0 18px 18px">'
            + '<p style="margin:0 0 20px;font-size:16px;line-height:24px;color:#1d2433">' + saludo.escapeHtml4()
            + ' recibimos tu aportación. Este es tu comprobante.</p>'
            + '<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0"><tr><td bgcolor="#eaf3ff" style="background:#eaf3ff;border-radius:14px;padding:20px;text-align:center">'
            + '<div style="font-size:12px;letter-spacing:1px;text-transform:uppercase;color:#4a5b78;font-weight:700">Monto donado</div>'
            + '<div style="font-size:34px;line-height:42px;color:#123a7a;font-weight:800;margin-top:4px">' + monto.escapeHtml4() + '</div>'
            + '<div style="font-size:14px;color:#4a5b78;margin-top:2px">' + campana.escapeHtml4() + '</div>'
            + '</td></tr></table>'
            + '<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="margin-top:18px">' + filasHtml + '</table>'
            + '<p style="margin:22px 0 0;font-size:14px;line-height:22px;color:#344054">' + muro.escapeHtml4() + '</p>'
            + boton
            + (urlSitio == null ? '' : '<p style="margin:14px 0 0;text-align:center;font-size:14px"><a href="' + urlSitio.escapeHtml4()
                + '" style="color:#123a7a;font-weight:700">Conocer las demás campañas</a></p>')
            + '<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="margin-top:26px"><tr>'
            + '<td bgcolor="#f4f7fc" style="background:#f4f7fc;border-left:4px solid #2f80e6;border-radius:8px;padding:14px 16px;font-size:13px;line-height:20px;color:#344054">'
            + factura.escapeHtml4()
            + (urlFacturas == null ? '' : '<br/><a href="' + urlFacturas.escapeHtml4()
                + '" style="color:#123a7a;font-weight:700">Ver los pasos para pedir tu factura</a>')
            + '</td></tr></table>'
            + '</td></tr>'
            // Pie
            + '<tr><td style="padding:20px 12px 4px;text-align:center;font-size:12px;line-height:18px;color:#7a8499">'
            + 'Comunidad Salesforce · Facultad de Matemáticas, UADY<br/>Guarda este correo: tu referencia es <strong>' + referencia.escapeHtml4() + '</strong>.'
            + '</td></tr></table></td></tr></table></body></html>';

        Messaging.SingleEmailMessage m = new Messaging.SingleEmailMessage();
        m.setToAddresses(new List<String>{ o.Contacto_Donador__r.Email });
        m.setSubject('Tu comprobante de donativo · Ref. ' + referencia);
        m.setPlainTextBody(texto);
        m.setHtmlBody(html);
        m.setSaveAsActivity(false);
        m.setUseSignature(false);
        return m;
    }

    /**
     * Nombre para el saludo. Si se donó con nombre público de persona, se usa ese; el nombre del contacto
     * no sirve cuando el contacto se creó antes en un donativo anónimo y quedó como "Anónimo".
     * Con empresa o sin nombre confiable, el saludo va sin nombre.
     */
    private static String primerNombre(Opportunity o) {
        String candidato;
        if (o.Visibilidad__c == 'Publica' && o.Donacion_Empresa__c != true && String.isNotBlank(o.Nombre_Visible__c)) {
            candidato = o.Nombre_Visible__c.trim().substringBefore(' ');
        } else if (o.Donacion_Empresa__c != true && o.Contacto_Donador__r != null) {
            candidato = o.Contacto_Donador__r.FirstName;
        }
        return String.isBlank(candidato) || candidato == 'Anónimo' ? null : candidato;
    }

    /** Enlace al muro de la campaña; null si el sitio no está configurado. */
    private static String urlMuro(Opportunity o) {
        String sitio = MesaPagosStripe.urlSitio();
        if (sitio == null || o.CampaignId == null) {
            return null;
        }
        return sitio + '/muro?campana=' + o.CampaignId;
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
