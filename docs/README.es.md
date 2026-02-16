# BLIP

**Habla. Y desaparece.**

🌐 [한국어](README.ko.md) | [English](../README.md) | [日本語](README.ja.md) | [中文](README.zh.md) | [Español](#) | [Français](README.fr.md)

---

BLIP es un servicio de chat efímero que no deja rastro.
Sin cuentas. Sin historial. Sin perfiles. Empieza con un solo enlace, y cuando termina, todo desaparece.

> "Esta conversación no necesita ser guardada." — Construido exactamente para esos momentos.

---

## ¿Por qué BLIP?

Todos los mensajeros actuales guardan demasiado. Cuentas, listas de amigos, historial de chat, notificaciones...
Pero la mayoría de las conversaciones en la vida son solo **charlas rápidas que no necesitan perdurar**.

| Mensajeros tradicionales | BLIP |
|---|---|
| Requiere cuenta | Sin cuentas |
| Historial almacenado para siempre | Cero historial — irrecuperable |
| Necesitas agregar amigos | Únete al instante con un enlace |
| Datos almacenados en servidores | Sin almacenamiento en servidor, cifrado E2E |

## Concepto central

- **Cero preparación** — Empieza al instante con un solo enlace
- **Cero persistencia** — Irrecuperable después de terminar
- **Cero identidad** — Sin cuentas, amigos ni perfiles
- **100% basado en consenso** — Existe solo mientras todos los participantes estén de acuerdo
- **Auto-destrucción** — Solo los mensajes más recientes permanecen visibles; los antiguos se destruyen en tiempo real
- **Protección contra capturas** — Detecta intentos de captura de pantalla y grabación, difuminando los mensajes al instante

## Cómo funciona

```
1. Crear sala    →  Un solo botón
2. Compartir     →  Envía el enlace a cualquiera
3. Chatear       →  Mensajería en tiempo real con cifrado E2E
4. Terminar      →  Todos los datos destruidos al instante
```

## Casos de uso

- "Charla rápida, luego destruir la sala"
- "Reunión estratégica, luego borrar todo rastro"
- "Un enlace, reunión instantánea"
- Coordinación de partidas, comunicación en eventos, conversaciones sensibles de una sola vez

## Filosofía

BLIP no es un mensajero.
Es una **herramienta de comunicación desechable**.

No existe para mantener a las personas conectadas.
Existe para eliminar fricciones, hablar y desaparecer.

### Lo que NO hacemos

Este servicio intencionalmente **NO** hace lo siguiente:

- ~~Solicitudes de amistad~~
- ~~Historial de chat~~
- ~~Perfiles de usuario~~
- ~~Archivo de conversaciones~~
- ~~Funciones sociales~~

> Nunca sacrificamos la filosofía por conveniencia.

## Stack tecnológico

- Comunicación en tiempo real basada en WebSocket
- Cifrado de extremo a extremo (E2E — Curve25519 ECDH + XSalsa20-Poly1305)
- El servidor solo actúa como relay
- Al cerrar la sala: irrecuperable tanto en servidor como en cliente
- Auto-destrucción: los mensajes fuera de la ventana visible se eliminan al instante con liberación de blob URL
- Protección contra capturas: detección de cambio de pestaña, atajos de teclado y menú contextual para difuminar mensajes

## Apoyo

Si te gusta este proyecto, ¡invítame un café!

<a href="https://buymeacoffee.com/ryokai" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" width="200"></a>

## Licencia

MIT
