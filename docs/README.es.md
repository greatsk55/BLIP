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

## Juego de Predicciones ✨ NEW

Haz predicciones sobre resultados del mundo real y gana **BP (BLIP Points)** — completamente anónimo.

- 🔮 **Vota en predicciones** — ¿Bitcoin llegará a $100k? ¿GTA 6 se lanzará en 2026?
- 🏆 **Gana recompensas** — Los votos correctos ganan puntos según distribución ponderada por popularidad
- 📊 **Sistema de 6 rangos** — Static → Receiver → Signal → Decoder → Control → Oracle
- ✏️ **Crea las tuyas** — Cualquiera puede crear preguntas de predicción (150 BP, descuentos por rango)
- 🕵️ **Totalmente anónimo** — Solo huella del dispositivo, sin cuentas necesarias
- 🌍 **8 idiomas** — Disponible en EN, KO, JA, ZH, ZH-TW, ES, FR, DE

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

## BLIP me — Enlace de contacto desechable

Comparte un solo enlace en tu perfil. Cuando alguien hace clic, se inicia un chat cifrado 1:1 al instante — sin cuentas, sin solicitudes de amistad.

- **Tu propio enlace** — Crea una URL única (ej: `blip.me/yourname`)
- **Alerta en tiempo real** — Recibe notificación al instante cuando un visitante se conecta
- **Gestión del enlace** — Cambia o elimina tu URL en cualquier momento
- **Sin cuenta necesaria** — Token basado en dispositivo demuestra la propiedad
- Visita `/blipme` en web, o toca la pestaña **BLIP me** en móvil

## Mis Salas

Las salas creadas o unidas recientemente se guardan localmente — sin almacenamiento en servidor.

- **Guardado automático**: las salas se almacenan en localStorage (web) o SecureStorage (móvil)
- **Reingreso con un clic**: la contraseña guardada te permite entrar sin escribirla de nuevo
- **Persistencia de admin**: los tokens de administrador de grupo se guardan para mantener privilegios
- **Lista unificada**: chats 1:1 y grupales en un solo lugar
- Visita `/my-rooms` en web, o toca la pestaña **Chat** en móvil

> Las contraseñas y tokens de admin nunca salen de tu dispositivo. Borrar los datos del navegador los elimina permanentemente.

## Embeber

Añade el chat BLIP a cualquier sitio web con un solo iframe:

```html
<iframe
  src="https://blip-blip.vercel.app/embed"
  width="400"
  height="600"
  style="border: none;"
  allow="clipboard-write"
></iframe>
```

Escucha los eventos del embed:

```js
window.addEventListener('message', (e) => {
  if (e.origin !== 'https://blip-blip.vercel.app') return;

  switch (e.data.type) {
    case 'blip:ready':         // Widget cargado
    case 'blip:room-created':  // Sala creada (roomId, shareUrl)
    case 'blip:room-joined':   // Entró al chat
    case 'blip:room-destroyed': // Sala destruida
  }
});
```

- Diseño ligero — sin anuncios, sin navegación
- Cifrado E2E completo mantenido
- Los enlaces compartidos se mantienen dentro del contexto embebido
- Ejemplo completo: [embed-example.html](../web/public/embed-example.html)

## Descargar

<a href="https://play.google.com/store/apps/details?id=com.bakkum.blip" target="_blank"><img src="https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png" alt="Disponible en Google Play" width="200"></a>

## Apoyo

Si te gusta este proyecto, ¡invítame un café!

<a href="https://buymeacoffee.com/ryokai" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" width="200"></a>

## Licencia

MIT
