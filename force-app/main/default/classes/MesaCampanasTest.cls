/** Pruebas de la lista de campañas (US-01) y de la página de presentación de una campaña (US-02). */
@IsTest
private class MesaCampanasTest {

    @TestSetup
    static void datos() {
        insert new Campaign(Name = 'México Dreaming TEST', IsActive = true, ExpectedRevenue = 10000);
        insert new Contact(FirstName = 'Ana', LastName = 'Prueba', Email = 'ana.prueba@example.com');
    }

    // ---------- US-01: lista de campañas del sitio central ----------

    private static MesaRegalosController.CampanaDTO campanaPorNombre(String nombre) {
        for (MesaRegalosController.CampanaDTO d : MesaRegalosController.obtenerCampanas()) {
            if (d.nombre == nombre) {
                return d;
            }
        }
        return null;
    }

    @IsTest
    static void campanaActivaApareceConSuMetaYAvance() {
        Id campanaId = [SELECT Id FROM Campaign LIMIT 1].Id;
        insert new Opportunity(
            Name = 'Pagado', StageName = 'Closed Won', CloseDate = Date.today(),
            Amount = 2500, CampaignId = campanaId
        );

        MesaRegalosController.CampanaDTO d = campanaPorNombre('México Dreaming TEST');
        Assert.isNotNull(d);
        Assert.isTrue(d.activa);
        Assert.isTrue(d.meta == 10000);
        Assert.isTrue(d.total == 2500);
        Assert.isTrue(d.porcentaje == 25);
        Assert.areEqual(1, d.donativos);
    }

    @IsTest
    static void promesasPendientesNoCuentanEnElAvance() {
        Id campanaId = [SELECT Id FROM Campaign LIMIT 1].Id;
        insert new Opportunity(
            Name = 'Promesa', StageName = 'Prospecting', CloseDate = Date.today().addDays(30),
            Amount = 5000, CampaignId = campanaId
        );

        MesaRegalosController.CampanaDTO d = campanaPorNombre('México Dreaming TEST');
        Assert.isTrue(d.total == 0);
        Assert.isTrue(d.porcentaje == 0);
        Assert.areEqual(0, d.donativos);
    }

    @IsTest
    static void campanaTerminadaSeMarcaComoCerrada() {
        insert new Campaign(
            Name = 'Campaña 2025', IsActive = true, ExpectedRevenue = 40000,
            StartDate = Date.today().addDays(-60), EndDate = Date.today().addDays(-1)
        );

        MesaRegalosController.CampanaDTO d = campanaPorNombre('Campaña 2025');
        Assert.isNotNull(d);
        Assert.isFalse(d.activa);
        Assert.isTrue(campanaPorNombre('México Dreaming TEST').activa);
    }

    @IsTest
    static void campanaPausadaOFuturaNoAparece() {
        insert new Campaign(Name = 'Pausada', IsActive = false);
        insert new Campaign(
            Name = 'Futura', IsActive = true,
            StartDate = Date.today().addDays(5), EndDate = Date.today().addDays(30)
        );

        Assert.isNull(campanaPorNombre('Pausada'));
        Assert.isNull(campanaPorNombre('Futura'));
    }

    @IsTest
    static void campanaSinMetaApareceConMetaCeroYSinError() {
        insert new Campaign(Name = 'Donación general TEST', IsActive = true);

        MesaRegalosController.CampanaDTO d = campanaPorNombre('Donación general TEST');
        Assert.isNotNull(d);
        Assert.isTrue(d.meta == 0);
        Assert.isTrue(d.porcentaje == 0);
        Assert.isTrue(d.activa);
    }

