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
    static void listasDevuelvenCampanasYDonativos() {
        Campaign c = new Campaign(Name = 'Prueba', IsActive = true, ExpectedRevenue = 500);
        insert c;
        insert new Opportunity(Name = 'D1', StageName = 'Closed Won', CloseDate = Date.today(), Amount = 100, CampaignId = c.Id);
        insert new Opportunity(Name = 'D2', StageName = 'Prospecting', CloseDate = Date.today(), Amount = 50, CampaignId = c.Id);

        List<MesaPanelController.CampanaFilaDTO> campanas = MesaPanelController.listarCampanas();
        List<MesaPanelController.DonativoFilaDTO> donativos = MesaPanelController.listarDonativos();
        MesaPanelController.listarReconocimientos();

        System.assertEquals(1, campanas.size());
        System.assertEquals(100, campanas[0].total, 'Solo suma lo pagado');
        System.assertEquals(2, donativos.size());
        Integer pagados = 0;
        for (MesaPanelController.DonativoFilaDTO d : donativos) {
            if (d.pagado) {
                pagados++;
            }
        }
        System.assertEquals(1, pagados);
    }
}
