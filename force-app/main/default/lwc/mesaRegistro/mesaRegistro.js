import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import guardarDonativo from '@salesforce/apex/MesaRegalosController.guardarDonativo';
import obtenerCampana from '@salesforce/apex/MesaRegalosController.obtenerCampana';
import iniciarPago from '@salesforce/apex/MesaRegalosController.iniciarPago';
import { parseMonto, formatearMonto, mensajeError, resolverUrl, irA, guardarRetornoPago, leerRetornoPago } from 'c/mesaUtil';

// Deben coincidir con MesaRegalosController (el servidor es quien manda).
const MONTO_MINIMO = 100;
const PAQUETES = { P1000: 1000, P3000: 3000, P5000: 5000 };
const LINKEDIN = /^https:\/\/([a-z]{2,3}\.)?linkedin\.com\/(in|company)\/\S+$/i;
const CORREO = /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/;
const ID_DONATIVO = /^[A-Za-z0-9]{15}([A-Za-z0-9]{3})?$/;

/** Último tramo de una ruta ("/donaciones/s/registro" -> "registro"): el servidor solo acepta nombres de página. */
const ultimoTramo = (ruta) => String(ruta || '').split('/').filter(Boolean).pop() || '';

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
     * Obsoletas desde US-05: el pago usa Stripe Checkout creado en el servidor. Se conservan solo porque
     * Salesforce no permite quitar propiedades que el sitio publicado tiene guardadas. No se leen.
     */
    @api urlPago;
    @api urlPagoP1000;
    @api urlPagoP3000;
    @api urlPagoP5000;
    /** Página del muro: Stripe regresa ahí al terminar de pagar y ahí se avisa el resultado. */
    @api paginaMuro = 'muro';

    /** Campaña que viene en la dirección (?campana=<Id>), por ejemplo desde el botón Donar de su página. */
    campanaUrl;

    @wire(CurrentPageReference)
    leerCampanaDeLaDireccion(ref) {
        this.campanaUrl = ref && ref.state && ref.state.campana ? ref.state.campana : undefined;
        this.aplicarMontoDeLaDireccion(ref && ref.state ? ref.state.monto : undefined);
        this.aplicarRegresoDelPago(ref && ref.state);
        this.cargarCampanaInfo();
    }

    /**
     * Stripe regresa aquí si la persona cancela (?pago=cancelado&donativo=<Id>). El donativo sigue
     * pendiente: se avisa y se ofrece pagar de nuevo el mismo donativo, sin crear otro (CA6, CA7).
     */
    regresoAplicado = false;

    aplicarRegresoDelPago(estado) {
        if (this.regresoAplicado || !estado || estado.pago !== 'cancelado' || !ID_DONATIVO.test(estado.donativo || '')) {
            return;
        }
        this.regresoAplicado = true;
        leerRetornoPago(); // ya no se viene de un pago: el muro no debe decir "Confirmando tu pago"
        this.donativoId = estado.donativo;
        this.pagoCancelado = true;
    }

    /** Datos públicos de la campaña para el encabezado (nombre y resumen). */
    campanaInfo;
    campanaCargada;

    connectedCallback() {
        this.cargarCampanaInfo();
    }

    cargarCampanaInfo() {
        const id = this.idCampana;
        if (!id || id === this.campanaCargada) {
            return;
        }
        this.campanaCargada = id;
        obtenerCampana({ campaignId: id })
            .then((d) => {
                if (id === this.idCampana) {
                    this.campanaInfo = d || undefined;
                }
            })
            .catch(() => {
                // El encabezado es secundario: si falla, se queda el título genérico.
                this.campanaInfo = undefined;
            });
    }

    get tituloBanda() {
        return this.campanaInfo ? `Apoya a ${this.campanaInfo.nombre}` : 'Tu donativo';
    }

    get resumenCampana() {
        return this.campanaInfo ? this.campanaInfo.resumen : undefined;
    }

    /**
     * US-22 (CA2): al elegir un nivel de impacto en la página de la campaña se llega con
     * ?monto=<n>. Se aplica una sola vez, para no pisar lo que la persona cambie después.
     * Si coincide con un paquete se elige ese paquete; si no, se usa "Otro monto".
     */
    montoAplicado = false;

    aplicarMontoDeLaDireccion(valor) {
        if (this.montoAplicado || valor === undefined || valor === null) {
            return;
        }
        const monto = parseMonto(valor);
        if (monto === null || monto <= 0) {
            return;
        }
        this.montoAplicado = true;
        const paquete = Object.keys(PAQUETES).find((k) => PAQUETES[k] === monto);
        if (paquete) {
            this.paquete = paquete;
        } else {
            this.paquete = 'Abierto';
            this.montoTexto = String(monto);
        }
    }

    /** La campaña de la dirección manda; si no viene, la que se configuró en Experience Builder. */
    get idCampana() {
        return this.campanaUrl || this.campaignId;
    }

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
    pagoCancelado = false;
    donativoId;
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
        return !this.registrado && !this.pagoCancelado;
    }

    get referenciaPago() {
        return this.donativoId ? String(this.donativoId).slice(-8).toUpperCase() : '';
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

    reintentarPago() {
        this.abrirPago();
    }

    /**
     * Pide al servidor la sesión de Stripe del donativo ya guardado y lleva a la persona a pagar.
     * El monto lo pone el servidor con lo guardado; aquí solo viaja el Id del donativo.
     */
    async abrirPago() {
        this.error = undefined;
        this.enviando = true;
        try {
            const url = await iniciarPago({
                donativoId: this.donativoId,
                paginaExito: ultimoTramo(this.paginaMuro),
                paginaRegreso: ultimoTramo(window.location.pathname)
            });
            // Al volver, el muro consulta el estado real de este donativo para avisar el resultado (CA7).
            guardarRetornoPago(this.donativoId);
            this.pagoCancelado = false;
            this.registrado = true;
            irA(url);
        } catch (e) {
            this.error = mensajeError(e);
            this.registrado = false;
            this.pagoCancelado = true;
        } finally {
            this.enviando = false;
        }
    }

    async enviar() {
        this.error = this.validar();
        if (this.error) {
            return;
        }
        const comoEmpresa = this.esPublico && this.esEmpresa;
        this.enviando = true;
        let r;
        try {
            r = await guardarDonativo({
                campaignId: this.idCampana || null,
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
        } catch (e) {
            this.error = mensajeError(e);
            return;
        } finally {
            this.enviando = false;
        }
        // CA1: el donativo ya quedó guardado como pendiente; hasta ahora se abre la pasarela.
        this.donativoId = r && r.donativoId;
        if (this.donativoId) {
            await this.abrirPago();
        } else {
            this.registrado = true; // campo trampa: no se guardó nada y no hay pago que abrir
        }
    }
}