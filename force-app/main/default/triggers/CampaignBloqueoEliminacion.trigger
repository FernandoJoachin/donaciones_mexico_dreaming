/**
 * Impide eliminar campañas que ya recibieron donativos pagados (tienen reconocimientos públicos).
 * La excepción es quien tenga el permiso personalizado Eliminar_Campanas_Con_Donaciones.
 */
trigger CampaignBloqueoEliminacion on Campaign (before delete) {
    MesaCampanaGuardia.validarEliminacion(Trigger.old);
}
