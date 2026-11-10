import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import obtenerCampana from '@salesforce/apex/MesaRegalosController.obtenerCampana';
import obtenerMuro from '@salesforce/apex/MesaRegalosController.obtenerMuro';
import { resolverUrl, irA, formatearMonto } from 'c/mesaUtil';

const MS_DIA = 24 * 60 * 60 * 1000;

/**
 * Página de presentación de una campaña (US-02). Lee el Id de la campaña de la dirección
 * (?campana=<Id>), que pone el botón "Ver campaña" del sitio central (mesaCampanas).
 *  - Campaña activa: muestra su información, su avance y el botón para donar.
 *  - Campaña cerrada: se muestra en solo lectura, sin opción de donar.
 *  - Dirección sin Id, con un Id inventado o de una campaña no publicada: mensaje claro, nunca
 *    datos de otra campaña.
 * Los textos y la página de donación se editan en Experience Builder, sin tocar código.
 */
export default class MesaCampanaDetalle extends LightningElement {
    @api textoBotonDonar = 'Donar';
    @api textoVolver = 'Ver todas las campañas';
    /** Nombre de la página de donación (como aparece en la URL) o ruta completa que empiece con "/". */
    @api paginaDonar = 'registro';

    campanaId;
    campana;
    donantes = [];
    cargando = true;
    hayError = false;

    @wire(CurrentPageReference)
    resolverPagina(ref) {
        if (!ref) {
            return;
        }
        const id = ref.state && ref.state.campana ? ref.state.campana : undefined;
        if (id === this.campanaId && !this.cargando) {
            return;
        }
        this.campanaId = id;
        this.cargar();
    }

    cargar() {
        this.cargando = true;
        this.hayError = false;
        this.campana = null;
        this.donantes = [];
        if (!this.campanaId) {
            this.cargando = false;
            return;
        }
        const id = this.campanaId;
        obtenerCampana({ campaignId: id })
            .then((d) => {
                if (id !== this.campanaId) {
                    return;
                }
                this.campana = d || null;
                this.cargando = false;
                if (d) {
                    this.cargarDonantes(id);
                }
            })
            .catch(() => {
                this.hayError = true;
                this.cargando = false;
            });
    }

    cargarDonantes(id) {
        obtenerMuro({ campaignId: id })
            .then((lista) => {
                if (id !== this.campanaId) {
                    return;
                }
                this.donantes = (lista || []).map((m, i) => ({
                    clave: `${i}-${m.nombre}`,
                    nombre: m.nombre,
                    monto: m.monto != null ? formatearMonto(m.monto) : ''
                }));
            })
            .catch(() => {
                // El muro es secundario: si falla, la campaña se muestra igual, sin lista.
                this.donantes = [];
            });
    }

    get noEncontrada() {
        return !this.cargando && !this.hayError && !this.campana;
    }

    get hayCampana() {
        return !this.cargando && !this.hayError && !!this.campana;
    }

    get cerrada() {
        return !!this.campana && !this.campana.activa;
    }

    get puedeDonar() {
        return !!this.campana && this.campana.activa;
    }

    get conMeta() {
        return !!this.campana && this.campana.meta > 0;
    }

    /** Con imagen, la imagen es el hero; sin ella se conserva la banda azul. */
    get claseHero() {
        return this.campana && this.campana.imagenUrl ? 'hero con-imagen' : 'hero banda-azul';
    }

    get porcentajeTexto() {
        return `${this.campana ? this.campana.porcentaje : 0}% de la meta`;
    }

    get hayRecaudado() {
        return !!this.campana && this.campana.total > 0;
    }

    get recaudado() {
        return formatearMonto(this.campana ? this.campana.total : 0);
    }

    get meta() {
        return formatearMonto(this.campana ? this.campana.meta : 0);
    }

    get estiloBarra() {
        return `width: ${this.campana ? this.campana.porcentaje : 0}%`;
    }

    get leyenda() {
        const c = this.campana;
        if (!c || !c.fechaFin) {
            return c && c.activa ? 'Sin fecha de cierre' : '';
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

    get hayDonantes() {
        return this.donantes.length > 0;
    }

    get urlVolver() {
        return resolverUrl('', null, false);
    }

    /** Si la imagen no carga (enlace roto o bloqueado), se oculta en lugar de mostrar el ícono roto. */
    ocultarImagen(evento) {
        evento.target.style.display = 'none';
    }

    donar() {
        irA(`${resolverUrl(this.paginaDonar, null, false)}?campana=${encodeURIComponent(this.campanaId)}`);
    }
}
