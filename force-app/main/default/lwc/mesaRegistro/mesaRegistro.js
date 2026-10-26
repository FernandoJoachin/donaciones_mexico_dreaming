import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import guardarRegistro from '@salesforce/apex/MesaRegalosController.guardarRegistro';
import { mensajeError, resolverUrl, irA } from 'c/mesaUtil';

/**
 * Registro de donadores nuevos.
 *  - Sin ?token= en la URL: la persona se registra a sí misma y continúa a donar.
 *  - Con ?token= (de un ex-alumno): el ex-alumno invita a otra persona o empresa.
 */
export default class MesaRegistro extends LightningElement {
    /** Id de la campaña (se configura en Experience Builder). */
    @api campaignId;
    @api avisoUrl;
    @api versionAviso = 'v1';
    /** Nombre de la página de donación del sitio. */
    @api paginaDonar = 'donar';

    tokenInvitador;

    nombre = '';
    apellidos = '';
    correo = '';
    esEmpresa = false;
    empresa = '';
    aceptaAviso = false;
    sitioWeb = '';

    enviando = false;
    registrado = false;
    error;
    aviso;
    mensajeExito;
    tokenNuevo;

    @wire(CurrentPageReference)
    resolverPagina(ref) {
        if (ref) {
            this.tokenInvitador = ref.state && ref.state.token ? ref.state.token : undefined;
        }
    }

    get esInvitacion() {
        return !!this.tokenInvitador;
    }

    get titulo() {
        return this.esInvitacion ? 'Invitar a una persona o empresa' : 'Regístrate para donar';
    }

    get intro() {
        return this.esInvitacion
            ? 'Comparte los datos de la persona que quieres invitar. El equipo le hará llegar su enlace personal.'
            : 'Déjanos tus datos y continúa a donar. Si ya participaste en la materia, usa mejor el enlace personal que te enviamos.';
    }

    get etiquetaAviso() {
        return this.esInvitacion
            ? 'Confirmo que esta persona sabe que compartiré sus datos para invitarla, y acepto el aviso de privacidad'
            : 'He leído y acepto el aviso de privacidad';
    }

    get etiquetaEmpresa() {
        return this.esInvitacion ? 'Es una empresa' : 'Dono en representación de una empresa';
    }

    get mostrarFormulario() {
        return !this.registrado;
    }

    get esAutorregistro() {
        return !!this.tokenNuevo;
    }

    cambio(evento) {
        const campo = evento.target.dataset.campo;
        if (evento.target.type === 'checkbox') {
            this[campo] = evento.target.checked;
        } else {
            this[campo] = evento.detail && evento.detail.value !== undefined ? evento.detail.value : evento.target.value;
        }
    }

    async enviar() {
        this.enviando = true;
        this.error = undefined;
        this.aviso = undefined;
        try {
            const r = await guardarRegistro({
                campaignId: this.campaignId || null,
                tokenInvitador: this.tokenInvitador || null,
                datosJson: JSON.stringify({
                    nombre: this.nombre,
                    apellidos: this.apellidos,
                    correo: this.correo,
                    esEmpresa: this.esEmpresa,
                    empresa: this.esEmpresa ? this.empresa : null,
                    aceptaAviso: this.aceptaAviso,
                    versionAviso: this.versionAviso,
                    sitioWeb: this.sitioWeb
                })
            });

            if (r.exito) {
                this.registrado = true;
                this.mensajeExito = r.mensaje;
                this.tokenNuevo = r.token;
            } else {
                this.aviso = r.mensaje;
            }
        } catch (e) {
            this.error = mensajeError(e);
        } finally {
            this.enviando = false;
        }
    }

    continuarADonar() {
        irA(resolverUrl(this.paginaDonar, this.tokenNuevo, false));
    }

    invitarOtra() {
        this.nombre = '';
        this.apellidos = '';
        this.correo = '';
        this.esEmpresa = false;
        this.empresa = '';
        this.aceptaAviso = false;
        this.registrado = false;
        this.mensajeExito = undefined;
    }
}
