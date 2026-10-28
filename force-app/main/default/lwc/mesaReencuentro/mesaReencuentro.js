import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import obtenerInvitacion from '@salesforce/apex/MesaRegalosController.obtenerInvitacion';
import guardarReencuentro from '@salesforce/apex/MesaRegalosController.guardarReencuentro';
import { resolverUrl, irA } from 'c/mesaUtil';

export default class MesaReencuentro extends LightningElement {
    /** Nombre de la página de donación del sitio (la que lleva el componente Mesa - Donación). */
    @api paginaDonar = 'donar';
    /** Dirección de tu aviso de privacidad (se configura en Experience Builder). */
    @api avisoUrl;
    /** Versión del aviso que ve la persona; se guarda junto con su consentimiento. */
    @api versionAviso = 'v1';

    token;
    invitacion;
    cargando = true;
    enviado = false;
    error;

    generacion = '';
    cuentaTrailhead = '';
    certificaciones = '';
    consentimientoContacto = false;
    darseDeBaja = false;

    @wire(CurrentPageReference)
    resolverPagina(ref) {
        if (!ref) {
            return;
        }
        const token = ref.state && ref.state.token;
        if (!token) {
            this.cargando = false;
            this.error = 'Este enlace no es válido. Usa el enlace personal que te enviamos.';
            return;
        }
        if (token !== this.token) {
            this.token = token;
            this.cargar();
        }
    }

    async cargar() {
        this.cargando = true;
        this.error = undefined;
        try {
            const inv = await obtenerInvitacion({ token: this.token });
            this.invitacion = inv;
            this.generacion = inv.generacion || '';
            this.cuentaTrailhead = inv.cuentaTrailhead || '';
            this.certificaciones = inv.certificaciones || '';
            this.consentimientoContacto = inv.consentimientoContacto === true;
        } catch (e) {
            this.error = this.mensaje(e);
        } finally {
            this.cargando = false;
        }
    }

    get mostrarFormulario() {
        return this.invitacion && !this.enviado;
    }
    
    get avisoHref(){
        return this.avisoUrl ? resolverUrl(this.avisoUrl) : undefined;
    }

    cambio(evento) {
        const campo = evento.target.dataset.campo;
        const esCheckbox = evento.target.type === 'checkbox';
        this[campo] = esCheckbox ? evento.target.checked : evento.target.value;
    }

    async guardar() {
        this.cargando = true;
        this.error = undefined;
        try {
            await guardarReencuentro({
                token: this.token,
                datosJson: JSON.stringify({
                    generacion: this.generacion,
                    cuentaTrailhead: this.cuentaTrailhead,
                    certificaciones: this.certificaciones,
                    consentimientoContacto: this.consentimientoContacto,
                    darseDeBaja: this.darseDeBaja,
                    versionAviso: this.versionAviso
                })
            });
            this.enviado = true;
        } catch (e) {
            this.error = this.mensaje(e);
        } finally {
            this.cargando = false;
        }
    }

    continuarADonar() {
        irA(resolverUrl(this.paginaDonar, this.token, false));
    }

    mensaje(e) {
        return (e && e.body && e.body.message) || 'Ocurrió un error. Intenta de nuevo en unos minutos.';
    }
}