    @IsTest
    static void campanaDevuelveSuImagenSoloSiEsHttps() {
        Campaign c = [SELECT Id FROM Campaign WHERE Name = 'México Dreaming TEST' LIMIT 1];
        Assert.isNull(campanaPorNombre('México Dreaming TEST').imagenUrl);

        c.Imagen_Url__c = 'https://example.com/foto.jpg';
        update c;
        Assert.areEqual('https://example.com/foto.jpg', campanaPorNombre('México Dreaming TEST').imagenUrl);

        c.Imagen_Url__c = 'http://example.com/foto.jpg';
        update c;
        Assert.isNull(campanaPorNombre('México Dreaming TEST').imagenUrl);
    }

    @IsTest
    static void sinCampanasPublicadasDevuelveListaVacia() {
        delete [SELECT Id FROM Campaign];
        Assert.areEqual(0, MesaRegalosController.obtenerCampanas().size());
    }

    // ---------- US-02: página de presentación de una campaña ----------

    @IsTest
    static void campanaIndividualDevuelveSusDatosYAvance() {
        Id campanaId = [SELECT Id FROM Campaign LIMIT 1].Id;
        insert new Opportunity(
            Name = 'Pagado', StageName = 'Closed Won', CloseDate = Date.today(),
            Amount = 2500, CampaignId = campanaId
        );
        insert new Opportunity(
            Name = 'Promesa', StageName = 'Prospecting', CloseDate = Date.today().addDays(30),
            Amount = 9000, CampaignId = campanaId
        );

        MesaRegalosController.CampanaDTO d = MesaRegalosController.obtenerCampana(String.valueOf(campanaId));
        Assert.isNotNull(d);
        Assert.areEqual('México Dreaming TEST', d.nombre);
        Assert.isTrue(d.activa);
        Assert.isTrue(d.meta == 10000);
        Assert.isTrue(d.total == 2500);
        Assert.isTrue(d.porcentaje == 25);
        Assert.areEqual(1, d.donativos);
    }

    @IsTest
    static void campanaIndividualSinPagosTieneTotalCero() {
        Id campanaId = [SELECT Id FROM Campaign LIMIT 1].Id;
        MesaRegalosController.CampanaDTO d = MesaRegalosController.obtenerCampana(String.valueOf(campanaId));
        Assert.isNotNull(d);
        Assert.isTrue(d.total == 0);
        Assert.isTrue(d.porcentaje == 0);
        Assert.areEqual(0, d.donativos);
    }

    @IsTest
    static void campanaIndividualCerradaSeDevuelveComoInactiva() {
        Campaign c = new Campaign(
            Name = 'Campaña 2025', IsActive = true, ExpectedRevenue = 40000,
            StartDate = Date.today().addDays(-60), EndDate = Date.today().addDays(-1)
        );
        insert c;

        MesaRegalosController.CampanaDTO d = MesaRegalosController.obtenerCampana(String.valueOf(c.Id));
        Assert.isNotNull(d);
        Assert.isFalse(d.activa);
    }

    @IsTest
    static void campanaIndividualNoPublicadaOInvalidaDevuelveNulo() {
        Campaign pausada = new Campaign(Name = 'Pausada', IsActive = false);
        Campaign futura = new Campaign(
            Name = 'Futura', IsActive = true,
            StartDate = Date.today().addDays(5), EndDate = Date.today().addDays(30)
        );
        insert new List<Campaign>{ pausada, futura };
        Id contactoId = [SELECT Id FROM Contact LIMIT 1].Id;

        Assert.isNull(MesaRegalosController.obtenerCampana(String.valueOf(pausada.Id)));
        Assert.isNull(MesaRegalosController.obtenerCampana(String.valueOf(futura.Id)));
        Assert.isNull(MesaRegalosController.obtenerCampana(String.valueOf(contactoId)));   // Id de otro objeto
        Assert.isNull(MesaRegalosController.obtenerCampana('no-es-un-id'));
        Assert.isNull(MesaRegalosController.obtenerCampana(''));
        Assert.isNull(MesaRegalosController.obtenerCampana(null));

        String borrada = String.valueOf(futura.Id);
        delete futura;
        Assert.isNull(MesaRegalosController.obtenerCampana(borrada));
    }
}
