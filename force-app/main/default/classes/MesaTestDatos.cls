/** Datos de apoyo compartidos por las pruebas. */
@IsTest
public class MesaTestDatos {

    /** Tipo de registro de las campañas del sitio de donaciones. */
    public static Id tipoCampana() {
        return [
            SELECT Id FROM RecordType
            WHERE SobjectType = 'Campaign' AND DeveloperName = :MesaRegalosController.TIPO_CAMPANA
            LIMIT 1
        ].Id;
    }
}