// Elimina únicamente los registros creados por datos-prueba-muro.apex.
// Ejecutar: sf apex run --file scripts/apex/limpiar-datos-prueba-muro.apex --target-org mesa-dev

List<Campaign> campanas = [
    SELECT Id FROM Campaign WHERE Name = 'México Dreaming' AND IsActive = true LIMIT 1
];
if (campanas.isEmpty()) {
    throw new IllegalArgumentException('No existe una campaña activa llamada México Dreaming.');
}
Id campaignId = campanas[0].Id;

List<Opportunity> oportunidades = [
    SELECT Id, Contacto_Donador__c
    FROM Opportunity
    WHERE CampaignId = :campaignId AND Name LIKE 'DEMO MURO |%'
];
Set<Id> opportunityIds = new Map<Id, Opportunity>(oportunidades).keySet();

if (!opportunityIds.isEmpty()) {
    List<Reconocimiento_Publico__c> reconocimientos = [
        SELECT Id FROM Reconocimiento_Publico__c
        WHERE Campana__c = :campaignId AND Donativo__c IN :opportunityIds
    ];
    if (!reconocimientos.isEmpty()) {
        delete reconocimientos;
    }
    delete oportunidades;
}

Set<Id> contactosDemo = new Set<Id>();
for (Opportunity oportunidad : oportunidades) {
    if (oportunidad.Contacto_Donador__c != null) {
        contactosDemo.add(oportunidad.Contacto_Donador__c);
    }
}
if (!contactosDemo.isEmpty()) {
    Set<Id> contactosConOtrosDonativos = new Set<Id>();
    for (Opportunity otraOportunidad : [
        SELECT Contacto_Donador__c FROM Opportunity
        WHERE Contacto_Donador__c IN :contactosDemo
    ]) {
        contactosConOtrosDonativos.add(otraOportunidad.Contacto_Donador__c);
    }
    List<Contact> contactosEliminar = [
        SELECT Id FROM Contact
        WHERE Id IN :contactosDemo
            AND Email LIKE 'muro.demo.%@example.com'
            AND Id NOT IN :contactosConOtrosDonativos
    ];
    if (!contactosEliminar.isEmpty()) {
        delete contactosEliminar;
    }
}

System.debug(LoggingLevel.ERROR, 'Oportunidades demo eliminadas: ' + oportunidades.size());
System.debug(LoggingLevel.ERROR, 'Contactos demo sin otras referencias eliminados: ' + contactosDemo.size());
