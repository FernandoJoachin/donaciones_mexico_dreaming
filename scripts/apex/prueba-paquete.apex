// MesaRegalosController.DonativoInput d = new MesaRegalosController.DonativoInput();
// d.paquete = 'P3000';
// d.visibilidad = 'Privada';
// d.aceptaAviso = true;
// d.versionAviso = 'v1';
// Id oppId = MesaRegalosController.registrarPromesa('302a0f69b37f910fc30bf3034e18be3404191e7079087db2cb99be4e73812665', d);
// System.debug('Promesa creada: ' + oppId);

MesaRegalosController.DonativoInput d = new MesaRegalosController.DonativoInput();
d.paquete = 'P5000';
d.visibilidad = 'Publica';
d.linkedinUrl = 'https://www.linkedin.com/in/prueba';
d.consentimientoPublicacion = true;
d.mostrarMonto = true;
d.aceptaAviso = true;
d.versionAviso = 'v1';
Id oppId = MesaRegalosController.registrarPromesa('302a0f69b37f910fc30bf3034e18be3404191e7079087db2cb99be4e73812665', d);
System.debug('Promesa creada: ' + oppId);

// MesaRegalosService.confirmarPago(new List<Id>{ oppId });
// System.debug('Pago confirmado');