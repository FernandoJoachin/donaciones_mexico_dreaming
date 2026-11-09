import { LightningElement, api } from 'lwc';
import { resolverUrl } from 'c/mesaUtil';

/**
 * Pie de pagina del sitio. Todo lo que cambia de una organizacion a otra se edita en
 * Experience Builder, sin desplegar. Lo que se deja vacio no se muestra: no hay datos de
 * contacto ni redes inventados.
 */
export default class MesaPie extends LightningElement {
    @api titulo = 'Salesforce Community';
    @api descripcion = 'Comunidad de ex-alumnos y amigos de la Facultad de Matemáticas, reunida en torno a causas que importan.';
    @api universidad = 'Universidad Autónoma de Yucatán';
    @api facultad = 'Facultad de Matemáticas';

    // Paginas del mismo sitio (nombre de la pagina). Vacio = no se muestra ese enlace.
    @api paginaCampanas = '';
    @api paginaDonar = 'donar';
    @api paginaMuro = 'muro';
    @api paginaReencuentro = 'reencuentro';

    // Aviso de privacidad: URL o nombre de pagina. Vacio = no se muestra.
    @api paginaAviso = '';

    @api correoContacto = '';
    @api telefonoContacto = '';
    @api urlInstagram = '';
    @api urlFacebook = '';
    @api urlLinkedin = '';

    @api textoCta = 'Cada aporte cuenta. Elige una campaña y sé parte.';
    @api textoBotonCta = 'Quiero donar';

    @api textoLegal = 'Facultad de Matemáticas, UADY.';

    get anio() {
        return new Date().getFullYear();
    }

    get enlaces() {
        const lista = [
            { id: 'inicio', texto: 'Inicio', url: resolverUrl('', null, false) },
            { id: 'campanas', texto: 'Campañas', pagina: this.paginaCampanas },
            { id: 'donar', texto: 'Donar', pagina: this.paginaDonar },
            { id: 'muro', texto: 'Quién ya se sumó', pagina: this.paginaMuro },
            { id: 'reencuentro', texto: 'Reencuentro', pagina: this.paginaReencuentro }
        ];
        return lista
            .map((e) => (e.pagina !== undefined ? { ...e, url: e.pagina ? resolverUrl(e.pagina, null, false) : null } : e))
            .filter((e) => e.url);
    }

    get urlDonar() {
        return this.paginaDonar ? resolverUrl(this.paginaDonar, null, false) : null;
    }

    get urlAviso() {
        return this.paginaAviso ? resolverUrl(this.paginaAviso, null, false) : null;
    }

    get hayContacto() {
        return Boolean(this.correoContacto || this.telefonoContacto);
    }

    get hrefCorreo() {
        return this.correoContacto ? `mailto:${this.correoContacto}` : null;
    }

    get hrefTelefono() {
        return this.telefonoContacto ? `tel:${this.telefonoContacto.replace(/[^\d+]/g, '')}` : null;
    }

    // Solo https: una propiedad mal escrita en el Builder no puede inyectar otro esquema.
    get redes() {
        return [
            { id: 'instagram', texto: 'Instagram', url: this.urlInstagram },
            { id: 'facebook', texto: 'Facebook', url: this.urlFacebook },
            { id: 'linkedin', texto: 'LinkedIn', url: this.urlLinkedin }
        ].filter((r) => r.url && /^https:\/\//i.test(r.url));
    }

    get hayRedes() {
        return this.redes.length > 0;
    }
}
