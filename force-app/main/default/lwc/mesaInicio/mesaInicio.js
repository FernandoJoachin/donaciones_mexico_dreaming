import { LightningElement, api } from 'lwc';
import { resolverUrl, irA } from 'c/mesaUtil';

/**
 * Página de inicio: presentación breve y puertas de entrada.
 * Sin token: todas las personas llegan al mismo formulario de registro y donación.
 * Los textos se editan en Experience Builder, sin tocar código.
 */
export default class MesaInicio extends LightningElement {
    @api etiqueta = 'Campaña de ex-alumnos';
    @api titulo = 'México Dreaming';
    @api descripcion =
        'Con el espíritu de Ohana, invitamos a quienes cursaron la materia de Salesforce a devolver un poco de lo que recibieron.';
    @api textoBotonDonar = 'Quiero donar';
    @api textoBotonMuro = 'Ver quién ya se sumó';
    @api tituloFinal = 'Gracias por ser parte de Ohana';
    @api textoFinal =
        'Cada aportación ayuda a que más personas vivan la experiencia. Conoce a quienes ya se sumaron.';
    /** Nombres de página (como aparecen en la URL) o rutas completas que empiecen con "/". */
    @api paginaRegistro = 'registro';
    @api paginaMuro = 'muro';

    /** Pasos de la sección "Cómo sumarte". Solo describen lo que el sistema hace hoy. */
    get pasos() {
        return [
            {
                numero: '1',
                titulo: 'Elige tu aportación',
                texto: 'Escoge un paquete u otro monto desde $100.'
            },
            {
                numero: '2',
                titulo: 'Decide cómo aparecer',
                texto: 'Con tu nombre (o el de tu empresa) o como Anónimo. El monto se muestra en ambos casos.'
            },
            {
                numero: '3',
                titulo: 'Completa tu pago',
                texto: 'Te llevamos al pago seguro y tu donativo aparece en el muro cuando se confirme.'
            }
        ];
    }

    /**
     * Montos que se muestran como referencia. Los precios reales de los paquetes los fija
     * el servidor (MesaRegalosController); si cambian allá, cámbialos también aquí.
     ** TODO: **
     * Ventana de mejora, centralizar esta información ya se replicó en varios lugares, quizá:
     * get montos() {
     *        return [
     *            { id: 'P1000', nombre: 'Paquete', monto: ',000' }, ...
     */
    get opciones() {
        return [
            { id: 'P1000', nombre: 'Paquete', monto: '$1,000' },
            { id: 'P3000', nombre: 'Paquete', monto: '$3,000' },
            { id: 'P5000', nombre: 'Paquete', monto: '$5,000' },
            { id: 'otro', nombre: 'Otro monto desde $100', monto: 'Tú eliges' }
        ];
    }

    get ayuda() {
        return 'Tarda un minuto: eliges tu aportación, nos dejas tus datos y pasas al pago.';
    }

    donar() {
        irA(resolverUrl(this.paginaRegistro, null, true));
    }

    verMuro() {
        irA(resolverUrl(this.paginaMuro, null, true));
    }
}