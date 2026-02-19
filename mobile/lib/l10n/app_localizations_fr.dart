// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get heroTitle => 'Parlez. Puis disparaissez.';

  @override
  String get heroSubtitle =>
      'Pas de compte. Pas de trace. Pas d\'historique.\nSeule la conversation de ce moment existe.';

  @override
  String get heroCta => 'Cliquez pour créer un salon';

  @override
  String get heroLinkShare =>
      'Connectez-vous parfaitement avec un seul lien, sans procédures complexes.';

  @override
  String get heroRateLimited =>
      'Limite de création de salons atteinte. Veuillez réessayer plus tard.';

  @override
  String get heroCreateFailed =>
      'Échec de la création du salon. Veuillez réessayer.';

  @override
  String get chatHeaderExit => 'EXIT';

  @override
  String chatHeaderOnline(int count) {
    return '$count en ligne';
  }

  @override
  String get chatHeaderE2ee => 'Chiffrement de bout en bout';

  @override
  String get chatInputPlaceholder => 'Taper un message...';

  @override
  String get chatInputSend => 'Envoyer';

  @override
  String get chatCreateTitle => 'CHANNEL CREATED';

  @override
  String get chatCreatePassword => 'ACCESS KEY';

  @override
  String get chatCreateShareLink => 'Lien de partage';

  @override
  String get chatCreateWarning =>
      'SAUVEGARDEZ CETTE CLÉ. ELLE NE PEUT PAS ÊTRE RÉCUPÉRÉE.';

  @override
  String get chatCreateEnter => 'ENTRER DANS LE CANAL';

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
  String get chatLeaveDescription => 'Êtes-vous sûr de vouloir partir ?';

  @override
  String get chatLeaveLastPersonWarning =>
      'Vous êtes le dernier participant. Partir détruira définitivement ce canal.';

  @override
  String get chatLeaveConfirm => 'EXIT';

  @override
  String get chatLeaveCancel => 'CANCEL';

  @override
  String get chatDestroyedTitle => 'Aucune trace ne subsiste.';

  @override
  String get chatDestroyedSubtitle => 'Ce canal a été définitivement détruit.';

  @override
  String get chatDestroyedNewChat => 'Démarrer un nouveau canal';

  @override
  String get chatRoomFullTitle => 'Canal complet.';

  @override
  String get chatRoomFullSubtitle => 'Ce canal a déjà 2 participants.';

  @override
  String get chatRoomFullNewChat => 'Démarrer un nouveau canal';

  @override
  String get chatMediaAttachFile => 'Joindre un média';

  @override
  String chatMediaFileTooLarge(String maxSize) {
    return 'Fichier trop volumineux (max. $maxSize)';
  }

  @override
  String get chatMediaSendingFile => 'Envoi du fichier...';

  @override
  String get chatMediaP2pConnecting =>
      'Établissement de la connexion P2P sécurisée...';

  @override
  String get chatMediaP2pFailed => 'Connexion P2P échouée. Texte uniquement.';

  @override
  String get chatMediaP2pConnected => 'Canal média P2P prêt';

  @override
  String get chatMediaVideoLoadFailed => 'Échec du chargement de la vidéo';

  @override
  String get chatMediaUnsupportedType => 'Type de fichier non pris en charge';

  @override
  String get boardCreateTitle => 'COMMUNAUTÉ CRÉÉE';

  @override
  String get boardCreateSubtitle => 'Créer une Communauté Privée';

  @override
  String get boardCreateButton => 'Créer la Communauté';

  @override
  String get boardCreateNamePlaceholder => 'Nom de la communauté';

  @override
  String get boardCreatePassword => 'Mot de passe de la Communauté';

  @override
  String get boardCreateAdminToken => 'Jeton Administrateur';

  @override
  String get boardCreateAdminTokenWarning =>
      'Sauvegardez ce jeton — il ne peut pas être récupéré';

  @override
  String get boardCreateShareLink => 'Lien de Partage';

  @override
  String get boardCreateEnter => 'Entrer dans la Communauté';

  @override
  String get boardHeaderEncrypted => 'Chiffrement E2E';

  @override
  String get boardHeaderAdmin => 'Panneau d\'Administration';

  @override
  String get boardHeaderForgetPassword => 'Oublier le mot de passe enregistré';

  @override
  String get boardHeaderForgetPasswordConfirm =>
      'Le mot de passe enregistré sur cet appareil sera supprimé. Vous devrez le saisir à nouveau lors de votre prochaine visite.';

  @override
  String get boardHeaderCancel => 'Annuler';

  @override
  String get boardHeaderConfirmForget => 'Supprimer';

  @override
  String get boardHeaderRegisterAdmin => 'Enregistrer le jeton admin';

  @override
  String get boardHeaderAdminTokenPlaceholder => 'Coller le jeton admin';

  @override
  String get boardHeaderConfirmRegister => 'Enregistrer';

  @override
  String get boardPostPlaceholder =>
      'Écrivez quelque chose... (Markdown pris en charge)';

  @override
  String get boardPostSubmit => 'Publier';

  @override
  String get boardPostCompose => 'Nouvelle publication';

  @override
  String get boardPostDetail => 'Publication';

  @override
  String get boardPostEmpty => 'Aucune publication pour le moment';

  @override
  String get boardPostWriteFirst => 'Écrivez la première publication';

  @override
  String get boardPostRefresh => 'Actualiser';

  @override
  String get boardPostAttachImage => 'Joindre une image';

  @override
  String get boardPostMaxImages => '4 images maximum';

  @override
  String get boardPostImageTooLarge => 'Image trop volumineuse';

  @override
  String get boardPostUploading => 'Téléchargement...';

  @override
  String get boardPostAttachMedia => 'Joindre un média';

  @override
  String boardPostMaxMedia(int count) {
    return 'Max $count fichiers';
  }

  @override
  String boardPostVideoTooLong(int seconds) {
    return 'Vidéo trop longue (max ${seconds}s)';
  }

  @override
  String get boardPostVideoTooLarge =>
      'Vidéo trop volumineuse après compression';

  @override
  String get boardPostCompressing => 'Compression...';

  @override
  String get boardPostTitlePlaceholder => 'Titre (optionnel)';

  @override
  String get boardPostInsertInline => 'Insérer dans le contenu';

  @override
  String get boardPostEdit => 'Modifier';

  @override
  String get boardPostEditTitle => 'Modifier la Publication';

  @override
  String get boardPostSave => 'Enregistrer';

  @override
  String get boardPostDelete => 'Supprimer';

  @override
  String get boardPostAdminDelete => 'Supprimer (Admin)';

  @override
  String get boardPostDeleteWarning =>
      'Cette publication sera définitivement supprimée. Cette action est irréversible.';

  @override
  String get boardPostConfirmDelete => 'Supprimer';

  @override
  String get boardReportTitle => 'Signaler la Publication';

  @override
  String get boardReportSpam => 'Spam';

  @override
  String get boardReportAbuse => 'Abus / Harcèlement';

  @override
  String get boardReportIllegal => 'Contenu Illégal';

  @override
  String get boardReportOther => 'Autre';

  @override
  String get boardReportSubmit => 'Signaler';

  @override
  String get boardReportCancel => 'Annuler';

  @override
  String get boardReportAlreadyReported => 'Déjà signalé';

  @override
  String get boardBlindedMessage =>
      'Masqué suite aux signalements de la communauté';

  @override
  String get boardAdminTitle => 'Panneau d\'Administration';

  @override
  String get boardAdminDestroy => 'Détruire la Communauté';

  @override
  String get boardAdminDestroyWarning =>
      'Cela supprimera définitivement la communauté et toutes les publications. Cette action est irréversible.';

  @override
  String get boardAdminCancel => 'Annuler';

  @override
  String get boardAdminConfirmDestroy => 'Détruire';

  @override
  String get boardDestroyedTitle => 'Communauté Détruite';

  @override
  String get boardDestroyedMessage =>
      'Cette communauté a été définitivement supprimée.';

  @override
  String get commonSettings => 'Paramètres';

  @override
  String get commonTheme => 'Thème';

  @override
  String get commonLanguage => 'Langue';

  @override
  String get commonCopy => 'Copier';

  @override
  String get commonShare => 'Partager';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonConfirm => 'Confirmer';

  @override
  String get commonLoading => 'Chargement...';

  @override
  String get commonError => 'Une erreur est survenue';

  @override
  String get commonRetry => 'Réessayer';

  @override
  String get commonClose => 'Fermer';

  @override
  String get commonBack => 'Retour';

  @override
  String get commonDone => 'Terminé';

  @override
  String get commonDelete => 'Supprimer';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get commonCopied => 'Copié dans le presse-papiers';

  @override
  String get heroBoardCta => 'Tableau Communautaire';

  @override
  String get featureZeroFriction => 'Zéro Friction';

  @override
  String get featureZeroFrictionDesc =>
      'Connectez-vous parfaitement avec un seul lien, sans procédures complexes.';

  @override
  String get featureAnonymity => 'Anonymat Total';

  @override
  String get featureAnonymityDesc =>
      'Pas de comptes, pas de profils. Seule la conversation compte.';

  @override
  String get featureDestruction => 'Autodestruction';

  @override
  String get featureDestructionDesc =>
      'Quand tout le monde part, toutes les traces disparaissent définitivement.';

  @override
  String get errorRateLimit =>
      'Trop de requêtes. Veuillez réessayer plus tard.';

  @override
  String get errorGeneric => 'Une erreur est survenue.';

  @override
  String get chatConnected => 'Connexion chiffrée de bout en bout établie';

  @override
  String get chatPasswordTitle => 'Entrez la clé d\'accès';

  @override
  String get chatPasswordSubtitle =>
      'Partagez la clé d\'accès avec votre interlocuteur';

  @override
  String get chatPasswordJoin => 'Rejoindre';

  @override
  String get chatPasswordInvalid => 'Clé d\'accès invalide';

  @override
  String get chatRoomNotFound => 'Salon introuvable';

  @override
  String get chatRoomDestroyed => 'Le salon a été détruit';

  @override
  String get chatExpired => 'Le salon a expiré';

  @override
  String get chatRoomFull => 'Le salon est complet';

  @override
  String get chatCreatedTitle => 'Salon Créé';

  @override
  String chatShareMessage(String link, String password) {
    return 'Rejoignez mon chat BLIP !\n\n$link\nMot de passe : $password';
  }

  @override
  String get chatWaitingPeer => 'En attente d\'un participant...';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsTheme => 'Thème';

  @override
  String get settingsThemeDark => 'Mode Sombre';

  @override
  String get settingsThemeLight => 'Mode Clair';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsAbout => 'À propos';

  @override
  String get boardTitle => 'Tableau Communautaire';

  @override
  String get boardCreated => 'Communauté créée avec succès !';

  @override
  String get boardDestroyed => 'Cette communauté a été détruite.';

  @override
  String get boardEmpty =>
      'Aucune publication pour le moment. Soyez le premier à écrire !';

  @override
  String get boardWritePost => 'Écrire une Publication';

  @override
  String get problemTitle => 'Vos conversations durent trop longtemps.';

  @override
  String get problemDescription =>
      'Journaux serveur, captures d\'écran, discussions de groupe oubliées...\nToutes les conversations n\'ont pas besoin d\'être enregistrées. Certaines devraient disparaître comme de la fumée.';

  @override
  String get solutionFrictionTitle => '0 Friction';

  @override
  String get solutionFrictionDesc =>
      'Zéro configuration. Envoyez un lien, commencez à parler.';

  @override
  String get solutionAnonymityTitle => 'Total Anonymity';

  @override
  String get solutionAnonymityDesc =>
      'Nous ne demandons pas qui vous êtes. Pas d\'identifiant, pas de profil nécessaire.';

  @override
  String get solutionDestructionTitle => 'Complete Destruction';

  @override
  String get solutionDestructionDesc =>
      'À part vous et le destinataire, même nous ne pouvons pas le voir.';

  @override
  String get solutionAutoshredTitle => 'Auto-Shred';

  @override
  String get solutionAutoshredDesc =>
      'Seuls les derniers messages restent à l\'écran. Les anciens sont détruits en temps réel — pas de défilement, pas de contexte.';

  @override
  String get solutionCaptureGuardTitle => 'Capture Guard';

  @override
  String get solutionCaptureGuardDesc =>
      'Les tentatives de capture d\'écran et d\'enregistrement sont détectées. Les messages sont floutés instantanément — rien à capturer.';

  @override
  String get solutionOpensourceTitle => 'Transparent Code';

  @override
  String get solutionOpensourceDesc =>
      '100% Open Source. Vous pouvez vérifier avec le code que nous n\'espionnons jamais vos conversations.';

  @override
  String get communityLabel => 'NOUVEAU';

  @override
  String get communityTitle => 'Créez votre communauté privée. Chiffrée.';

  @override
  String get communitySubtitle =>
      'Créez une communauté privée avec un seul mot de passe.\nLes publications sont stockées en texte chiffré illisible — le serveur ne peut jamais voir votre contenu.\nMarkdown, images, publication anonyme. Tout chiffré de bout en bout.';

  @override
  String get communityCta => 'Créer une Communauté Privée';

  @override
  String get communityPasswordTitle => 'Mot de passe = Clé';

  @override
  String get communityPasswordDesc =>
      'Un mot de passe partagé chiffre tout. Pas de compte, pas d\'inscription. Partagez le mot de passe, partagez l\'espace.';

  @override
  String get communityServerBlindTitle => 'Serveur Aveugle';

  @override
  String get communityServerBlindDesc =>
      'Nous stockons vos publications, mais ne pouvons jamais les lire. La clé de déchiffrement ne quitte jamais votre appareil.';

  @override
  String get communityModerationTitle => 'Modération Communautaire';

  @override
  String get communityModerationDesc =>
      'Système de signalement avec masquage automatique. Aucun admin n\'a besoin de lire le contenu pour garder l\'espace sûr.';

  @override
  String get philosophyText1 =>
      'BLIP n\'est pas une messagerie. C\'est un outil de communication jetable.';

  @override
  String get philosophyText2 =>
      'Nous ne voulons pas vous retenir. Dites ce que vous avez à dire, puis partez.';

  @override
  String get footerEasterEgg =>
      'Cette page pourrait aussi disparaître bientôt.';

  @override
  String get footerSupportProtocol => 'Soutenir le Protocole';

  @override
  String get footerCopyright => '© 2026 BLIP PROTOCOL';

  @override
  String get footerNoRights => 'NO RIGHTS RESERVED';

  @override
  String get navHome => 'Accueil';

  @override
  String get navChat => 'Chat';

  @override
  String get navCommunity => 'Communauté';

  @override
  String get chatListTitle => 'Mes Salons de Chat';

  @override
  String get chatListEmpty =>
      'Aucun salon de chat.\nCréez un salon depuis l\'onglet Accueil.';

  @override
  String get chatListCreateNew => 'Créer un Nouveau Salon';

  @override
  String get chatListJoinById => 'Rejoindre par ID de salle';

  @override
  String get chatListJoinDialogTitle => 'Rejoindre un salon';

  @override
  String get chatListJoinDialogHint => 'ID de salle ou lien';

  @override
  String get chatListJoinDialogJoin => 'Rejoindre';

  @override
  String get chatListStatusActive => 'Actif';

  @override
  String get chatListStatusDestroyed => 'Détruit';

  @override
  String get chatListStatusExpired => 'Expiré';

  @override
  String get communityListTitle => 'Mes Communautés';

  @override
  String get communityListEmpty => 'Vous n\'avez rejoint aucune communauté.';

  @override
  String get communityListCreate => 'Créer';

  @override
  String get communityListJoinById => 'Rejoindre par ID';

  @override
  String get communityListJoinDialogTitle => 'Rejoindre une Communauté';

  @override
  String get communityListJoinDialogHint => 'Entrez le Board ID';

  @override
  String get communityListJoinDialogJoin => 'Rejoindre';

  @override
  String get communityListJoinedAt => 'Rejoint :';

  @override
  String get contactButton => 'Contacter';

  @override
  String get contactConfirmTitle => 'Envoyer une notification ?';

  @override
  String get contactConfirmMessage =>
      'Une notification push sera envoyée à l\'autre personne. Aucun contenu de chat ne sera partagé.';

  @override
  String get contactSent => 'Notification envoyée';

  @override
  String get contactNotReady =>
      'La notification push n\'est pas encore disponible';

  @override
  String get cancel => 'Annuler';

  @override
  String get confirm => 'OK';

  @override
  String get boardRefresh => 'Actualiser';

  @override
  String get boardAdminPanel => 'Panneau d\'administration';

  @override
  String get boardAdminRegister => 'Enregistrer le jeton admin';

  @override
  String get boardAdminTokenPlaceholder => 'Entrez le jeton admin...';

  @override
  String get boardAdminConfirmRegister => 'Enregistrer';

  @override
  String get boardAdminForgetToken => 'Supprimer le jeton admin';
}
