import { LightningElement, api, wire } from 'lwc';
import obtenerCampanas from '@salesforce/apex/MesaRegalosController.obtenerCampanas';
import { resolverUrl, irA, formatearMonto } from 'c/mesaUtil';

const MS_DIA = 24 * 60 * 60 * 1000;

/**
 * Sitio central (US-01): lista las campañas con su meta y su avance.
 *  - Por defecto muestra las campañas activas; la pestaña "Campañas pasadas" muestra las que ya
 *    cerraron, con la etiqueta "Cerrada" y sin botón para donar.
 *  - Qué campañas se publican y cuáles están activas lo decide el servidor (obtenerCampanas).
 *  - El botón lleva a la página de presentación de la campaña con ?campana=<Id>.
 * Los textos y la página de destino se editan en Experience Builder, sin tocar código.
 */
export default class MesaCampanas extends LightningElement {
    /** Texto pequeño sobre el título. Opcional: si queda vacío no se muestra. */
    @api etiqueta = '';
    @api titulo = 'Donaciones';
    @api descripcion =
        'Conoce las campañas de ex-alumnos de la Facultad de Matemáticas y apoya la que más te llegue.';
    @api textoBotonVer = 'Ver campaña';
    /** Nombre de la página de presentación (como aparece en la URL) o ruta completa que empiece con "/". */
    @api paginaCampana = 'campana';

    pestana = 'activas';

    @wire(obtenerCampanas)
    campanas;

    get hayError() {
        return !!(this.campanas && this.campanas.error);
    }

    get cargando() {
        return !this.campanas || (!this.campanas.data && !this.campanas.error);
    }

    get esActivas() {
        return this.pestana === 'activas';
    }

    get pulsadaActivas() {
        return this.esActivas ? 'true' : 'false';
    }

    get pulsadaPasadas() {
        return this.esActivas ? 'false' : 'true';
    }

    get claseActivas() {
        return this.esActivas ? 'tab tab-activa' : 'tab';
    }

    get clasePasadas() {
        return this.esActivas ? 'tab' : 'tab tab-activa';
    }

    get tarjetas() {
        const datos = (this.campanas && this.campanas.data) || [];
        return datos.filter((c) => c.activa === this.esActivas).map((c) => this.armarTarjeta(c));
    }

    get sinTarjetas() {
        return !this.cargando && !this.hayError && this.tarjetas.length === 0;
    }

    get mensajeVacio() {
        return this.esActivas
            ? 'Por ahora no hay campañas activas. Vuelve pronto.'
            : 'Todavía no hay campañas pasadas.';
    }

    armarTarjeta(c) {
        const conMeta = c.meta > 0;
        return {
            id: c.id,
            imagen: c.imagenUrl,
            nombre: c.nombre,
            descripcion: c.descripcion,
            cerrada: !c.activa,
            conMeta,
            hayRecaudado: c.total > 0,
            recaudado: formatearMonto(c.total),
            meta: formatearMonto(c.meta),
            porcentaje: c.porcentaje,
            estiloBarra: `width: ${c.porcentaje}%`,
            leyenda: this.leyenda(c),
            // CA7: las campañas cerradas se muestran sin opción de donar (no llevan botón).
            puedeDonar: c.activa
        };
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

    cambiarPestana(evento) {
        this.pestana = evento.currentTarget.dataset.pestana;
    }

    verCampana(evento) {
        const id = evento.currentTarget.dataset.id;
        irA(`${resolverUrl(this.paginaCampana, null, true)}?campana=${encodeURIComponent(id)}`);
    }
}
