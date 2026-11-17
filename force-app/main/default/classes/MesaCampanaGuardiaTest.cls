@IsTest
private class MesaCampanaGuardiaTest {

    private static Campaign campana(String nombre) {
        Campaign c = new Campaign(Name = nombre, IsActive = true, RecordTypeId = MesaTestDatos.tipoCampana());
        insert c;
        return c;
    }

    private static void donativoPagado(Campaign c) {
        insert new Reconocimiento_Publico__c(Name = 'Donante', Monto__c = 100, Campana__c = c.Id);
    }

    @IsTest
    static void sinDonativosSeEliminaAunSinPermiso() {
        MesaCampanaGuardia.permisoForzado = false;
        Campaign c = campana('Sin donativos');

        Database.DeleteResult r = Database.delete(c, false);

        Assert.isTrue(r.isSuccess());
    }

    @IsTest
    static void conDonativosNoSeEliminaSinPermiso() {
        MesaCampanaGuardia.permisoForzado = false;
        Campaign c = campana('Con donativos');
        donativoPagado(c);

        Database.DeleteResult r = Database.delete(c, false);

        Assert.isFalse(r.isSuccess());
        Assert.isTrue(r.getErrors()[0].getMessage().contains('donativo'));
        Assert.areEqual(1, [SELECT COUNT() FROM Campaign WHERE Id = :c.Id]);
    }

    @IsTest
    static void conDonativosSeEliminaConPermiso() {
        MesaCampanaGuardia.permisoForzado = true;
        Campaign c = campana('Con donativos y admin');
        donativoPagado(c);

        Database.DeleteResult r = Database.delete(c, false);

        Assert.isTrue(r.isSuccess());
    }

    @IsTest
    static void enLoteSoloSeBloqueaLaQueTieneDonativos() {
        MesaCampanaGuardia.permisoForzado = false;
        Campaign libre = campana('Libre');
        Campaign pagada = campana('Pagada');
        donativoPagado(pagada);

        List<Database.DeleteResult> rs = Database.delete(new List<Campaign>{ libre, pagada }, false);

        Assert.isTrue(rs[0].isSuccess());
        Assert.isFalse(rs[1].isSuccess());
    }
}
