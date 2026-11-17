/** Pruebas de la lista de campañas (US-01) y de la página de presentación de una campaña (US-02). */
@IsTest
private class MesaCampanasTest {

    @TestSetup
    static void datos() {
        insert new Campaign(RecordTypeId = MesaTestDatos.tipoCampana(), Name = 'México Dreaming TEST', IsActive = true, ExpectedRevenue = 10000);
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
        insert new Campaign(RecordTypeId = MesaTestDatos.tipoCampana(),
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
        insert new Campaign(RecordTypeId = MesaTestDatos.tipoCampana(), Name = 'Pausada', IsActive = false);
        insert new Campaign(RecordTypeId = MesaTestDatos.tipoCampana(),
            Name = 'Futura', IsActive = true,
            StartDate = Date.today().addDays(5), EndDate = Date.today().addDays(30)
        );

        Assert.isNull(campanaPorNombre('Pausada'));
        Assert.isNull(campanaPorNombre('Futura'));
    }

    @IsTest
    static void campanaDeOtroTipoNoApareceEnElSitio() {
        // Las campañas de otras aplicaciones de la org no se publican. Si la org solo tiene el tipo
        // Donacion no hay otro tipo con que probar y la prueba no aplica.
        List<RecordType> otros = [
            SELECT Id FROM RecordType
            WHERE SobjectType = 'Campaign' AND IsActive = true
            AND DeveloperName != :MesaRegalosController.TIPO_CAMPANA
            LIMIT 1
        ];
        if (otros.isEmpty()) {
            return;
        }
        insert new Campaign(Name = 'Otra aplicación TEST', IsActive = true, RecordTypeId = otros[0].Id);

        Assert.isNull(campanaPorNombre('Otra aplicación TEST'));
    }

    @IsTest
    static void campanaSinMetaApareceConMetaCeroYSinError() {
        insert new Campaign(RecordTypeId = MesaTestDatos.tipoCampana(), Name = 'Donación general TEST', IsActive = true);

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
        Campaign c = new Campaign(RecordTypeId = MesaTestDatos.tipoCampana(),
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
        Campaign pausada = new Campaign(RecordTypeId = MesaTestDatos.tipoCampana(), Name = 'Pausada', IsActive = false);
        Campaign futura = new Campaign(RecordTypeId = MesaTestDatos.tipoCampana(),
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

    // ---------- US-22: historia de cada campaña ----------

    @IsTest
    static void campanaIndividualDevuelveSuHistoriaEImpactosOrdenados() {
        Campaign c = [SELECT Id FROM Campaign LIMIT 1];
        c.Resumen__c = '  Llevamos a 20 estudiantes al evento  ';
        c.Historia__c = 'Primer párrafo.\n\nSegundo párrafo.\r\n\r\n\n  Tercer párrafo.  ';
        c.Para_Quien__c = 'Estudiantes de la facultad';
        c.Organiza__c = 'Comunidad de la facultad';
        update c;
        insert new List<Nivel_Impacto__c>{
            new Nivel_Impacto__c(Campana__c = c.Id, Monto__c = 1000, Descripcion__c = 'Un boleto', Orden__c = 2),
            new Nivel_Impacto__c(Campana__c = c.Id, Monto__c = 250, Descripcion__c = 'Un mes de internet', Orden__c = 1),
            new Nivel_Impacto__c(Campana__c = c.Id, Monto__c = 5000, Descripcion__c = 'Hospedaje', Orden__c = null),
            new Nivel_Impacto__c(Campana__c = c.Id, Monto__c = 0, Descripcion__c = 'Monto inválido', Orden__c = 3)
        };

        MesaRegalosController.CampanaDTO d = MesaRegalosController.obtenerCampana(String.valueOf(c.Id));
        Assert.areEqual('Llevamos a 20 estudiantes al evento', d.resumen);
        Assert.areEqual(new List<String>{ 'Primer párrafo.', 'Segundo párrafo.', 'Tercer párrafo.' }, d.historia);
        Assert.areEqual('Estudiantes de la facultad', d.paraQuien);
        Assert.areEqual('Comunidad de la facultad', d.organiza);
        Assert.areEqual(3, d.impactos.size(), 'El nivel con monto 0 no se publica');
        Assert.areEqual('Un mes de internet', d.impactos[0].descripcion);
        Assert.areEqual('Un boleto', d.impactos[1].descripcion);
        Assert.areEqual('Hospedaje', d.impactos[2].descripcion, 'Sin orden va al final');
    }

    @IsTest
    static void campanaSinHistoriaDevuelveListasVaciasYNoSeRompe() {
        Id campanaId = [SELECT Id FROM Campaign LIMIT 1].Id;
        MesaRegalosController.CampanaDTO d = MesaRegalosController.obtenerCampana(String.valueOf(campanaId));
        Assert.isNull(d.resumen);
        Assert.isNull(d.paraQuien);
        Assert.isNull(d.organiza);
        Assert.areEqual(0, d.historia.size());
        Assert.areEqual(0, d.impactos.size());
        Assert.areEqual(0, d.donantes);
    }

    @IsTest
    static void donantesCuentaPersonasDistintasConDonacionPagada() {
        Id campanaId = [SELECT Id FROM Campaign LIMIT 1].Id;
        Contact ana = [SELECT Id FROM Contact LIMIT 1];
        Contact beto = new Contact(FirstName = 'Beto', LastName = 'Prueba', Email = 'beto.prueba@example.com');
        Contact carla = new Contact(FirstName = 'Carla', LastName = 'Prueba', Email = 'carla.prueba@example.com');
        insert new List<Contact>{ beto, carla };
        insert new List<Opportunity>{
            new Opportunity(Name = 'A1', StageName = 'Closed Won', CloseDate = Date.today(), Amount = 100, CampaignId = campanaId, Contacto_Donador__c = ana.Id),
            new Opportunity(Name = 'A2', StageName = 'Closed Won', CloseDate = Date.today(), Amount = 200, CampaignId = campanaId, Contacto_Donador__c = ana.Id),
            new Opportunity(Name = 'B1', StageName = 'Closed Won', CloseDate = Date.today(), Amount = 300, CampaignId = campanaId, Contacto_Donador__c = beto.Id),
            new Opportunity(Name = 'C1', StageName = 'Prospecting', CloseDate = Date.today().addDays(10), Amount = 900, CampaignId = campanaId, Contacto_Donador__c = carla.Id)
        };

        MesaRegalosController.CampanaDTO detalle = MesaRegalosController.obtenerCampana(String.valueOf(campanaId));
        Assert.areEqual(2, detalle.donantes, 'Ana cuenta una vez; Carla está pendiente y no cuenta');
        Assert.areEqual(3, detalle.donativos);
        MesaRegalosController.CampanaDTO enLista = campanaPorNombre('México Dreaming TEST');
        Assert.areEqual(2, enLista.donantes);
        Assert.areEqual(0, enLista.impactos.size(), 'La lista no carga niveles de impacto');
    }
}
