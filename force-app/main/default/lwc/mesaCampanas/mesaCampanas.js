import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import obtenerCampanas from '@salesforce/apex/MesaRegalosController.obtenerCampanas';
import { resolverUrl, irA, formatearMonto } from 'c/mesaUtil';

/** "N personas ya donaron" (solo donaciones pagadas); vacío si nadie ha donado. */
function textoDonantes(n) {
    if (!n) {
        return '';
    }
    return n === 1 ? '1 persona ya donó' : `${n} personas ya donaron`;
}

const MS_DIA = 24 * 60 * 60 * 1000;

/**
 * Sitio central (US-01): lista las campañas con su meta y su avance.
 *  - Muestra primero las campañas activas; las que ya cerraron quedan abajo en una sección plegable
 *    "Campañas pasadas", en filas compactas y sin botón para donar.
 *  - Qué campañas se publican y cuáles están activas lo decide el servidor (obtenerCampanas).
 *  - El botón lleva a la página de presentación de la campaña con ?campana=<Id>.
 * Los textos y la página de destino se editan en Experience Builder, sin tocar código.
 */
export default class MesaCampanas extends LightningElement {
    /** Texto pequeño sobre el título. Opcional: si queda vacío no se muestra. */
    @api etiqueta = '';
    @api titulo = 'Donaciones';
    /** En la página de inicio la lista va debajo de la portada, sin su propia banda azul. */
    @api ocultarBanda = false;
    /** Landing: muestra la portada y la información de mesaInicio arriba de la lista (sin banda propia). */
    @api sinPortada = false;
    @api descripcion =
        'Conoce las campañas de la comunidad de la Facultad de Matemáticas y apoya la que más te llegue.';
    @api textoBotonVer = 'Ver campaña';
    /** Nombre de la página de presentación (como aparece en la URL) o ruta completa que empiece con "/". */
    @api paginaCampana = 'campana';

    pasadasAbiertas = false;
    _pedida = 'activas';
    _irALista = false;
    _yaDesplazado = false;

    /**
     * Desde el encabezado se llega con ?pestana=activas o ?pestana=pasadas: la página baja sola hasta
     * esa parte (con "pasadas" la sección plegable se abre), que es lo que la persona fue a buscar.
     */
    @wire(CurrentPageReference)
    leerPestanaDeLaDireccion(ref) {
        const pedida = ref && ref.state ? ref.state.pestana : undefined;
        if (pedida === 'activas' || pedida === 'pasadas') {
            this._pedida = pedida;
            this.pasadasAbiertas = pedida === 'pasadas';
            this._irALista = true;
        }
    }

    // Aviso de la ventana (lo mandan «Donar» y «Campañas» del encabezado y del pie): ya estamos aquí, así que
    // se baja a la parte pedida de inmediato (abriendo las pasadas si hace falta), sin recargar la página.
    _alPedirLista = (evento) => {
        const pedida = evento.detail && evento.detail.pestana;
        if (pedida === 'activas' || pedida === 'pasadas') {
            this._pedida = pedida;
            this.pasadasAbiertas = pedida === 'pasadas';
        }
        if (evento.detail) {
            evento.detail.manejado = true;
        }
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        requestAnimationFrame(() => {
            this.bajarAlAncla();
        });
    };

    /** Baja hasta el título de las activas, o hasta las pasadas si eso fue lo pedido. */
    bajarAlAncla() {
        const destino =
            (this._pedida === 'pasadas' && this.template.querySelector('.pasadas')) ||
            this.template.querySelector('.lista-titulo');
        if (destino) {
            destino.scrollIntoView({ behavior: 'smooth', block: 'start' });
        }
    }

    connectedCallback() {
        window.addEventListener('mesa:ir-a-campanas', this._alPedirLista);
    }

    disconnectedCallback() {
        window.removeEventListener('mesa:ir-a-campanas', this._alPedirLista);
    }

    renderedCallback() {
        // Una sola vez: se espera un momento a que el sitio termine de pintarse (si se baja antes, la
        // página vuelve arriba) y se baja hasta la lista de campañas. El elemento se busca otra vez al
        // bajar, porque al llegar los datos la lista se vuelve a pintar.
        if (this._irALista && !this._yaDesplazado && this.template.querySelector('.lista-titulo')) {
            this._yaDesplazado = true;
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            setTimeout(() => this.bajarAlAncla(), 1300);
        }
    }

    @wire(obtenerCampanas)
    campanas;

