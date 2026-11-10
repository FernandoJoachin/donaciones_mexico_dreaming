// Crea la campaña "México Dreaming" con los estados del embudo.
// Ejecutar (desde la raíz del proyecto) 1 de estos comandos:
//   sf apex run --file scripts/apex/crear-campana.apex
//   sf apex run --file scripts/apex/crear-campana.apex --target-org mesa-nueva
//
// Nota: no se define aquí la meta. Captúrala en el campo "Ingreso esperado" de la campaña
// cuando se confirme el monto objetivo (es lo que usa el avance del sitio).

Campaign c = new Campaign(Name = 'México Dreamin', IsActive = true, Status = 'Planned');
insert c;

// Identificado y Contactado se marcan a mano en las campañas de correo.
// Registrado, Redirigido a donar y Donó los avanza el sitio.
List<String> estados = new List<String>{
    'Identificado', 'Contactado', 'Registrado', 'Redirigido a donar', 'Donó'
};

List<CampaignMemberStatus> filas = new List<CampaignMemberStatus>();
Integer orden = 10;
for (String e : estados) {
    filas.add(new CampaignMemberStatus(
        CampaignId = c.Id,
        Label = e,
        SortOrder = orden++,
        HasResponded = (e != 'Identificado' && e != 'Contactado')
    ));
}
insert filas;

System.debug('Campaña creada: ' + c.Id);
System.debug('Al cargar la lista de ex-alumnos como miembros, asigna Status = Identificado.');
