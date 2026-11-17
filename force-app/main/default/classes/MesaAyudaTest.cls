/** Pruebas del formulario de ayuda que crea un Case (SCRUM-141). */
@IsTest
private class MesaAyudaTest {

    private static String datos(String correo, String mensaje, String referencia, String trampa) {
        return JSON.serialize(new Map<String, Object>{
            'nombre' => 'Luz Prueba',
            'correo' => correo,
            'mensaje' => mensaje,
            'referencia' => referencia,
            'sitioWeb' => trampa
        });
    }

    private static void esperaError(String json, String fragmento) {
        try {
            MesaRegalosController.enviarAyuda(json);
            Assert.fail('Debía rechazarse');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains(fragmento), 'Mensaje inesperado: ' + e.getMessage());
        }
    }

    @IsTest
    static void creaElCasoConLoQueEscribioLaPersonaYDevuelveSoloElNumero() {
        MesaRegalosController.AyudaResultado r = MesaRegalosController.enviarAyuda(
            datos('luz@example.com', 'Mi pago salió rechazado y no sé por qué.', 'EIJPXYAU', null));

        Assert.isTrue(r.exito);
        Case c = [SELECT CaseNumber, Subject, Description, SuppliedEmail, SuppliedName FROM Case];
        Assert.areEqual(c.CaseNumber, r.numeroCaso);
        Assert.isNull([SELECT Origin FROM Case].Origin, 'No usa el origen Web: dispara un proceso ajeno de la org');
        Assert.isTrue(c.Subject.contains('EIJPXYAU'));
        Assert.isTrue(c.Description.contains('Mi pago salió rechazado'));
        Assert.areEqual('luz@example.com', c.SuppliedEmail);
        Assert.areEqual('Luz Prueba', c.SuppliedName);
    }

    @IsTest
    static void unBotQueLlenaElCampoTrampaNoCreaNada() {
        MesaRegalosController.AyudaResultado r = MesaRegalosController.enviarAyuda(
            datos('bot@example.com', 'Compra pastillas baratas ahora mismo', null, 'http://spam.example'));
        Assert.isTrue(r.exito);
        Assert.areEqual(0, [SELECT COUNT() FROM Case]);
    }

    @IsTest
    static void rechazaCorreoInvalidoMensajeCortoYReferenciaRara() {
        esperaError(datos('no-es-correo', 'Necesito ayuda con mi donativo', null, null), 'correo válido');
        esperaError(datos('luz@example.com', 'ayuda', null, null), 'de detalle');
        esperaError(datos('luz@example.com', 'Necesito ayuda con mi donativo', 'ab', null), 'referencia');
        esperaError(datos('luz@example.com', 'Necesito ayuda con mi donativo', 'ab cd<script>', null), 'referencia');
        Assert.areEqual(0, [SELECT COUNT() FROM Case]);
    }

    @IsTest
    static void frenaEnvioMasivoPorHora() {
        MesaRegalosController.maxAyudasPorHora = 2;
        MesaRegalosController.enviarAyuda(datos('a@example.com', 'Primer mensaje de ayuda', null, null));
        MesaRegalosController.enviarAyuda(datos('b@example.com', 'Segundo mensaje de ayuda', null, null));
        esperaError(datos('c@example.com', 'Tercer mensaje de ayuda', null, null), 'muchas solicitudes');
        Assert.areEqual(2, [SELECT COUNT() FROM Case]);
    }

    @IsTest
    static void ligaElCasoAlContactoSiElCorreoYaExiste() {
        Contact c = new Contact(FirstName = 'Luz', LastName = 'Prueba', Email = 'luz@example.com');
        insert c;
        MesaRegalosController.enviarAyuda(datos('luz@example.com', 'Necesito mi comprobante otra vez', null, null));
        Assert.areEqual(c.Id, [SELECT ContactId FROM Case].ContactId);
    }
}
