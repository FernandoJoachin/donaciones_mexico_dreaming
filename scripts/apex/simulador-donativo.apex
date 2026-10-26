// TOKEN: Este se crea individualmente para cada contacto y campaña. Se puede obtener de la tabla CampaignMember.
String t = [
    SELECT Token_Acceso__c FROM CampaignMember
    WHERE Campaign.Name = 'México Dreaming' AND Contact.LastName = 'Test1'
    LIMIT 1
].Token_Acceso__c;

// Payload de prueba para registrar un donativo. Se puede modificar para probar distintos escenarios.
MesaRegalosController.DonativoInput d = new MesaRegalosController.DonativoInput();
d.paquete = 'P5000';
d.visibilidad = 'Publica';
d.linkedinUrl = 'https://www.linkedin.com/in/prueba';
d.consentimientoPublicacion = true;
d.mostrarMonto = true;
d.aceptaAviso = true;
d.versionAviso = 'v1';

// Registrar promesa de donativo con el token y el payload de prueba. Devuelve el Id de la oportunidad creada.
// Id oppId = MesaRegalosController.registrarPromesa('302a0f69b37f910fc30bf3034e18be3404191e7079087db2cb99be4e73812665', d);
Id oppId = MesaRegalosController.registrarPromesa(t, d);
System.debug('Promesa creada: ' + oppId);

// Confirmar el pago de la oportunidad creada. Devuelve true si se confirma correctamente.
// Por el momento no se ha implementado de manera automatica con stripe, por lo que se debe ejecutar manualmente para probar el flujo completo.
// Para que los demás flujos funcionen correctamente, se debe ejecutar este paso de confirmación de pago.
MesaRegalosService.confirmarPago(new List<Id>{ oppId });
// MesaRegalosService.confirmarPago(new List<Id>{ '006fj00000OcuMjAAJ' });
System.debug('Pago confirmado');