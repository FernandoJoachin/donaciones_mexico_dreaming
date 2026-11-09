import { LightningElement, api } from 'lwc';
import guardarDonativo from '@salesforce/apex/MesaRegalosController.guardarDonativo';
import { parseMonto, formatearMonto, mensajeError, resolverUrl } from 'c/mesaUtil';

// Deben coincidir con MesaRegalosController (el servidor es quien manda).
const MONTO_MINIMO = 100;
const PAQUETES = { P1000: 1000, P3000: 3000, P5000: 5000 };
const LINKEDIN = /^https:\/\/([a-z]{2,3}\.)?linkedin\.com\/(in|company)\/\S+$/i;
const CORREO = /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/;

/**
 * Registro y donación en un solo formulario, sin token: la persona se identifica con su correo.
 * Anónima oculta nombre, empresa y LinkedIn (el servidor igual los ignora).
 */
export default class MesaRegistro extends LightningElement {
    /** Id de la campaña (se configura en Experience Builder). */
    @api campaignId;
    @api avisoUrl;
    @api versionAviso = 'v1';
    /**
     * Opcional. Enlace de pago (Payment Link de Stripe). Si se llena, al registrar el donativo
     * se redirige ahí con el Id del donativo (client_reference_id) y el correo pre-rellenado.
     */
    @api urlPago;

    paquete = '';
    montoTexto = '';
    visibilidad = '';
    esEmpresa = false;
    nombreEmpresa = '';
    nombre = '';
    apellidos = '';
    linkedinUrl = '';
    correo = '';
    consentimientoAvisos = '';
    consentimientoPublicacion = false;
    aceptaAviso = false;
    sitioWeb = '';

    enviando = false;
    registrado = false;
    error;

    opcionesPaquete = [
        { label: 'Paquete $1,000', value: 'P1000' },
        { label: 'Paquete $3,000', value: 'P3000' },
        { label: 'Paquete $5,000', value: 'P5000' },
        { label: 'Otro monto', value: 'Abierto' }
    ];

    opcionesVisibilidad = [
        { label: 'Pública: mi nombre (o el de mi empresa) y el monto', value: 'Publica' },
        { label: 'Anónima: «Anónimo» y el monto', value: 'Anonima' }
    ];

    opcionesConsentimiento = [
        { label: 'Sí, avísenme', value: 'Si' },
        { label: 'No, gracias', value: 'No' }
    ];

    get mostrarFormulario() {
        return !this.registrado;
    }

    get esPublico() {
        return this.visibilidad === 'Publica';
    }

    get esAnonimo() {
        return this.visibilidad === 'Anonima';
    }

    get esAbierto() {
        return this.paquete === 'Abierto';
    }

    get montoFinal() {
        if (PAQUETES[this.paquete]) {
            return PAQUETES[this.paquete];
        }
        return this.esAbierto ? parseMonto(this.montoTexto) : null;
    }

    get montoValido() {
        const monto = this.montoFinal;
        return monto !== null && monto > 0 && (!this.esAbierto || monto >= MONTO_MINIMO);
    }

    get etiquetaBoton() {
        return this.montoValido ? `Donarás: ${formatearMonto(this.montoFinal)} MXN` : 'Elige un monto';
    }

    get botonDeshabilitado() {
        return this.enviando || !this.montoValido;
    }

    get ayudaMonto() {
        return `Monto mínimo: ${formatearMonto(MONTO_MINIMO)} MXN`;
    }

    get avisoHref() {
        return this.avisoUrl ? resolverUrl(this.avisoUrl) : undefined;
    }

    cambio(evento) {
        const campo = evento.target.dataset.campo;
        if (evento.target.type === 'checkbox') {
            this[campo] = evento.target.checked;
        } else {
            this[campo] = evento.detail && evento.detail.value !== undefined ? evento.detail.value : evento.target.value;
        }
    }

    /** Revisión rápida para no hacer viajes al servidor. El servidor vuelve a validar todo. */
    validar() {
        if (!this.montoValido) {
            return this.esAbierto
                ? `Escribe un monto de ${formatearMonto(MONTO_MINIMO)} o más.`
                : 'Elige un paquete o la opción de otro monto.';
        }
        if (!this.visibilidad) {
            return 'Elige si tu donativo será público o anónimo.';
        }
        if (this.esPublico) {
            if (this.esEmpresa) {
                if (!this.nombreEmpresa.trim()) {
                    return 'Escribe el nombre de la empresa.';
                }
            } else if (!this.nombre.trim() || !this.apellidos.trim()) {
                return 'Escribe tu nombre y apellidos.';
            }
            if (this.linkedinUrl.trim() && !LINKEDIN.test(this.linkedinUrl.trim())) {
                return 'La dirección de LinkedIn no es válida (https://www.linkedin.com/in/... o /company/...).';
            }
        }
        if (!CORREO.test(this.correo.trim())) {
            return 'Escribe un correo válido.';
        }
        if (!this.consentimientoAvisos) {
            return 'Indica si quieres recibir avisos de próximos eventos y donaciones.';
        }
        if (!this.consentimientoPublicacion) {
            return 'Para continuar necesitamos tu autorización para publicar tu donativo.';
        }
        if (!this.aceptaAviso) {
            return 'Para continuar debes aceptar el aviso de privacidad.';
        }
        return undefined;
    }

    async enviar() {
        this.error = this.validar();
        if (this.error) {
            return;
        }
        const comoEmpresa = this.esPublico && this.esEmpresa;
        this.enviando = true;
        try {
            const r = await guardarDonativo({
                campaignId: this.campaignId || null,
                datosJson: JSON.stringify({
                    paquete: this.paquete,
                    monto: this.esAbierto ? this.montoFinal : null,
                    visibilidad: this.visibilidad,
                    nombre: this.esPublico && !comoEmpresa ? this.nombre : null,
                    apellidos: this.esPublico && !comoEmpresa ? this.apellidos : null,
                    correo: this.correo,
                    esEmpresa: comoEmpresa,
                    nombreEmpresa: comoEmpresa ? this.nombreEmpresa : null,
                    linkedinUrl: this.esPublico ? this.linkedinUrl : null,
                    consentimientoAvisos: this.consentimientoAvisos,
                    consentimientoPublicacion: this.consentimientoPublicacion,
                    aceptaAviso: this.aceptaAviso,
                    versionAviso: this.versionAviso,
                    sitioWeb: this.sitioWeb
                })
            });
            this.registrado = true;
            if (r && r.donativoId && this.urlPago) {
                const separador = this.urlPago.includes('?') ? '&' : '?';
                window.location.href =
                    `${this.urlPago}${separador}client_reference_id=${encodeURIComponent(r.donativoId)}` +
                    `&prefilled_email=${encodeURIComponent(this.correo.trim())}`;
            }
        } catch (e) {
            this.error = mensajeError(e);
        } finally {
            this.enviando = false;
        }
    }
}