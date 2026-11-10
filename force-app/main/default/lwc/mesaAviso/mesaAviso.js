import { LightningElement, api } from 'lwc';
import { resolverUrl } from 'c/mesaUtil';

const PENDIENTE = '[completar en Experience Builder]';

/**
 * Aviso de privacidad de la campaña. El texto vive en mesaAviso.html; lo que cambia de una
 * organización a otra (responsable, domicilio, correo de contacto, plazo, versión y fecha)
 * se edita en Experience Builder, sin desplegar.
 * Si se cambia el texto, subir la versión (v2 -> v3) y usar la misma versión en la propiedad
 * "Versión del aviso" de Registro, para que cada consentimiento quede ligado a la versión
 * que la persona aceptó.
 */
export default class MesaAviso extends LightningElement {
    @api responsable = 'El comité organizador de México Dreaming de la Facultad de Matemáticas';
    @api domicilio;
    @api correoContacto;
    @api plazoConservacion =
        'durante la campaña y el tiempo necesario para dar seguimiento a los donativos y atender solicitudes';
    @api versionAviso = 'v2';
    @api fechaActualizacion = '9 de noviembre de 2026';
    /** Nombre de la página de baja (como aparece en la URL) o ruta completa que empiece con "/". */
    @api paginaBaja = 'baja';

    get bajaHref() {
        return resolverUrl(this.paginaBaja);
    }

    get responsableTexto() {
        return this.responsable || PENDIENTE;
    }

    get domicilioTexto() {
        return this.domicilio || PENDIENTE;
    }

    get correoTexto() {
        return this.correoContacto || PENDIENTE;
    }

    get hayCorreo() {
        return !!this.correoContacto;
    }

    get enlaceCorreo() {
        return `mailto:${this.correoContacto}`;
    }

    get plazoTexto() {
        return this.plazoConservacion || PENDIENTE;
    }

    get claseDomicilio() {
        return this.domicilio ? '' : 'pendiente';
    }

    get claseCorreo() {
        return this.correoContacto ? '' : 'pendiente';
    }

    get clasePlazo() {
        return this.plazoConservacion ? '' : 'pendiente';
    }
}