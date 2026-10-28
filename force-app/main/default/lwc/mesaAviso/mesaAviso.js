import { LightningElement, api } from 'lwc';

const PENDIENTE = '[completar en Experience Builder]';

/**
 * Aviso de privacidad de la campaña. El texto vive en mesaAviso.html; lo que cambia de una
 * organización a otra (responsable, domicilio, correo de contacto, plazo, versión y fecha)
 * se edita en Experience Builder, sin desplegar.
 * Si se cambia el texto, subir la versión (v1 -> v2) y usar la misma versión en la propiedad
 * "Versión del aviso" de Registro, Reencuentro y Donación, para que cada consentimiento
 * quede ligado a la versión que la persona aceptó.
 */
export default class MesaAviso extends LightningElement {
    @api responsable = 'El comité organizador de México Dreaming de la Facultad de Matemáticas';
    @api domicilio;
    @api correoContacto;
    @api plazoConservacion =
        'durante la campaña y el tiempo necesario para dar seguimiento a los donativos y atender solicitudes';
    @api versionAviso = 'v1';
    @api fechaActualizacion = '28 de octubre de 2026';

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