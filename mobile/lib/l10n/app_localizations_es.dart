// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get heroTitle => 'Habla. Luego desaparece.';

  @override
  String get heroSubtitle =>
      'Sin cuentas. Sin rastro. Sin historial.\nSolo existe la conversación de este momento.';

  @override
  String get heroCta => 'Haz clic para crear sala de chat';

  @override
  String get heroLinkShare =>
      'Conéctate perfectamente con un solo enlace, sin procedimientos complejos.';

  @override
  String get heroRateLimited =>
      'Se alcanzó el límite de creación de salas. Inténtalo más tarde.';

  @override
  String get heroCreateFailed => 'Error al crear la sala. Inténtalo de nuevo.';

  @override
  String get chatHeaderExit => 'EXIT';

  @override
  String chatHeaderOnline(int count) {
    return '$count en línea';
  }

  @override
  String get chatHeaderE2ee => 'Cifrado de extremo a extremo';

  @override
  String get chatInputPlaceholder => 'Escribir mensaje...';

  @override
  String get chatInputSend => 'Enviar';

  @override
  String get chatCreateTitle => 'CHANNEL CREATED';

  @override
  String get chatCreatePassword => 'ACCESS KEY';

  @override
  String get chatCreateShareLink => 'Enlace para compartir';

  @override
  String get chatCreateWarning => 'GUARDA ESTA CLAVE. NO SE PUEDE RECUPERAR.';

  @override
  String get chatCreateEnter => 'ENTRAR AL CANAL';

  @override
  String get chatJoinTitle => 'ENTER ACCESS KEY';

  @override
  String get chatJoinConnect => 'CONNECT';

  @override
  String get chatJoinInvalidKey => 'INVALID_KEY';

  @override
  String get chatJoinExpired => 'CHANNEL_EXPIRED';

  @override
  String get chatJoinFull => 'CHANNEL_FULL';

  @override
  String get chatLeaveTitle => 'EXIT CHANNEL?';

  @override
  String get chatLeaveDescription => '¿Estás seguro de que quieres salir?';

  @override
  String get chatLeaveLastPersonWarning =>
      'Eres el último participante. Salir destruirá permanentemente este canal.';

  @override
  String get chatLeaveConfirm => 'EXIT';

  @override
  String get chatLeaveCancel => 'CANCEL';

  @override
  String get chatDestroyedTitle => 'No queda rastro.';

  @override
  String get chatDestroyedSubtitle =>
      'Este canal ha sido destruido permanentemente.';

  @override
  String get chatDestroyedNewChat => 'Iniciar nuevo canal';

  @override
  String get chatRoomFullTitle => 'Canal lleno.';

  @override
  String get chatRoomFullSubtitle => 'Este canal ya tiene 2 participantes.';

  @override
  String get chatRoomFullNewChat => 'Iniciar nuevo canal';

  @override
  String get chatMediaAttachFile => 'Adjuntar media';

  @override
  String chatMediaFileTooLarge(String maxSize) {
    return 'Archivo demasiado grande (máx. $maxSize)';
  }

  @override
  String get chatMediaSendingFile => 'Enviando archivo...';

  @override
  String get chatMediaP2pConnecting => 'Estableciendo conexión P2P segura...';

  @override
  String get chatMediaP2pFailed =>
      'Conexión P2P fallida. Solo texto disponible.';

  @override
  String get chatMediaP2pConnected => 'Canal de media P2P listo';

  @override
  String get chatMediaVideoLoadFailed => 'Error al cargar el video';

  @override
  String get chatMediaUnsupportedType => 'Tipo de archivo no soportado';

  @override
  String get boardCreateTitle => 'COMUNIDAD CREADA';

  @override
  String get boardCreateSubtitle => 'Crear Comunidad Privada';

  @override
  String get boardCreateButton => 'Crear Comunidad';

  @override
  String get boardCreateNamePlaceholder => 'Nombre de la comunidad';

  @override
  String get boardCreatePassword => 'Contraseña de la Comunidad';

  @override
  String get boardCreateAdminToken => 'Token de Administrador';

  @override
  String get boardCreateAdminTokenWarning =>
      'Guarda este token — no se puede recuperar';

  @override
  String get boardCreateShareLink => 'Enlace para Compartir';

  @override
  String get boardCreateEnter => 'Entrar a la Comunidad';

  @override
  String get boardHeaderEncrypted => 'Cifrado E2E';

  @override
  String get boardHeaderAdmin => 'Panel de Administración';

  @override
  String get boardHeaderForgetPassword => 'Olvidar contraseña guardada';

  @override
  String get boardHeaderForgetPasswordConfirm =>
      'Se eliminará la contraseña guardada en este dispositivo. Deberá ingresarla nuevamente en su próxima visita.';

  @override
  String get boardHeaderCancel => 'Cancelar';

  @override
  String get boardHeaderConfirmForget => 'Eliminar';

  @override
  String get boardHeaderRegisterAdmin => 'Registrar token de administrador';

  @override
  String get boardHeaderAdminTokenPlaceholder => 'Pegar token de administrador';

  @override
  String get boardHeaderConfirmRegister => 'Registrar';

  @override
  String get boardPostPlaceholder => 'Escribe algo... (Markdown compatible)';

  @override
  String get boardPostSubmit => 'Publicar';

  @override
  String get boardPostCompose => 'Nueva publicación';

  @override
  String get boardPostDetail => 'Publicación';

  @override
  String get boardPostEmpty => 'Aún no hay publicaciones';

  @override
  String get boardPostWriteFirst => 'Escribe la primera publicación';

  @override
  String get boardPostRefresh => 'Actualizar';

  @override
  String get boardPostAttachImage => 'Adjuntar imagen';

  @override
  String get boardPostMaxImages => 'Máximo 4 imágenes';

  @override
  String get boardPostImageTooLarge => 'Imagen demasiado grande';

  @override
  String get boardPostUploading => 'Subiendo...';

  @override
  String get boardPostAttachMedia => 'Adjuntar media';

  @override
  String boardPostMaxMedia(int count) {
    return 'Máximo $count archivos';
  }

  @override
  String boardPostVideoTooLong(int seconds) {
    return 'Video demasiado largo (máx. ${seconds}s)';
  }

  @override
  String get boardPostVideoTooLarge => 'Video demasiado grande tras compresión';

  @override
  String get boardPostCompressing => 'Comprimiendo...';

  @override
  String get boardPostTitlePlaceholder => 'Título (opcional)';

  @override
  String get boardPostInsertInline => 'Insertar en contenido';

  @override
  String get boardPostEdit => 'Editar';

  @override
  String get boardPostEditTitle => 'Editar Publicación';

  @override
  String get boardPostSave => 'Guardar';

  @override
  String get boardPostDelete => 'Eliminar';

  @override
  String get boardPostAdminDelete => 'Eliminar (Admin)';

  @override
  String get boardPostDeleteWarning =>
      'Esta publicación se eliminará permanentemente. No se puede deshacer.';

  @override
  String get boardPostConfirmDelete => 'Eliminar';

  @override
  String get boardReportTitle => 'Reportar Publicación';

  @override
  String get boardReportSpam => 'Spam';

  @override
  String get boardReportAbuse => 'Abuso / Acoso';

  @override
  String get boardReportIllegal => 'Contenido Ilegal';

  @override
  String get boardReportOther => 'Otro';

  @override
  String get boardReportSubmit => 'Reportar';

  @override
  String get boardReportCancel => 'Cancelar';

  @override
  String get boardReportAlreadyReported => 'Ya reportado';

  @override
  String get boardBlindedMessage => 'Ocultado por reportes de la comunidad';

  @override
  String get boardAdminTitle => 'Panel de Administración';

  @override
  String get boardAdminDestroy => 'Destruir Comunidad';

  @override
  String get boardAdminDestroyWarning =>
      'Esto eliminará permanentemente la comunidad y todas las publicaciones. No se puede deshacer.';

  @override
  String get boardAdminCancel => 'Cancelar';

  @override
  String get boardAdminConfirmDestroy => 'Destruir';

  @override
  String get boardDestroyedTitle => 'Comunidad Destruida';

  @override
  String get boardDestroyedMessage =>
      'Esta comunidad ha sido eliminada permanentemente.';

  @override
  String get commonSettings => 'Ajustes';

  @override
  String get commonTheme => 'Tema';

  @override
  String get commonLanguage => 'Idioma';

  @override
  String get commonCopy => 'Copiar';

  @override
  String get commonShare => 'Compartir';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonConfirm => 'Confirmar';

  @override
  String get commonLoading => 'Cargando...';

  @override
  String get commonError => 'Se produjo un error';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonClose => 'Cerrar';

  @override
  String get commonBack => 'Atrás';

  @override
  String get commonDone => 'Hecho';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonCopied => 'Copiado al portapapeles';

  @override
  String get heroBoardCta => 'Tablón Comunitario';

  @override
  String get featureZeroFriction => 'Sin Fricciones';

  @override
  String get featureZeroFrictionDesc =>
      'Conéctate perfectamente con un solo enlace, sin procedimientos complejos.';

  @override
  String get featureAnonymity => 'Anonimato Total';

  @override
  String get featureAnonymityDesc =>
      'Sin cuentas, sin perfiles. Solo importa la conversación.';

  @override
  String get featureDestruction => 'Autodestrucción';

  @override
  String get featureDestructionDesc =>
      'Cuando todos se van, todos los rastros desaparecen permanentemente.';

  @override
  String get errorRateLimit =>
      'Demasiadas solicitudes. Por favor, inténtalo más tarde.';

  @override
  String get errorGeneric => 'Se produjo un error.';

  @override
  String get chatConnected =>
      'Conexión cifrada de extremo a extremo establecida';

  @override
  String get chatPasswordTitle => 'Ingresa la clave de acceso';

  @override
  String get chatPasswordSubtitle =>
      'Comparte la clave de acceso con tu compañero de conversación';

  @override
  String get chatPasswordJoin => 'Unirse';

  @override
  String get chatPasswordInvalid => 'Clave de acceso inválida';

  @override
  String get chatRoomNotFound => 'Sala no encontrada';

  @override
  String get chatRoomDestroyed => 'La sala ha sido destruida';

  @override
  String get chatExpired => 'La sala ha expirado';

  @override
  String get chatRoomFull => 'La sala está llena';

  @override
  String get chatCreatedTitle => 'Sala Creada';

  @override
  String chatShareMessage(String link, String password) {
    return '¡Únete a mi chat de BLIP!\n\n$link\nContraseña: $password';
  }

  @override
  String get chatWaitingPeer => 'Esperando a que alguien se una...';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsThemeDark => 'Modo Oscuro';

  @override
  String get settingsThemeLight => 'Modo Claro';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsAbout => 'Acerca de';

  @override
  String get boardTitle => 'Tablón Comunitario';

  @override
  String get boardCreated => '¡Comunidad creada con éxito!';

  @override
  String get boardDestroyed => 'Esta comunidad ha sido destruida.';

  @override
  String get boardEmpty =>
      'Aún no hay publicaciones. ¡Sé el primero en escribir!';

  @override
  String get boardWritePost => 'Escribir Publicación';

  @override
  String get problemTitle => 'Tus conversaciones duran demasiado.';

  @override
  String get problemDescription =>
      'Registros del servidor, capturas de pantalla, chats grupales olvidados...\nNo todas las conversaciones necesitan un registro. Algunas deberían desaparecer como el humo.';

  @override
  String get solutionFrictionTitle => '0 Friction';

  @override
  String get solutionFrictionDesc =>
      'Cero configuración. Envía un enlace, empieza a hablar.';

  @override
  String get solutionAnonymityTitle => 'Total Anonymity';

  @override
  String get solutionAnonymityDesc =>
      'No preguntamos quién eres. No se necesita ID ni perfil.';

  @override
  String get solutionDestructionTitle => 'Complete Destruction';

  @override
  String get solutionDestructionDesc =>
      'Excepto tú y el destinatario, ni siquiera nosotros podemos verlo.';

  @override
  String get solutionAutoshredTitle => 'Auto-Shred';

  @override
  String get solutionAutoshredDesc =>
      'Solo los últimos mensajes permanecen en pantalla. Los antiguos se destruyen en tiempo real — sin desplazamiento, sin contexto.';

  @override
  String get solutionCaptureGuardTitle => 'Capture Guard';

  @override
  String get solutionCaptureGuardDesc =>
      'Se detectan intentos de captura de pantalla y grabación. Los mensajes se difuminan al instante — nada que capturar.';

  @override
  String get solutionOpensourceTitle => 'Transparent Code';

  @override
  String get solutionOpensourceDesc =>
      '100% de código abierto. Puedes verificar con el código que nunca espiamos tus conversaciones.';

  @override
  String get communityLabel => 'NUEVO';

  @override
  String get communityTitle => 'Crea tu propia comunidad privada. Cifrada.';

  @override
  String get communitySubtitle =>
      'Crea una comunidad privada con una sola contraseña.\nLas publicaciones se almacenan como texto cifrado ilegible — el servidor nunca puede ver tu contenido.\nMarkdown, imágenes, publicación anónima. Todo cifrado de extremo a extremo.';

  @override
  String get communityCta => 'Crear Comunidad Privada';

  @override
  String get communityPasswordTitle => 'Contraseña = Llave';

  @override
  String get communityPasswordDesc =>
      'Una contraseña compartida cifra todo. Sin cuentas, sin registros. Comparte la contraseña, comparte el espacio.';

  @override
  String get communityServerBlindTitle => 'Servidor Ciego';

  @override
  String get communityServerBlindDesc =>
      'Almacenamos tus publicaciones, pero nunca podemos leerlas. La clave de descifrado nunca sale de tu dispositivo.';

  @override
  String get communityModerationTitle => 'Moderación Comunitaria';

  @override
  String get communityModerationDesc =>
      'Sistema de reportes con ocultamiento automático. Ningún admin necesita leer contenido para mantener el espacio seguro.';

  @override
  String get philosophyText1 =>
      'BLIP no es un mensajero. Es una herramienta de comunicación desechable.';

  @override
  String get philosophyText2 =>
      'No queremos retenerte. Di lo que tengas que decir y vete.';

  @override
  String get footerEasterEgg =>
      'Esta página también podría desaparecer pronto.';

  @override
  String get footerSupportProtocol => 'Apoyar el Protocolo';

  @override
  String get footerCopyright => '© 2026 BLIP PROTOCOL';

  @override
  String get footerNoRights => 'NO RIGHTS RESERVED';

  @override
  String get navHome => 'Inicio';

  @override
  String get navChat => 'Chat';

  @override
  String get navCommunity => 'Comunidad';

  @override
  String get chatListTitle => 'Mis Salas de Chat';

  @override
  String get chatListEmpty =>
      'Aún no hay salas de chat.\nCrea una sala desde la pestaña Inicio.';

  @override
  String get chatListCreateNew => 'Crear Nueva Sala';

  @override
  String get chatListJoinById => 'Unirse por ID de sala';

  @override
  String get chatListJoinDialogTitle => 'Unirse a sala de chat';

  @override
  String get chatListJoinDialogHint => 'ID de sala o enlace';

  @override
  String get chatListJoinDialogJoin => 'Unirse';

  @override
  String get chatListStatusActive => 'Activo';

  @override
  String get chatListStatusDestroyed => 'Destruido';

  @override
  String get chatListStatusExpired => 'Expirado';

  @override
  String get communityListTitle => 'Mis Comunidades';

  @override
  String get communityListEmpty => 'Aún no te has unido a ninguna comunidad.';

  @override
  String get communityListCreate => 'Crear Nuevo';

  @override
  String get communityListJoinById => 'Unirse por ID';

  @override
  String get communityListJoinDialogTitle => 'Unirse a Comunidad';

  @override
  String get communityListJoinDialogHint => 'Ingresa el Board ID';

  @override
  String get communityListJoinDialogJoin => 'Unirse';

  @override
  String get communityListJoinedAt => 'Unido:';

  @override
  String get contactButton => 'Contactar';

  @override
  String get contactConfirmTitle => '¿Enviar notificación?';

  @override
  String get contactConfirmMessage =>
      'Se enviará una notificación push a la otra persona. No se compartirá ningún contenido del chat.';

  @override
  String get contactSent => 'Notificación enviada';

  @override
  String get contactNotReady => 'La notificación push aún no está disponible';

  @override
  String get cancel => 'Cancelar';

  @override
  String get confirm => 'Aceptar';

  @override
  String get boardRefresh => 'Actualizar';

  @override
  String get boardAdminPanel => 'Panel de administración';

  @override
  String get boardAdminRegister => 'Registrar token de administrador';

  @override
  String get boardAdminTokenPlaceholder => 'Ingrese token de administrador...';

  @override
  String get boardAdminConfirmRegister => 'Registrar';

  @override
  String get boardAdminForgetToken => 'Eliminar token de administrador';

  @override
  String get boardAdminEditSubtitle => 'Editar subtítulo';

  @override
  String get boardAdminSubtitlePlaceholder =>
      'Subtítulo de la comunidad (opcional)';

  @override
  String get boardAdminSubtitleSave => 'Guardar';

  @override
  String get boardCreateSubtitlePlaceholder => 'Subtítulo (opcional)';
}
