import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import guardarDonativo from '@salesforce/apex/MesaRegalosController.guardarDonativo';
import obtenerCampana from '@salesforce/apex/MesaRegalosController.obtenerCampana';
import iniciarPago from '@salesforce/apex/MesaRegalosController.iniciarPago';
import { parseMonto, formatearMonto, mensajeError, resolverUrl, irA, guardarRetornoPago, leerRetornoPago } from 'c/mesaUtil';

// Deben coincidir con MesaRegalosController (el servidor es quien manda).
const MONTO_MINIMO = 100;
/** Montos de uso común, para campañas sin niveles de impacto. */
const MONTOS_COMUNES = [500, 1000, 3000, 5000];
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
     * El monto se escribe en el campo de monto; si coincide con una tarjeta, esa tarjeta se marca.
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
        this.montoTexto = String(monto);
    }

    /** La campaña de la dirección manda; si no viene, la que se configuró en Experience Builder. */
    get idCampana() {
        return this.campanaUrl || this.campaignId;
    }

    /** Siempre se envía como monto libre; el servidor valida mínimo y máximo. */
    paquete = 'Abierto';
    montoTexto = '';
    visibilidad = '';
    esEmpresa = false;
    nombreEmpresa = '';
    nombre = '';
    apellidos = '';
    linkedinUrl = '';
    correo = '';
    /** Casilla opcional de novedades. Sin marcar equivale a consentimiento «No». */
    quiereNovedades = false;
    aceptaAviso = false;
    sitioWeb = '';

    enviando = false;
    registrado = false;
    pagoCancelado = false;
    donativoId;
    error;

    // ---------- Presentación: tarjetas de monto, resumen de la causa y botón ----------

    imagenOculta = false;

    get claseContenedor() {
        return this.mostrarFormulario ? 'contenedor ancho' : 'contenedor';
    }

    /**
     * Tarjetas rápidas: los niveles de impacto de la campaña y, si no tiene, montos de uso común.
     * Elegir una llena el campo de monto, que se puede ajustar.
     */
    get montosBase() {
        const impactos = ((this.campanaInfo && this.campanaInfo.impactos) || [])
            .map((i) => ({ monto: Number(i.monto), detalle: i.descripcion }))
            .filter((i) => i.monto >= MONTO_MINIMO)
            .slice(0, 4);
        return impactos.length ? impactos : MONTOS_COMUNES.map((m) => ({ monto: m, detalle: '' }));
    }

    get tarjetasMonto() {
        return this.montosBase.map((t) => {
            const seleccionada = this.montoFinal === t.monto;
            return {
                valor: String(t.monto),
                etiqueta: `${formatearMonto(t.monto).replace('.00', '')}`,
                pulsada: String(seleccionada),
                clase: seleccionada ? 'monto seleccionado' : 'monto'
            };
        });
    }

    /** Columnas de las tarjetas: todas en una fila hasta 4. */
    get estiloMontos() {
        return `--columnas: ${Math.min(this.montosBase.length, 4)}`;
    }

    elegirMonto(evento) {
        this.limpiarError();
        this.montoTexto = evento.currentTarget.dataset.valor;
    }

    cambioMonto(evento) {
        this.limpiarError();
        this.montoTexto = evento.target.value;
    }

    /**
     * Mensaje bajo el monto: qué alcanza a cubrir (con los niveles de la campaña) o por qué no se puede continuar.
     * Solo afirma lo que es cierto: el nivel más alto cuyo monto ya se cubre.
     */
    get mensajeMonto() {
        const texto = (this.montoTexto || '').trim();
        const monto = this.montoFinal;
        if (!texto) {
            return `Elige un monto o escribe el tuyo (mínimo ${formatearMonto(MONTO_MINIMO).replace('.00', '')}).`;
        }
        if (monto === null || monto < MONTO_MINIMO) {
            return `El monto mínimo es ${formatearMonto(MONTO_MINIMO).replace('.00', '')} MXN.`;
        }
        const impactos = (this.campanaInfo && this.campanaInfo.impactos) || [];
        const cubiertos = impactos.filter((i) => Number(i.monto) <= monto).sort((x, y) => Number(y.monto) - Number(x.monto));
        if (cubiertos.length) {
            return `Con ${formatearMonto(monto).replace('.00', '')} alcanza para: ${cubiertos[0].descripcion}.`;
        }
        return 'Tu aportación se suma a la meta de la campaña.';
    }

    get claseMensajeMonto() {
        const monto = this.montoFinal;
        const texto = (this.montoTexto || '').trim();
        return texto && (monto === null || monto < MONTO_MINIMO) ? 'mensaje-monto mensaje-error' : 'mensaje-monto';
    }

    cambioVisibilidad(evento) {
        this.limpiarError();
        this.visibilidad = evento.target.value;
    }

    get clasePublica() {
        return this.esPublico ? 'opcion seleccionada' : 'opcion';
    }

    get claseAnonima() {
        return this.esAnonimo ? 'opcion seleccionada' : 'opcion';
    }

    get mostrarImagen() {
        return !!(this.campanaInfo && this.campanaInfo.imagenUrl) && !this.imagenOculta;
    }

    ocultarImagen() {
        this.imagenOculta = true;
    }

    get textoCausa() {
        const c = this.campanaInfo;
        return c ? c.resumen || c.descripcion : undefined;
    }

    get hayMeta() {
        return !!(this.campanaInfo && Number(this.campanaInfo.meta) > 0);
    }

    get recaudadoTexto() {
        return formatearMonto(Number(this.campanaInfo.total) || 0);
    }

    get metaTexto() {
        return formatearMonto(Number(this.campanaInfo.meta) || 0);
    }

    get porcentajeAvance() {
        return Math.min(100, Math.round(Number(this.campanaInfo.porcentaje) || 0));
    }

    get estiloBarra() {
        return `width: ${this.porcentajeAvance}%`;
    }

    get textoDonantes() {
        const n = this.campanaInfo ? Number(this.campanaInfo.donantes) || 0 : 0;
        if (n <= 0) {
            return '';
        }
        return n === 1 ? '1 persona ya donó' : `${n} personas ya donaron`;
    }

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

    get montoFinal() {
        return parseMonto(this.montoTexto);
    }

    get montoValido() {
        const monto = this.montoFinal;
        return monto !== null && monto >= MONTO_MINIMO;
    }

    get etiquetaBoton() {
        return this.montoValido ? `Donar ${formatearMonto(this.montoFinal)} MXN` : 'Elige un monto';
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
        this.limpiarError();
        const campo = evento.target.dataset.campo;
        if (evento.target.type === 'checkbox') {
            this[campo] = evento.target.checked;
        } else {
            this[campo] = evento.detail && evento.detail.value !== undefined ? evento.detail.value : evento.target.value;
        }
    }

    /** Revisión rápida para no hacer viajes al servidor. El servidor vuelve a validar todo. */
    validar() {
        this.pasoError = 0;
        if (!this.montoValido) {
            return this.fallo(1, `Escribe un monto de ${formatearMonto(MONTO_MINIMO)} o más.`);
        }
        if (!this.visibilidad) {
            return this.fallo(2, 'Elige si tu donativo será público o anónimo.');
        }
        if (this.esPublico) {
            if (this.esEmpresa) {
                if (!this.nombreEmpresa.trim()) {
                    return this.fallo(2, 'Escribe el nombre de la empresa.');
                }
            } else if (!this.nombre.trim() || !this.apellidos.trim()) {
                return this.fallo(2, 'Escribe tu nombre y apellidos.');
            }
            if (this.linkedinUrl.trim() && !LINKEDIN.test(this.linkedinUrl.trim())) {
                return this.fallo(2, 'La dirección de LinkedIn no es válida (https://www.linkedin.com/in/... o /company/...).');
            }
        }
        if (!CORREO.test(this.correo.trim())) {
            return this.fallo(3, 'Escribe un correo válido.');
        }
        if (!this.aceptaAviso) {
            return this.fallo(3, 'Para continuar debes aceptar el aviso de privacidad.');
        }
        return undefined;
    }

    // ---------- Errores junto al paso con el problema ----------

    /** Paso donde se muestra el error: 1, 2 o 3 del formulario; 4 = junto al botón; 0 = arriba (otros estados). */
    pasoError = 0;

    fallo(paso, mensaje) {
        this.pasoError = paso;
        return mensaje;
    }

    get errorSuperior() {
        return !!this.error && this.pasoError === 0;
    }

    get errorPaso1() {
        return !!this.error && this.pasoError === 1;
    }

    get errorPaso2() {
        return !!this.error && this.pasoError === 2;
    }

    get errorPaso3() {
        return !!this.error && this.pasoError === 3;
    }

    get errorBoton() {
        return !!this.error && this.pasoError === 4;
    }

    /** Baja la página hasta el mensaje de error, para que la persona vea qué falta sin buscarlo. */
    mostrarError() {
        requestAnimationFrame(() => {
            const aviso = this.template.querySelector('.error-formulario');
            if (aviso) {
                aviso.scrollIntoView({ behavior: 'smooth', block: 'center' });
            }
        });
    }

    /** En cuanto la persona edita algo, el error anterior ya no aplica. */
    limpiarError() {
        if (this.error && this.pasoError !== 0) {
            this.error = undefined;
            this.pasoError = 0;
        }
    }

    reintentarPago() {
        this.abrirPago();
    }

    /**
     * Pide al servidor la sesión de Stripe del donativo ya guardado y lleva a la persona a pagar.
     * El monto lo pone el servidor con lo guardado; aquí solo viaja el Id del donativo.
     */
    async abrirPago() {
        this.pasoError = 0;
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
            this.mostrarError();
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
                    monto: this.montoFinal,
                    visibilidad: this.visibilidad,
                    nombre: this.esPublico && !comoEmpresa ? this.nombre : null,
                    apellidos: this.esPublico && !comoEmpresa ? this.apellidos : null,
                    correo: this.correo,
                    esEmpresa: comoEmpresa,
                    nombreEmpresa: comoEmpresa ? this.nombreEmpresa : null,
                    linkedinUrl: this.esPublico ? this.linkedinUrl : null,
                    consentimientoAvisos: this.quiereNovedades ? 'Si' : 'No',
                    // No hay casilla aparte: elegir «Con mi nombre» o «Anónima» en el paso 2 ya autoriza publicar
                    // lo que esa opción dice (nombre y monto, o «Anónimo» y monto). El servidor exige este valor.
                    consentimientoPublicacion: true,
                    aceptaAviso: this.aceptaAviso,
                    versionAviso: this.versionAviso,
                    sitioWeb: this.sitioWeb
                })
            });
        } catch (e) {
            this.pasoError = 4;
            this.error = mensajeError(e);
            this.mostrarError();
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