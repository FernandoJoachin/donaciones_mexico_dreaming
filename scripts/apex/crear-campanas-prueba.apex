// Datos de PRUEBA para revisar la lista de campañas (US-01) en la org de desarrollo.
// No es parte del repo. Borra después con:  DELETE [SELECT Id FROM Campaign WHERE Name LIKE '% (prueba)'];
Date hoy = Date.today();

List<Campaign> campanas = new List<Campaign>{
    new Campaign(Name = 'Boleto al evento (prueba)', IsActive = true, Status = 'In Progress',
        ExpectedRevenue = 50000, StartDate = hoy.addDays(-10), EndDate = hoy.addDays(12),
        Description = 'Ayuda a que más ex-alumnos asistan al evento.'),
    new Campaign(Name = 'Viaje a Ciudad de México (prueba)', IsActive = true, Status = 'In Progress',
        ExpectedRevenue = 30000, StartDate = hoy.addDays(-5), EndDate = hoy.addDays(26),
        Description = 'Apoya el viaje del grupo a Mexico Dreaming.'),
    new Campaign(Name = 'Donación general (prueba)', IsActive = true, Status = 'In Progress',
        Description = 'Aporta sin elegir una campaña específica.'),
    new Campaign(Name = 'Campaña 2025 (prueba)', IsActive = true, Status = 'Completed',
        ExpectedRevenue = 40000, StartDate = hoy.addDays(-200), EndDate = hoy.addDays(-90),
        Description = 'Campaña del año pasado, ya cerrada.'),
    new Campaign(Name = 'Campaña pausada (prueba)', IsActive = false, Status = 'Planned',
        ExpectedRevenue = 10000, StartDate = hoy.addDays(-1), EndDate = hoy.addDays(30))
};
insert campanas;

Map<String, Id> ids = new Map<String, Id>();
for (Campaign c : campanas) {
    ids.put(c.Name, c.Id);
}

List<Opportunity> pagos = new List<Opportunity>{
    new Opportunity(Name = 'Pago de prueba 1', StageName = 'Closed Won', CloseDate = hoy,
        Amount = 38500, CampaignId = ids.get('Boleto al evento (prueba)')),
    new Opportunity(Name = 'Pago de prueba 2', StageName = 'Closed Won', CloseDate = hoy,
        Amount = 9200, CampaignId = ids.get('Viaje a Ciudad de México (prueba)')),
    new Opportunity(Name = 'Pago de prueba 3', StageName = 'Closed Won', CloseDate = hoy.addDays(-95),
        Amount = 41800, CampaignId = ids.get('Campaña 2025 (prueba)')),
    // Una promesa sin pagar: NO debe sumar al avance.
    new Opportunity(Name = 'Promesa de prueba', StageName = 'Prospecting', CloseDate = hoy.addDays(30),
        Amount = 5000, CampaignId = ids.get('Boleto al evento (prueba)'))
};
insert pagos;

System.debug('Campañas de prueba creadas: ' + ids);
