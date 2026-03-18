# Registro de cambios

Todos los cambios importantes de BLIP se documentan aquí.

📋 Otros idiomas: [English](../CHANGELOG.md) | [한국어](CHANGELOG.ko.md) | [日本語](CHANGELOG.ja.md) | [中文](CHANGELOG.zh.md) | [Français](CHANGELOG.fr.md)

---

## v1.7.0 — Transferencia universal de archivos

- **Soporte para todo tipo de archivos**: Envía PDFs, documentos, archivos comprimidos, código y más
- **Iconos inteligentes**: Selección automática de iconos según la extensión del archivo
- **Validación de tamaño**: Límites por tipo (imágenes 50MB, videos 100MB, archivos 200MB)
- **Botón de descarga**: Descarga con un clic para archivos recibidos
- **Progreso de transferencia**: Indicador de progreso en tiempo real
- **Cifrado de extremo a extremo**: Todos los archivos cifrados con el mismo E2E que los mensajes

## v1.6.0 — Chat grupal

- **Salas grupales**: Crea salas de chat grupal sin límite de participantes
- **Controles de administrador**: Bloqueo de sala, expulsión, prohibición y destrucción
- **Token de administrador**: Autenticación separada para la gestión de salas
- **Barra lateral de participantes**: Lista de participantes en tiempo real con indicadores de administrador
- **Enlaces para compartir**: Genera enlaces de invitación con contraseña opcional incorporada
- **Expiración en 24 horas**: Las salas grupales expiran automáticamente después de 24 horas

## v1.5.0 — Widget de chat integrable

- **Guía de integración**: Guía paso a paso para integrar el chat BLIP en cualquier sitio web
- **Personalización del widget**: Apariencia y comportamiento configurables
- **Soporte cross-origin**: Integración segura de iframe con encabezados CSP adecuados

## v1.4.0 — Sistema de códigos de invitación comunitarios

- **Códigos de invitación**: Genera y comparte códigos de invitación para comunidades
- **Tablero comunitario**: Tablero público para discusiones comunitarias
- **Limitación de velocidad**: Protección contra spam y abuso

## v1.3.0 — Aplicación móvil y estabilidad

- **Optimización móvil**: Diseño totalmente responsivo y soporte PWA
- **Manejo del viewport visual**: Comportamiento correcto del teclado en dispositivos móviles
- **Mejoras de rendimiento**: Renderizado y uso de memoria optimizados

## v1.2.0 — Transferencia de medios cifrados

- **Transferencia de imágenes**: Envío y recepción de imágenes con cifrado E2E
- **Transferencia de video**: Compartición de video cifrado con miniaturas
- **Transferencia por fragmentos**: Archivos grandes divididos en fragmentos para entrega confiable
- **Verificación de checksum**: Verificación de integridad SHA-256 para todas las transferencias

## v1.1.0 — Destrucción instantánea de salas y notificaciones

- **Destrucción de salas**: Destruye salas de chat instantáneamente al terminar
- **Notificaciones del navegador**: Recibe notificaciones cuando llegan mensajes
- **Detección de captura de pantalla**: Alerta cuando se detecta captura de pantalla
- **Confirmación de salida**: Confirma antes de abandonar una sala de chat

## v1.0.0 — Lanzamiento inicial

- **Cifrado de extremo a extremo**: Intercambio de claves X25519 + cifrado XSalsa20-Poly1305
- **Salas efímeras**: Sin almacenamiento de mensajes, las salas expiran automáticamente
- **Acceso basado en contraseña**: Acceso seguro a salas con contraseñas generadas
- **Mensajería en tiempo real**: Mensajería instantánea WebSocket vía Supabase Realtime
- **Arquitectura de conocimiento cero**: El servidor nunca ve los mensajes en texto plano
- **Soporte multilingüe**: Inglés, coreano, japonés, chino, español, francés
