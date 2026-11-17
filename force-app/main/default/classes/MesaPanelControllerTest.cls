@IsTest
private class MesaPanelControllerTest {

    @IsTest
    static void resumenSumaSoloPagadosYCuentaActivas() {
        Campaign activa = new Campaign(Name = 'Activa', IsActive = true, ExpectedRevenue = 1000);
        Campaign cerrada = new Campaign(Name = 'Cerrada', IsActive = true, EndDate = Date.today().addDays(-3));
        insert new List<Campaign>{ activa, cerrada };
        insert new List<Opportunity>{
            new Opportunity(Name = 'Pagado', StageName = 'Closed Won', CloseDate = Date.today(), Amount = 250, CampaignId = activa.Id),
            new Opportunity(Name = 'Pendiente', StageName = 'Prospecting', CloseDate = Date.today(), Amount = 900, CampaignId = activa.Id)
        };

        Test.startTest();
        MesaPanelController.ResumenDTO r = MesaPanelController.obtenerResumen();
        Test.stopTest();

        System.assertEquals(250, r.totalRecaudado, 'Solo cuenta lo pagado');
        System.assertEquals(1, r.donativosPagados);
        System.assertEquals(1, r.campanasActivas, 'La campaña con fecha de cierre pasada no es activa');
        System.assertEquals(2, r.campanas.size());
    }

    @IsTest
    static void donativosSePaginanConCursorYFiltran() {
        Campaign c = new Campaign(Name = 'Prueba', IsActive = true, ExpectedRevenue = 500);
        insert c;
        List<Opportunity> ops = new List<Opportunity>();
        for (Integer i = 0; i < 5; i++) {
            ops.add(new Opportunity(
                Name = 'Donativo ' + i, StageName = i < 3 ? 'Closed Won' : 'Prospecting',
                CloseDate = Date.today(), Amount = 100, CampaignId = c.Id
            ));
        }
        insert ops;

        MesaPanelController.PaginaDonativosDTO p1 = MesaPanelController.listarDonativos('todos', null, 2, null, null);
        System.assertEquals(5, p1.total);
        System.assertEquals(2, p1.filas.size());
        System.assert(p1.haySiguiente, 'Hay más páginas');

        MesaPanelController.DonativoFilaDTO ultima = p1.filas[1];
        MesaPanelController.PaginaDonativosDTO p2 = MesaPanelController.listarDonativos('todos', null, 2, ultima.creado, ultima.id);
        System.assertEquals(2, p2.filas.size());
        System.assertNotEquals(p1.filas[0].id, p2.filas[0].id, 'La segunda página no repite filas');

        System.assertEquals(3, MesaPanelController.listarDonativos('pagados', null, 10, null, null).total);
        System.assertEquals(2, MesaPanelController.listarDonativos('pendientes', null, 10, null, null).total);
        System.assertEquals(1, MesaPanelController.listarDonativos('todos', 'Donativo 4', 10, null, null).total);
    }

    @IsTest
    static void reconocimientosYCampanasListan() {
        Campaign c = new Campaign(Name = 'Prueba', IsActive = true, ExpectedRevenue = 500);
        insert c;
        List<MesaPanelController.CampanaFilaDTO> campanas = MesaPanelController.listarCampanas();
        System.assertEquals(1, campanas.size());
        MesaPanelController.PaginaReconocimientosDTO r = MesaPanelController.listarReconocimientos('ocultos', 'x', 20, null, null);
        System.assertEquals(0, r.total);
        System.assertEquals(false, r.haySiguiente);
    }
}
