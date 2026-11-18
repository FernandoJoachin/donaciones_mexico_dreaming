import { LightningElement, api } from 'lwc';
import { resolverUrl, bajarALista, ponerTitulo, ponerIcono } from 'c/mesaUtil';

/**
 * Encabezado del sitio: marca, navegación y botón Donar. En pantallas chicas la navegación se abre
 * con un botón de menú. Los nombres siguen lo que pidió el panel: «Campañas activas» y «Campañas
 * pasadas», no un genérico «Campañas» que no dice qué lista.
 */
export default class MesaEncabezado extends LightningElement {
    @api marca = 'Comunidad Salesforce';
    @api lema = 'Facultad de Matemáticas';
    @api paginaMuro = 'muro';
    @api paginaFacturas = 'facturas';

    menuAbierto = false;

    /** El encabezado está en todas las páginas: aquí se pone el ícono y el título de la pestaña. */
    connectedCallback() {
        ponerIcono();
        const ruta = window.location.pathname.replace(/\/+$/, '');
        const tramo = ruta.substring(ruta.lastIndexOf('/') + 1);
        const titulos = {
            [this.paginaMuro]: 'Muro de agradecimiento',
            [this.paginaFacturas]: 'Facturas',
            registro: 'Donar',
            campana: 'Campaña'
        };
        // La página de una campaña vuelve a poner su título con el nombre de la campaña cuando lo conoce.
        ponerTitulo(titulos[tramo]);
    }

    /** Id de la campaña en la dirección (?campana=), si la página es de una campaña; si no, undefined. */
    get campanaActual() {
        const id = new URLSearchParams(window.location.search).get('campana');
        return id && /^[A-Za-z0-9]{15}([A-Za-z0-9]{3})?$/.test(id) ? id : undefined;
    }

    /** Página donde estamos, para marcar el enlace activo. */
    get actual() {
        const ruta = window.location.pathname.replace(/\/+$/, '');
        const tramo = ruta.substring(ruta.lastIndexOf('/') + 1);
        if (tramo === '' || tramo === 's' || tramo === 'inicio') {
            return 'campanas';
        }
        if (tramo === this.paginaMuro) {
            return 'muro';
        }
        if (tramo === this.paginaFacturas) {
            return 'facturas';
        }
        return '';
    }

    /**
     * «Campañas» es un solo enlace; el filtro Activas / Pasadas está dentro de la página. El muro es de
     * cada campaña, así que su enlace solo aparece dentro de una campaña y lleva al muro de ESA campaña.
     */
    get enlaces() {
        const inicio = resolverUrl('', null, false);
        const lista = [{ id: 'campanas', texto: 'Campañas', url: `${inicio}?pestana=activas`, lista: 'activas' }];
        if (this.campanaActual) {
            lista.push({
                id: 'muro',
                texto: 'Muro de esta campaña',
                url: `${resolverUrl(this.paginaMuro, null, false)}?campana=${encodeURIComponent(this.campanaActual)}`
            });
        }
        lista.push({ id: 'facturas', texto: 'Facturas', url: resolverUrl(this.paginaFacturas, null, false) });
        return lista.map((e) => ({
            ...e,
            clase: e.id === this.actual ? 'enlace activo' : 'enlace',
            actual: e.id === this.actual ? 'page' : null
        }));
    }

    get urlInicio() {
        return resolverUrl('', null, false);
    }

    /** «Donar» lleva a elegir campaña: la persona primero decide a cuál. */
    get urlDonar() {
        return `${resolverUrl('', null, false)}?pestana=activas`;
    }

    get claseMenu() {
        return this.menuAbierto ? 'menu menu-abierto' : 'menu';
    }

    get etiquetaBoton() {
        return this.menuAbierto ? 'Cerrar menú' : 'Abrir menú';
    }

    get expandido() {
        return this.menuAbierto ? 'true' : 'false';
    }

    /** Estando en el inicio, «Campañas» y «Donar» bajan a la lista sin recargar la página. */
    alNavegar(evento) {
        if (bajarALista(evento)) {
            this.menuAbierto = false;
        }
    }

    alternarMenu() {
        this.menuAbierto = !this.menuAbierto;
    }

    teclaMenu(evento) {
        if (evento.key === 'Escape' && this.menuAbierto) {
            this.menuAbierto = false;
        }
    }

    /** La ventana de ayuda vive en el pie; se le avisa por un evento de la ventana. */
    abrirAyuda() {
        this.menuAbierto = false;
        window.dispatchEvent(new CustomEvent('mesa:abrir-ayuda'));
    }
}
