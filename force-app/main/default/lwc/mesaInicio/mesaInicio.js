import { LightningElement, api } from 'lwc';

/**
 * Landing del inicio: portada, cómo sumarte y datos informativos. La lista de campañas
 * (mesaCampanas, con "ocultar banda") va justo debajo; "Quiero donar" baja hasta ella.
 * Los textos se editan en Experience Builder, sin tocar código.
 */
export default class MesaInicio extends LightningElement {
    @api etiqueta = '';
    /**
     * Qué parte se muestra: «arriba» (portada), «abajo» (pasos, información y cierre) o «todo».
     * Así la lista de campañas puede ir entre las dos: lo que la gente busca va primero.
     */
    @api parte = 'todo';

    get preguntas() {
        return [
            { id: 'p1', pregunta: '¿Es seguro pagar aquí?', respuesta: 'El pago se hace en la página de Stripe. Tu tarjeta solo la ve Stripe; este sitio nunca la recibe ni la guarda.' },
            { id: 'p2', pregunta: '¿Necesito una cuenta?', respuesta: 'No. Solo eliges un monto y llenas tus datos para el comprobante.' },
            { id: 'p3', pregunta: '¿Puedo donar de forma anónima?', respuesta: 'Sí. En el muro aparecerá «Anónimo» con el monto, sin tu nombre. Tu correo se usa solo para enviarte el comprobante.' },
            { id: 'p4', pregunta: '¿Cómo pido mi factura?', respuesta: 'Tu comprobante llega por correo e incluye los pasos. También los encuentras en la página Facturas del menú.' },
            { id: 'p5', pregunta: '¿Qué pasa si el pago falla o lo cancelo?', respuesta: 'Tu donativo queda pendiente y no se suma al avance de la campaña. Puedes intentarlo de nuevo; si tienes dudas, usa «Ayuda» con tu referencia.' },
            { id: 'p6', pregunta: '¿Para qué se usa el dinero?', respuesta: 'Cada campaña explica su destino y su meta en su propia página. Entra a la que te interese antes de donar.' }
        ];
    }

    get verArriba() {
        return this.parte !== 'abajo';
    }

    get verAbajo() {
        return this.parte !== 'arriba';
    }
    @api titulo = 'Apoya a la comunidad';
    @api descripcion =
        'Con el espíritu de Ohana, invitamos a quienes cursaron la materia de Salesforce a devolver un poco de lo que recibieron.';
    @api textoBotonDonar = 'Quiero donar';
    /**
     * Obsoletas desde SCRUM-135: cada campaña tiene su propio muro y el enlace vive en su página.
     * Se conservan porque Salesforce no deja quitar propiedades que el sitio publicado tiene guardadas. No se leen.
     */
    @api textoBotonMuro;
    @api paginaMuro;
    @api tituloFinal = 'Gracias por ser parte de Ohana';
    @api textoFinal =
        'Cada aportación ayuda a que más personas vivan la experiencia. Elige una campaña y súmate.';
    @api mostrarCierre = false;
    @api tituloSobre = 'Sobre la campaña';
    @api subSobre = 'Lo que conviene saber antes de donar.';
    @api infoTitulo1 = 'Quién organiza';
    @api infoTexto1 = 'La comunidad Salesforce de la Facultad de Matemáticas, con el espíritu de Ohana.';
    @api infoTitulo2 = 'Cada campaña, su meta';
    @api infoTexto2 = 'Cada campaña tiene su propia meta y su avance. Entra a la que más te llegue para ver los detalles.';
    @api infoTitulo3 = 'Transparencia';
    @api infoTexto3 = 'Cada campaña muestra cuánto lleva y quiénes ya se sumaron en su muro de agradecimiento.';

    get pasos() {
        return [
            { numero: '1', titulo: 'Elige una causa', texto: 'Lee la historia de cada campaña y escoge la que más te llegue.' },
            { numero: '2', titulo: 'Decide tu aportación', texto: 'Cada campaña te dice qué logra cada monto. Tú decides si tu nombre se muestra.' },
            { numero: '3', titulo: 'Súmate al muro', texto: 'Cuando tu aportación se confirma, aparece en el muro de agradecimiento de la campaña.' }
        ];
    }

    get infos() {
        return [
            { id: 'i1', titulo: this.infoTitulo1, texto: this.infoTexto1 },
            { id: 'i2', titulo: this.infoTitulo2, texto: this.infoTexto2 },
            { id: 'i3', titulo: this.infoTitulo3, texto: this.infoTexto3 }
        ];
    }

    get ayuda() {
        return 'Cada aportación, grande o pequeña, acerca a una campaña a su meta.';
    }

    /** Las campañas van justo debajo de este componente: baja suavemente hasta ellas. */
    irACampanas() {
        const fin = this.template.host.getBoundingClientRect().bottom + window.scrollY;
        window.scrollTo({ top: Math.max(fin - 24, 0), behavior: 'smooth' });
    }
}
