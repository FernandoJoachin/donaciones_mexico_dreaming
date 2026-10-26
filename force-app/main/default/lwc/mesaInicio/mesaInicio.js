import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { resolverUrl, irA } from 'c/mesaUtil';

/**
 * Página de inicio: presentación breve y puertas de entrada.
 *  - Con ?token= en la URL: el botón principal lleva directo a donar.
 *  - Sin token: lleva al registro (la persona aún no tiene cuenta).
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
    @api paginaDonar = 'donar';
    @api paginaRegistro = 'registro';
    @api paginaMuro = 'muro';

    token;

    @wire(CurrentPageReference)
    resolverPagina(ref) {
        if (ref) {
            this.token = ref.state && ref.state.token ? ref.state.token : undefined;
        }
    }

    /** Pasos de la sección "Cómo sumarte". Solo describen lo que el sistema hace hoy. */
    get pasos() {
        return [
            {
                numero: '1',
                titulo: 'Reencuéntrate',
                texto: 'Actualiza tus datos y cuéntanos cómo estás.'
            },
            {
                numero: '2',
                titulo: 'Elige tu aportación',
                texto: 'Escoge un paquete u otro monto. Tú decides si tu donativo es público o privado.'
            },
            {
                numero: '3',
                titulo: 'Recibe tu reconocimiento',
                texto: 'Si lo autorizas, tu nombre aparece en el muro de agradecimiento.'
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
        return this.token
            ? 'Tu enlace personal está activo: te llevamos directo a donar.'
            : '¿Ya tienes tu enlace personal? Ábrelo desde el correo que te enviamos. Si aún no tienes cuenta, te registramos en un minuto.';
    }

    donar() {
        const url = this.token
            ? resolverUrl(this.paginaDonar, this.token, true)
            : resolverUrl(this.paginaRegistro, null, true);
        irA(url);
    }

    verMuro() {
        irA(resolverUrl(this.paginaMuro, null, true));
    }
}
