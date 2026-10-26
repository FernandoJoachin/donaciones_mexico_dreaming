// Borra los donativos y reconocimientos de UN contacto de prueba, para repetir la simulación.
// NO borra el contacto ni su lugar en la campaña.
//
// Antes de ejecutar, cambia el valor de 'apellido' por el apellido de tu contacto de prueba.
//
// Ejecutar:  sf apex run --file scripts/apex/limpiar-pruebas.apex --target-org mesa-dev

String apellido = 'CAMBIAR_ESTE_VALOR';

if (apellido == 'CAMBIAR_ESTE_VALOR') {
    System.debug('Edita el apellido antes de ejecutar. No se borró nada.');
} else {
    List<Opportunity> donativos = [
        SELECT Id FROM Opportunity WHERE Contacto_Donador__r.LastName = :apellido
    ];
    List<Reconocimiento_Publico__c> reconocimientos = [
        SELECT Id FROM Reconocimiento_Publico__c WHERE Donativo__c IN :donativos
    ];
    Integer nRec = reconocimientos.size();
    Integer nDon = donativos.size();
    delete reconocimientos;
    delete donativos;

    // Regresa al miembro al inicio del embudo para poder repetir el recorrido.
    // Si el estado 'Identificado' no existe en la campaña, no se cambia nada.
    List<CampaignMember> miembros = [SELECT Id FROM CampaignMember WHERE Contact.LastName = :apellido];
    for (CampaignMember cm : miembros) {
        cm.Status = 'Identificado';
    }
    Database.update(miembros, false);

    System.debug('Reconocimientos borrados: ' + nRec + ' | Donativos borrados: ' + nDon);
}
