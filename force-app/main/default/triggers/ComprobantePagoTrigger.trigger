/**
 * Atiende el aviso "donativo pagado" y manda el comprobante.
 * Los triggers de eventos de plataforma corren como el usuario Automated Process, no como el guest
 * del sitio, así que el envío de correo ya no depende de permisos del visitante anónimo.
 */
trigger ComprobantePagoTrigger on Comprobante_Pago__e (after insert) {
    List<Id> donativos = new List<Id>();
    for (Comprobante_Pago__e e : Trigger.new) {
        if (String.isNotBlank(e.Donativo_Id__c)) {
            donativos.add((Id) e.Donativo_Id__c);
        }
    }
    MesaComprobante.enviar(donativos);
}
