import { LightningElement, api } from 'lwc';
import { resolverUrl, irA } from 'c/mesaUtil';

/**
 * Landing del inicio: portada, cómo sumarte y datos informativos. La lista de campañas
 * (mesaCampanas, con "ocultar banda") va justo debajo; "Quiero donar" baja hasta ella.
 * Los textos se editan en Experience Builder, sin tocar código.
 */
export default class MesaInicio extends LightningElement {
    @api etiqueta = '';
    @api titulo = 'Apoya a la comunidad';
    @api descripcion =
        'Con el espíritu de Ohana, invitamos a quienes cursaron la materia de Salesforce a devolver un poco de lo que recibieron.';
    @api textoBotonDonar = 'Quiero donar';
    @api textoBotonMuro = 'Ver quién ya se sumó';
    @api tituloFinal = 'Gracias por ser parte de Ohana';
    @api textoFinal =
        'Cada aportación ayuda a que más personas vivan la experiencia. Conoce a quienes ya se sumaron.';
    /** Nombre de la página del muro (como aparece en la URL) o ruta completa que empiece con "/". */
    @api paginaMuro = 'muro';
    @api mostrarCierre = false;
    @api tituloSobre = 'Sobre la campaña';
    @api subSobre = 'Lo que conviene saber antes de donar.';
    @api infoTitulo1 = 'Quién organiza';
    @api infoTexto1 = 'Ex-alumnos de la Facultad de Matemáticas que cursaron Salesforce, con el espíritu de Ohana.';
    @api infoTitulo2 = 'Cada campaña, su meta';
    @api infoTexto2 = 'Cada campaña tiene su propia meta y su avance. Entra a la que más te llegue para ver los detalles.';
    @api infoTitulo3 = 'Transparencia';
    @api infoTexto3 = 'Puedes ver cuánto lleva cada campaña y quiénes ya se sumaron en el muro de agradecimiento.';

    get pasos() {
        return [
            { numero: '1', titulo: 'Elige una campaña', texto: 'Conoce las campañas activas y escoge la que más te llegue.' },
            { numero: '2', titulo: 'Indica tu aportación', texto: 'Dinos tu nombre y correo, y el monto que quieras donar. Tú decides si tu nombre se muestra.' },
            { numero: '3', titulo: 'Completa tu pago', texto: 'Te llevamos al pago seguro y recibes la confirmación por correo.' }
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
        return 'Elige una campaña, indica tu aportación y pasas al pago. Tarda un minuto.';
    }

    /** Las campañas van justo debajo de este componente: baja suavemente hasta ellas. */
    irACampanas() {
        const fin = this.template.host.getBoundingClientRect().bottom + window.scrollY;
        window.scrollTo({ top: Math.max(fin - 24, 0), behavior: 'smooth' });
    }

    verMuro() {
        irA(resolverUrl(this.paginaMuro, null, true));
    }
}
