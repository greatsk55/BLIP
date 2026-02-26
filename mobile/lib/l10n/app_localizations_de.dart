// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get heroTitle => 'Reden. Dann verschwinden.';

  @override
  String get heroSubtitle =>
      'Keine Konten. Keine Spuren. Keine Chatverläufe.\nNur das Gespräch dieses Augenblicks existiert.';

  @override
  String get heroCta => 'Chatraum erstellen';

  @override
  String get heroLinkShare =>
      'Verbinde dich mühelos mit einem einzigen Link, ohne komplizierte Schritte.';

  @override
  String get heroRateLimited =>
      'Raum-Erstellungslimit erreicht. Bitte versuche es später erneut.';

  @override
  String get heroCreateFailed =>
      'Raum konnte nicht erstellt werden. Bitte versuche es erneut.';

  @override
  String get chatHeaderExit => 'VERLASSEN';

  @override
  String chatHeaderOnline(int count) {
    return '$count online';
  }

  @override
  String get chatHeaderE2ee => 'Ende-zu-Ende-verschlüsselt';

  @override
  String get chatInputPlaceholder => 'Nachricht eingeben...';

  @override
  String get chatInputSend => 'Senden';

  @override
  String get chatCreateTitle => 'KANAL ERSTELLT';

  @override
  String get chatCreatePassword => 'ZUGANGSSCHLÜSSEL';

  @override
  String get chatCreateShareLink => 'Link teilen';

  @override
  String get chatCreateWarning =>
      'SPEICHERE DIESEN SCHLÜSSEL. ER KANN NICHT WIEDERHERGESTELLT WERDEN.';

  @override
  String get chatCreateEnter => 'KANAL BETRETEN';

  @override
  String get chatJoinTitle => 'ZUGANGSSCHLÜSSEL EINGEBEN';

  @override
  String get chatJoinConnect => 'VERBINDEN';

  @override
  String get chatJoinInvalidKey => 'UNGÜLTIGER_SCHLÜSSEL';

  @override
  String get chatJoinExpired => 'KANAL_ABGELAUFEN';

  @override
  String get chatJoinFull => 'KANAL_VOLL';

  @override
  String get chatLeaveTitle => 'KANAL VERLASSEN?';

  @override
  String get chatLeaveDescription => 'Möchtest du wirklich gehen?';

  @override
  String get chatLeaveLastPersonWarning =>
      'Du bist der letzte Teilnehmer. Wenn du gehst, wird dieser Kanal unwiderruflich zerstört.';

  @override
  String get chatLeaveConfirm => 'VERLASSEN';

  @override
  String get chatLeaveCancel => 'ABBRECHEN';

  @override
  String get chatDestroyedTitle => 'Keine Spur bleibt zurück.';

  @override
  String get chatDestroyedSubtitle =>
      'Dieser Kanal wurde unwiderruflich zerstört.';

  @override
  String get chatDestroyedNewChat => 'Neuen Kanal starten';

  @override
  String get chatRoomFullTitle => 'Kanal ist voll.';

  @override
  String get chatRoomFullSubtitle => 'Dieser Kanal hat bereits 2 Teilnehmer.';

  @override
  String get chatRoomFullNewChat => 'Neuen Kanal starten';

  @override
  String get chatMediaAttachFile => 'Medien anhängen';

  @override
  String chatMediaFileTooLarge(String maxSize) {
    return 'Datei überschreitet die maximale Größe ($maxSize)';
  }

  @override
  String get chatMediaSendingFile => 'Datei wird gesendet...';

  @override
  String get chatMediaP2pConnecting =>
      'Sichere P2P-Verbindung wird aufgebaut...';

  @override
  String get chatMediaP2pFailed =>
      'P2P-Verbindung fehlgeschlagen. Nur Text möglich.';

  @override
  String get chatMediaP2pConnected => 'P2P-Medienkanal bereit';

  @override
  String get chatMediaVideoLoadFailed => 'Video konnte nicht geladen werden';

  @override
  String get chatMediaUnsupportedType => 'Nicht unterstützter Dateityp';

  @override
  String get boardCreateTitle => 'COMMUNITY ERSTELLT';

  @override
  String get boardCreateSubtitle => 'Private Community erstellen';

  @override
  String get boardCreateButton => 'Community erstellen';

  @override
  String get boardCreateNamePlaceholder => 'Community-Name';

  @override
  String get boardCreatePassword => 'Community-Passwort';

  @override
  String get boardCreateAdminToken => 'Admin-Token';

  @override
  String get boardCreateAdminTokenWarning =>
      'Speichere dieses Token — es kann nicht wiederhergestellt werden';

  @override
  String get boardCreateShareLink => 'Link teilen';

  @override
  String get boardCreateEnter => 'Community betreten';

  @override
  String get boardHeaderEncrypted => 'E2E-verschlüsselt';

  @override
  String get boardHeaderAdmin => 'Admin-Bereich';

  @override
  String get boardHeaderForgetPassword => 'Gespeichertes Passwort vergessen';

  @override
  String get boardHeaderForgetPasswordConfirm =>
      'Das gespeicherte Passwort auf diesem Gerät wird gelöscht. Beim nächsten Besuch musst du das Passwort erneut eingeben.';

  @override
  String get boardHeaderCancel => 'Abbrechen';

  @override
  String get boardHeaderConfirmForget => 'Löschen';

  @override
  String get boardHeaderRegisterAdmin => 'Admin-Token registrieren';

  @override
  String get boardHeaderAdminTokenPlaceholder => 'Admin-Token hier einfügen';

  @override
  String get boardHeaderConfirmRegister => 'Registrieren';

  @override
  String get boardPostPlaceholder =>
      'Schreib etwas... (Markdown wird unterstützt)';

  @override
  String get boardPostSubmit => 'Posten';

  @override
  String get boardPostCompose => 'Neuer Beitrag';

  @override
  String get boardPostDetail => 'Beitrag';

  @override
  String get boardPostEmpty => 'Noch keine Beiträge';

  @override
  String get boardPostWriteFirst => 'Schreibe den ersten Beitrag';

  @override
  String get boardPostRefresh => 'Aktualisieren';

  @override
  String get boardPostAttachImage => 'Bild anhängen';

  @override
  String get boardPostMaxImages => 'Max. 4 Bilder';

  @override
  String get boardPostImageTooLarge => 'Bild zu groß';

  @override
  String get boardPostUploading => 'Wird hochgeladen...';

  @override
  String get boardPostAttachMedia => 'Medien anhängen';

  @override
  String boardPostMaxMedia(int count) {
    return 'Max. $count Dateien';
  }

  @override
  String boardPostVideoTooLong(int seconds) {
    return 'Video zu lang (max. $seconds s)';
  }

  @override
  String get boardPostVideoTooLarge => 'Video nach Komprimierung zu groß';

  @override
  String get boardPostCompressing => 'Wird komprimiert...';

  @override
  String get boardPostTitlePlaceholder => 'Titel (optional)';

  @override
  String get boardPostInsertInline => 'In Inhalt einfügen';

  @override
  String get boardPostEdit => 'Bearbeiten';

  @override
  String get boardPostEditTitle => 'Beitrag bearbeiten';

  @override
  String get boardPostSave => 'Speichern';

  @override
  String get boardPostDelete => 'Löschen';

  @override
  String get boardPostAdminDelete => 'Löschen (Admin)';

  @override
  String get boardPostDeleteWarning =>
      'Dieser Beitrag wird unwiderruflich gelöscht. Dies kann nicht rückgängig gemacht werden.';

  @override
  String get boardPostConfirmDelete => 'Löschen';

  @override
  String get boardReportTitle => 'Beitrag melden';

  @override
  String get boardReportSpam => 'Spam';

  @override
  String get boardReportAbuse => 'Beleidigung / Belästigung';

  @override
  String get boardReportIllegal => 'Illegale Inhalte';

  @override
  String get boardReportOther => 'Sonstiges';

  @override
  String get boardReportSubmit => 'Melden';

  @override
  String get boardReportCancel => 'Abbrechen';

  @override
  String get boardReportAlreadyReported => 'Bereits gemeldet';

  @override
  String get boardBlindedMessage =>
      'Von der Community gemeldet und ausgeblendet';

  @override
  String get boardAdminTitle => 'Admin-Bereich';

  @override
  String get boardAdminDestroy => 'Community zerstören';

  @override
  String get boardAdminDestroyWarning =>
      'Die Community und alle Beiträge werden unwiderruflich gelöscht. Dies kann nicht rückgängig gemacht werden.';

  @override
  String get boardAdminCancel => 'Abbrechen';

  @override
  String get boardAdminConfirmDestroy => 'Zerstören';

  @override
  String get boardDestroyedTitle => 'Community zerstört';

  @override
  String get boardDestroyedMessage =>
      'Diese Community wurde unwiderruflich gelöscht.';

  @override
  String get commonSettings => 'Einstellungen';

  @override
  String get commonTheme => 'Design';

  @override
  String get commonLanguage => 'Sprache';

  @override
  String get commonCopy => 'Kopieren';

  @override
  String get commonShare => 'Teilen';

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonConfirm => 'Bestätigen';

  @override
  String get commonLoading => 'Wird geladen...';

  @override
  String get commonError => 'Ein Fehler ist aufgetreten';

  @override
  String get commonRetry => 'Erneut versuchen';

  @override
  String get commonClose => 'Schließen';

  @override
  String get commonBack => 'Zurück';

  @override
  String get commonDone => 'Fertig';

  @override
  String get commonDelete => 'Löschen';

  @override
  String get commonSave => 'Speichern';

  @override
  String get commonCopied => 'In die Zwischenablage kopiert';

  @override
  String get heroBoardCta => 'Community-Board';

  @override
  String get featureZeroFriction => 'Null Aufwand';

  @override
  String get featureZeroFrictionDesc =>
      'Verbinde dich mühelos mit einem einzigen Link, ohne komplizierte Schritte.';

  @override
  String get featureAnonymity => 'Vollständige Anonymität';

  @override
  String get featureAnonymityDesc =>
      'Keine Konten, keine Profile. Nur das Gespräch zählt.';

  @override
  String get featureDestruction => 'Automatische Zerstörung';

  @override
  String get featureDestructionDesc =>
      'Wenn alle gehen, verschwinden alle Spuren für immer.';

  @override
  String get errorRateLimit =>
      'Zu viele Anfragen. Bitte versuche es später erneut.';

  @override
  String get errorGeneric => 'Ein Fehler ist aufgetreten.';

  @override
  String get chatConnected =>
      'Ende-zu-Ende-verschlüsselte Verbindung hergestellt';

  @override
  String get chatPasswordTitle => 'Zugangsschlüssel eingeben';

  @override
  String get chatPasswordSubtitle =>
      'Teile den Zugangsschlüssel mit deinem Gesprächspartner';

  @override
  String get chatPasswordJoin => 'Beitreten';

  @override
  String get chatPasswordInvalid => 'Ungültiger Zugangsschlüssel';

  @override
  String get chatRoomNotFound => 'Raum nicht gefunden';

  @override
  String get chatRoomDestroyed => 'Raum wurde zerstört';

  @override
  String get chatExpired => 'Raum ist abgelaufen';

  @override
  String get chatRoomFull => 'Raum ist voll';

  @override
  String get chatCreatedTitle => 'KANAL ERSTELLT';

  @override
  String get chatCreatedWarning =>
      'SPEICHERN SIE DIESEN SCHLÜSSEL. ER KANN NICHT WIEDERHERGESTELLT WERDEN.';

  @override
  String get chatAccessKey => 'ZUGANGSSCHLÜSSEL';

  @override
  String get chatShareLink => 'LINK TEILEN';

  @override
  String get chatPeerConnected => 'PARTNER VERBUNDEN';

  @override
  String chatShareMessage(String link, String password) {
    return 'Tritt meinem BLIP-Chat bei!\n\n$link\nPasswort: $password';
  }

  @override
  String get chatIncludeKey => 'Passwort im Link einbetten';

  @override
  String get chatIncludeKeyWarning =>
      'Jeder mit diesem Link kann ohne Passworteingabe beitreten';

  @override
  String chatShareMessageLinkOnly(String link) {
    return 'Tritt meinem BLIP-Chat bei!\n\n$link';
  }

  @override
  String get chatWaitingPeer => 'Warte auf einen Teilnehmer...';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsTheme => 'Design';

  @override
  String get settingsThemeDark => 'Dunkler Modus';

  @override
  String get settingsThemeLight => 'Heller Modus';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get settingsAbout => 'Über';

  @override
  String get boardTitle => 'Community-Board';

  @override
  String get boardCreated => 'Community erfolgreich erstellt!';

  @override
  String get boardDestroyed => 'Diese Community wurde zerstört.';

  @override
  String get boardEmpty => 'Noch keine Beiträge. Schreibe den ersten!';

  @override
  String get boardWritePost => 'Beitrag schreiben';

  @override
  String get problemTitle => 'Deine Gespräche dauern zu lange.';

  @override
  String get problemDescription =>
      'Server-Logs, Screenshots, vergessene Gruppenchats...\nNicht jedes Gespräch braucht eine Aufzeichnung. Manche sollten sich wie Rauch auflösen.';

  @override
  String get solutionFrictionTitle => '0 Aufwand';

  @override
  String get solutionFrictionDesc =>
      'Keine Einrichtung. Link senden, losreden.';

  @override
  String get solutionAnonymityTitle => 'Totale Anonymität';

  @override
  String get solutionAnonymityDesc =>
      'Wir fragen nicht, wer du bist. Keine ID, kein Profil nötig.';

  @override
  String get solutionDestructionTitle => 'Vollständige Zerstörung';

  @override
  String get solutionDestructionDesc =>
      'Außer dir und dem Empfänger kann niemand mitlesen — nicht einmal wir.';

  @override
  String get solutionAutoshredTitle => 'Automatisches Schreddern';

  @override
  String get solutionAutoshredDesc =>
      'Nur die letzten Nachrichten bleiben sichtbar. Ältere werden in Echtzeit zerstört — kein Zurückscrollen, kein Kontext.';

  @override
  String get solutionCaptureGuardTitle => 'Aufnahme-Schutz';

  @override
  String get solutionCaptureGuardDesc =>
      'Screenshot- und Bildschirmaufnahme-Versuche werden erkannt. Nachrichten verschwimmen sofort — nichts zu erfassen.';

  @override
  String get solutionOpensourceTitle => 'Transparenter Code';

  @override
  String get solutionOpensourceDesc =>
      '100 % Open Source. Du kannst im Code nachprüfen, dass wir deine Gespräche niemals ausspionieren.';

  @override
  String get communityLabel => 'NEU';

  @override
  String get communityTitle =>
      'Baue deine eigene private Community. Verschlüsselt.';

  @override
  String get communitySubtitle =>
      'Erstelle eine private Community mit einem einzigen Passwort.\nBeiträge werden als unlesbarer Chiffretext gespeichert — der Server kann deine Inhalte niemals lesen.\nMarkdown, Bilder, anonymes Posten. Alles Ende-zu-Ende-verschlüsselt.';

  @override
  String get communityCta => 'Private Community erstellen';

  @override
  String get communityPasswordTitle => 'Passwort = Schlüssel';

  @override
  String get communityPasswordDesc =>
      'Ein gemeinsames Passwort verschlüsselt alles. Keine Konten, keine Anmeldung. Teile das Passwort, teile den Raum.';

  @override
  String get communityServerBlindTitle => 'Server-Blind';

  @override
  String get communityServerBlindDesc =>
      'Wir speichern deine Beiträge, aber wir können sie niemals lesen. Der Entschlüsselungsschlüssel verlässt nie dein Gerät.';

  @override
  String get communityModerationTitle => 'Community-Moderation';

  @override
  String get communityModerationDesc =>
      'Meldesystem mit automatischer Ausblendung. Kein Admin muss Inhalte lesen, um den Raum sicher zu halten.';

  @override
  String get philosophyText1 =>
      'BLIP ist kein Messenger. Es ist ein Einweg-Kommunikationstool.';

  @override
  String get philosophyText2 =>
      'Wir wollen dich nicht hier behalten. Sag, was du zu sagen hast, und geh.';

  @override
  String get footerEasterEgg => 'Diese Seite könnte auch bald verschwinden.';

  @override
  String get footerSupportProtocol => 'Das Protokoll unterstützen';

  @override
  String get footerCopyright => '© 2026 BLIP PROTOCOL';

  @override
  String get footerNoRights => 'KEINE RECHTE VORBEHALTEN';

  @override
  String get navHome => 'Startseite';

  @override
  String get navChat => 'Chat';

  @override
  String get navCommunity => 'Community';

  @override
  String get chatListTitle => 'Meine Chaträume';

  @override
  String get chatListEmpty =>
      'Noch keine Chaträume.\nErstelle einen Raum über den Startseite-Tab.';

  @override
  String get chatListCreateNew => 'Neuen Raum erstellen';

  @override
  String get chatListJoinById => 'Per Raum-ID beitreten';

  @override
  String get chatListJoinDialogTitle => 'Chatraum beitreten';

  @override
  String get chatListJoinDialogHint => 'Raum-ID oder Link';

  @override
  String get chatListJoinDialogJoin => 'Beitreten';

  @override
  String get chatListStatusActive => 'Aktiv';

  @override
  String get chatListStatusDestroyed => 'Zerstört';

  @override
  String get chatListStatusExpired => 'Abgelaufen';

  @override
  String get communityListTitle => 'Meine Communities';

  @override
  String get communityListEmpty => 'Noch keiner Community beigetreten.';

  @override
  String get communityListCreate => 'Neu erstellen';

  @override
  String get communityListJoinById => 'Per ID beitreten';

  @override
  String get communityListJoinDialogTitle => 'Community beitreten';

  @override
  String get communityListJoinDialogHint => 'Board-ID eingeben';

  @override
  String get communityListJoinDialogJoin => 'Beitreten';

  @override
  String get communityListJoinedAt => 'Beigetreten:';

  @override
  String get contactButton => 'Kontakt';

  @override
  String get contactConfirmTitle => 'Benachrichtigung senden?';

  @override
  String get contactConfirmMessage =>
      'Eine Push-Benachrichtigung wird an die andere Person gesendet. Keine Chatinhalte werden geteilt.';

  @override
  String get contactSent => 'Benachrichtigung gesendet';

  @override
  String get contactNotReady =>
      'Push-Benachrichtigung ist noch nicht verfügbar';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get confirm => 'OK';

  @override
  String get boardRefresh => 'Aktualisieren';

  @override
  String get boardAdminPanel => 'Admin-Bereich';

  @override
  String get boardAdminRegister => 'Admin-Token registrieren';

  @override
  String get boardAdminTokenPlaceholder => 'Admin-Token eingeben...';

  @override
  String get boardAdminConfirmRegister => 'Registrieren';

  @override
  String get boardAdminForgetToken => 'Admin-Token entfernen';

  @override
  String get boardAdminEditSubtitle => 'Untertitel bearbeiten';

  @override
  String get boardAdminSubtitlePlaceholder => 'Community-Untertitel (optional)';

  @override
  String get boardAdminSubtitleSave => 'Speichern';

  @override
  String get boardCreateSubtitlePlaceholder => 'Untertitel (optional)';

  @override
  String get termsAgree => 'Ich stimme den Nutzungsbedingungen zu';

  @override
  String get termsAgreeLink => 'Nutzungsbedingungen';

  @override
  String get termsMustAgree =>
      'Sie müssen den Nutzungsbedingungen zustimmen, um fortzufahren.';

  @override
  String get termsViewInChat => 'AGB';

  @override
  String get termsTitle => 'Nutzungsbedingungen';

  @override
  String get termsLastUpdated => 'Zuletzt aktualisiert: Februar 2026';

  @override
  String get termsIntro =>
      'Durch die Nutzung von BLIP stimmst du diesen Bedingungen zu. Sie sind kurz, ehrlich und in einfacher Sprache geschrieben — genau wie unser Code.';

  @override
  String get termsSection1Title => 'Was ist BLIP';

  @override
  String get termsSection1Content =>
      'BLIP ist ein kostenloser, quelloffener, Ende-zu-Ende verschlüsselter ephemerer Chat-Service. Er bietet temporäre Kommunikationskanäle, die nach der Nutzung zerstört werden.';

  @override
  String get termsSection2Title => 'Kein Konto erforderlich';

  @override
  String get termsSection2Content =>
      'BLIP funktioniert ohne Registrierung, Anmeldedaten oder persönliche Profile. Der Zugang erfolgt über temporäre Raumlinks und gemeinsame Passwörter.';

  @override
  String get termsSection3Title => 'Akzeptable Nutzung';

  @override
  String get termsSection3Content =>
      'Du stimmst zu, BLIP nicht für folgendes zu nutzen: Verbreitung illegaler Inhalte, Belästigung, Malware-Übertragung, automatisierten Spam oder gesetzeswidrige Aktivitäten.';

  @override
  String get termsSection4Title => 'Keine Datenwiederherstellung';

  @override
  String get termsSection4Content =>
      'Nachrichten werden in keiner Datenbank gespeichert. Sobald ein Chatraum zerstört wird, sind alle Daten dauerhaft verloren. Dies ist beabsichtigt, keine Einschränkung.';

  @override
  String get termsSection5Title => 'Open Source';

  @override
  String get termsSection5Content =>
      'Der Quellcode von BLIP ist öffentlich verfügbar. Die Transparenz unseres Codes ist unsere stärkste Datenschutzgarantie.';

  @override
  String get termsSection6Title => 'Dienstverfügbarkeit';

  @override
  String get termsSection6Content =>
      'BLIP wird \'wie besehen\' bereitgestellt. Wir garantieren keine Betriebszeit, Verfügbarkeit oder unterbrechungsfreien Dienst.';

  @override
  String get termsSection7Title => 'Haftungsbeschränkung';

  @override
  String get termsSection7Content =>
      'Im gesetzlich zulässigen Rahmen haften BLIP und seine Betreiber nicht für Schäden, die aus der Nutzung des Dienstes entstehen.';

  @override
  String get termsSection8Title => 'Geistiges Eigentum';

  @override
  String get termsSection8Content =>
      'Der Name, das Logo und die Markenzeichen von BLIP sind geschützt. Der Service-Quellcode wird unter einer Open-Source-Lizenz veröffentlicht.';

  @override
  String get termsSection9Title => 'Änderungen und anwendbares Recht';

  @override
  String get termsSection9Content =>
      'Wir behalten uns das Recht vor, diese Bedingungen jederzeit zu ändern. Die fortgesetzte Nutzung von BLIP nach Änderungen gilt als Zustimmung zu den aktualisierten Bedingungen.';
}
