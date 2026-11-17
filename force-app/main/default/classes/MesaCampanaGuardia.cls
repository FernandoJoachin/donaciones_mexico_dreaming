/**
 * Regla: una campaña con donativos pagados no se elimina, salvo que el usuario tenga el permiso
 * personalizado Eliminar_Campanas_Con_Donaciones (se asigna con "Mesa de regalos - Administración").
 *
 * Un donativo pagado se detecta por su Reconocimiento_Publico__c, que se crea al confirmar el pago.
 * Va sin "with sharing" a propósito: la consulta debe ver todos los reconocimientos aunque el usuario
 * (por ejemplo, un gestor) no pueda verlos, o la regla se podría esquivar.
 */
public without sharing class MesaCampanaGuardia {

    public static final String PERMISO_ELIMINAR = 'Eliminar_Campanas_Con_Donaciones';

    /** Solo para pruebas: fuerza el resultado del permiso sin crear permission sets. */
    @TestVisible private static Boolean permisoForzado;

    public static void validarEliminacion(List<Campaign> campanas) {
        if (campanas == null || campanas.isEmpty() || tienePermiso()) {
            return;
        }
        Map<Id, Integer> donativosPorCampana = new Map<Id, Integer>();
        for (AggregateResult ar : [
            SELECT Campana__c camp, COUNT(Id) total
            FROM Reconocimiento_Publico__c
            WHERE Campana__c IN :campanas
            GROUP BY Campana__c
        ]) {
            donativosPorCampana.put((Id) ar.get('camp'), (Integer) ar.get('total'));
        }
        for (Campaign c : campanas) {
            Integer total = donativosPorCampana.get(c.Id);
            if (total != null) {
                c.addError(
                    'No se puede eliminar la campaña: ya tiene ' + total + ' donativo(s) pagado(s). '
                    + 'Si necesitas eliminarla, pide ayuda a administración; '
                    + 'también puedes desactivarla con la casilla Active.'
                );
            }
        }
    }

    private static Boolean tienePermiso() {
        if (permisoForzado != null) {
            return permisoForzado;
        }
        return FeatureManagement.checkPermission(PERMISO_ELIMINAR);
    }
}
