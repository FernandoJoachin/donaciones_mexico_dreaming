// Asigna token a los miembros de campaña que ya existían antes de desplegar el trigger.
// Ejecutar:  sf apex run --file scripts/apex/tokens-faltantes.apex
List<CampaignMember> sinToken = [SELECT Id FROM CampaignMember WHERE Token_Acceso__c = null LIMIT 5000];
for (CampaignMember cm : sinToken) {
    cm.Token_Acceso__c = MesaRegalosService.nuevoToken();
}
update sinToken;
System.debug('Tokens asignados: ' + sinToken.size());
