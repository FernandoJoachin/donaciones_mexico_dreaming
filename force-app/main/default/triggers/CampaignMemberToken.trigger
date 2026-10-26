/** Asigna a cada miembro de campaña un token aleatorio para su enlace personalizado. */
trigger CampaignMemberToken on CampaignMember (before insert) {
    for (CampaignMember cm : Trigger.new) {
        if (String.isBlank(cm.Token_Acceso__c)) {
            cm.Token_Acceso__c = MesaRegalosService.nuevoToken();
        }
    }
}
