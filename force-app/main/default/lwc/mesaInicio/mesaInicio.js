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
    @api titulo = 'México Dreaming';
    @api descripcion =
        'Con el espíritu de Ohana, invitamos a quienes cursaron la materia de Salesforce a devolver un poco de lo que recibieron.';
    @api textoBotonDonar = 'Quiero donar';
    @api textoBotonMuro = 'Ver quién ya se sumó';
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