    get hayError() {
        return !!(this.campanas && this.campanas.error);
    }

    get cargando() {
        return !this.campanas || (!this.campanas.data && !this.campanas.error);
    }

    get tarjetas() {
        const datos = (this.campanas && this.campanas.data) || [];
        return datos.filter((c) => c.activa).map((c) => this.armarTarjeta(c));
    }

    get pasadas() {
        const datos = (this.campanas && this.campanas.data) || [];
        return datos
            .filter((c) => !c.activa)
            .map((c) => {
                const t = this.armarTarjeta(c);
                return { ...t, montoTexto: c.total > 0 ? `${t.recaudado} recaudados` : 'Sin donaciones' };
            });
    }

    get hayPasadas() {
        return this.pasadas.length > 0;
    }

    get tituloPasadas() {
        return `Campañas pasadas (${this.pasadas.length})`;
    }

    get sinTarjetas() {
        return !this.cargando && !this.hayError && this.tarjetas.length === 0;
    }

    get mensajeVacio() {
        return 'Por ahora no hay campañas activas. Vuelve pronto.';
    }

    armarTarjeta(c) {
        const conMeta = c.meta > 0;
        const aviso = this.aviso(c);
        return {
            id: c.id,
            imagen: c.imagenUrl,
            nombre: c.nombre,
            descripcion: c.resumen || c.descripcion,
            donantes: textoDonantes(c.donantes),
            conMeta,
            hayRecaudado: c.total > 0,
            recaudado: formatearMonto(c.total),
            meta: formatearMonto(c.meta),
            porcentaje: c.porcentaje,
            estiloBarra: `width: ${c.porcentaje}%`,
            // Si ya hay etiqueta de cierre, no se repite la leyenda de días.
            leyenda: aviso.aviso ? '' : this.leyenda(c),
            ...aviso
        };
    }

    /** Etiqueta destacada: "Meta superada", o "Cierra en N días" cuando faltan 7 o menos. */
    aviso(c) {
        if (!c.activa) {
            return { aviso: '', claseAviso: '' };
        }
        if (c.meta > 0 && c.total >= c.meta) {
            return { aviso: 'Meta superada', claseAviso: 'aviso aviso-meta' };
        }
        if (!c.fechaFin) {
            return { aviso: '', claseAviso: '' };
        }
        const hoy = new Date();
        hoy.setHours(0, 0, 0, 0);
        const dias = Math.round((new Date(`${c.fechaFin}T00:00:00`) - hoy) / MS_DIA);
        if (dias > 7) {
            return { aviso: '', claseAviso: '' };
        }
        const texto = dias <= 0 ? 'Cierra hoy' : dias === 1 ? 'Cierra mañana' : `Cierra en ${dias} días`;
        return { aviso: texto, claseAviso: 'aviso aviso-cierre' };
    }

    leyenda(c) {
        if (!c.fechaFin) {
            return c.activa ? 'Sin fecha de cierre' : '';
        }
        const fin = new Date(`${c.fechaFin}T00:00:00`);
        if (!c.activa) {
            const fecha = new Intl.DateTimeFormat('es-MX', {
                day: 'numeric',
                month: 'long',
                year: 'numeric'
            }).format(fin);
            return `Cerró el ${fecha}`;
        }
        const hoy = new Date();
        hoy.setHours(0, 0, 0, 0);
        const dias = Math.round((fin - hoy) / MS_DIA);
        if (dias <= 0) {
            return 'Cierra hoy';
        }
        return dias === 1 ? 'Falta 1 día' : `Faltan ${dias} días`;
    }

    /** Si la imagen no carga (enlace roto o bloqueado), se oculta en lugar de mostrar el ícono roto. */
    ocultarImagen(evento) {
        evento.target.style.display = 'none';
    }

    /** Mantiene sincronizado el estado cuando la persona abre o cierra la sección con un clic. */
    alAlternarPasadas(evento) {
        this.pasadasAbiertas = evento.target.open;
    }

    verCampana(evento) {
        const id = evento.currentTarget.dataset.id;
        irA(`${resolverUrl(this.paginaCampana, null, true)}?campana=${encodeURIComponent(id)}`);
    }

    get incluirPortada() {
        return !this.sinPortada;
    }

    get sinBanda() {
        return this.ocultarBanda || this.incluirPortada;
    }

    get mostrarBanda() {
        return !this.sinBanda;
    }

    get claseContenedor() {
        return this.sinBanda ? 'contenedor sin-banda' : 'contenedor';
    }
}
