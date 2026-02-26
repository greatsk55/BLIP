// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get heroTitle => 'Talk. Then Vanish.';

  @override
  String get heroSubtitle =>
      'No accounts. No traces. No history.\nOnly the conversation of this moment exists.';

  @override
  String get heroCta => 'Click to Create Chat Room';

  @override
  String get heroLinkShare =>
      'Connect perfectly with a single link, no complex procedures.';

  @override
  String get heroRateLimited =>
      'Room creation limit reached. Please try again later.';

  @override
  String get heroCreateFailed => 'Failed to create room. Please try again.';

  @override
  String get chatHeaderExit => 'EXIT';

  @override
  String chatHeaderOnline(int count) {
    return '$count online';
  }

  @override
  String get chatHeaderE2ee => 'End-to-End Encrypted';

  @override
  String get chatInputPlaceholder => 'Type message...';

  @override
  String get chatInputSend => 'Send';

  @override
  String get chatCreateTitle => 'CHANNEL CREATED';

  @override
  String get chatCreatePassword => 'ACCESS KEY';

  @override
  String get chatCreateShareLink => 'Share link';

  @override
  String get chatCreateWarning => 'SAVE THIS KEY. IT CANNOT BE RECOVERED.';

  @override
  String get chatCreateEnter => 'ENTER CHANNEL';

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
  String get chatLeaveDescription => 'Are you sure you want to leave?';

  @override
  String get chatLeaveLastPersonWarning =>
      'You are the last participant. Leaving will permanently destroy this channel.';

  @override
  String get chatLeaveConfirm => 'EXIT';

  @override
  String get chatLeaveCancel => 'CANCEL';

  @override
  String get chatDestroyedTitle => 'No trace remains.';

  @override
  String get chatDestroyedSubtitle =>
      'This channel has been permanently destroyed.';

  @override
  String get chatDestroyedNewChat => 'Start New Channel';

  @override
  String get chatRoomFullTitle => 'Channel is full.';

  @override
  String get chatRoomFullSubtitle => 'This channel already has 2 participants.';

  @override
  String get chatRoomFullNewChat => 'Start New Channel';

  @override
  String get chatMediaAttachFile => 'Attach media';

  @override
  String chatMediaFileTooLarge(String maxSize) {
    return 'File exceeds maximum size ($maxSize)';
  }

  @override
  String get chatMediaSendingFile => 'Sending file...';

  @override
  String get chatMediaP2pConnecting => 'Establishing secure P2P connection...';

  @override
  String get chatMediaP2pFailed => 'P2P connection failed. Text only.';

  @override
  String get chatMediaP2pConnected => 'P2P media channel ready';

  @override
  String get chatMediaVideoLoadFailed => 'Video failed to load';

  @override
  String get chatMediaUnsupportedType => 'Unsupported file type';

  @override
  String get boardCreateTitle => 'COMMUNITY CREATED';

  @override
  String get boardCreateSubtitle => 'Create Private Community';

  @override
  String get boardCreateButton => 'Create Community';

  @override
  String get boardCreateNamePlaceholder => 'Community name';

  @override
  String get boardCreatePassword => 'Community Password';

  @override
  String get boardCreateAdminToken => 'Admin Token';

  @override
  String get boardCreateAdminTokenWarning =>
      'Save this token — it cannot be recovered';

  @override
  String get boardCreateShareLink => 'Share Link';

  @override
  String get boardCreateEnter => 'Enter Community';

  @override
  String get boardHeaderEncrypted => 'E2E Encrypted';

  @override
  String get boardHeaderAdmin => 'Admin Panel';

  @override
  String get boardHeaderForgetPassword => 'Forget saved password';

  @override
  String get boardHeaderForgetPasswordConfirm =>
      'The saved password on this device will be deleted. You will need to enter the password again on your next visit.';

  @override
  String get boardHeaderCancel => 'Cancel';

  @override
  String get boardHeaderConfirmForget => 'Delete';

  @override
  String get boardHeaderRegisterAdmin => 'Register Admin Token';

  @override
  String get boardHeaderAdminTokenPlaceholder => 'Paste admin token here';

  @override
  String get boardHeaderConfirmRegister => 'Register';

  @override
  String get boardPostPlaceholder => 'Write something... (Markdown supported)';

  @override
  String get boardPostSubmit => 'Post';

  @override
  String get boardPostCompose => 'New Post';

  @override
  String get boardPostDetail => 'Post';

  @override
  String get boardPostEmpty => 'No posts yet';

  @override
  String get boardPostWriteFirst => 'Write the first post';

  @override
  String get boardPostRefresh => 'Refresh';

  @override
  String get boardPostAttachImage => 'Attach image';

  @override
  String get boardPostMaxImages => 'Max 4 images';

  @override
  String get boardPostImageTooLarge => 'Image too large';

  @override
  String get boardPostUploading => 'Uploading...';

  @override
  String get boardPostAttachMedia => 'Attach media';

  @override
  String boardPostMaxMedia(int count) {
    return 'Max $count files';
  }

  @override
  String boardPostVideoTooLong(int seconds) {
    return 'Video too long (max ${seconds}s)';
  }

  @override
  String get boardPostVideoTooLarge => 'Video too large after compression';

  @override
  String get boardPostCompressing => 'Compressing...';

  @override
  String get boardPostTitlePlaceholder => 'Title (optional)';

  @override
  String get boardPostInsertInline => 'Insert in content';

  @override
  String get boardPostEdit => 'Edit';

  @override
  String get boardPostEditTitle => 'Edit Post';

  @override
  String get boardPostSave => 'Save';

  @override
  String get boardPostDelete => 'Delete';

  @override
  String get boardPostAdminDelete => 'Delete (Admin)';

  @override
  String get boardPostDeleteWarning =>
      'This post will be permanently deleted. This cannot be undone.';

  @override
  String get boardPostConfirmDelete => 'Delete';

  @override
  String get boardReportTitle => 'Report Post';

  @override
  String get boardReportSpam => 'Spam';

  @override
  String get boardReportAbuse => 'Abuse / Harassment';

  @override
  String get boardReportIllegal => 'Illegal Content';

  @override
  String get boardReportOther => 'Other';

  @override
  String get boardReportSubmit => 'Report';

  @override
  String get boardReportCancel => 'Cancel';

  @override
  String get boardReportAlreadyReported => 'Already reported';

  @override
  String get boardBlindedMessage => 'Blinded by community reports';

  @override
  String get boardAdminTitle => 'Admin Panel';

  @override
  String get boardAdminDestroy => 'Destroy Community';

  @override
  String get boardAdminDestroyWarning =>
      'This will permanently delete the community and all posts. This cannot be undone.';

  @override
  String get boardAdminCancel => 'Cancel';

  @override
  String get boardAdminConfirmDestroy => 'Destroy';

  @override
  String get boardDestroyedTitle => 'Community Destroyed';

  @override
  String get boardDestroyedMessage =>
      'This community has been permanently deleted.';

  @override
  String get commonSettings => 'Settings';

  @override
  String get commonTheme => 'Theme';

  @override
  String get commonLanguage => 'Language';

  @override
  String get commonCopy => 'Copy';

  @override
  String get commonShare => 'Share';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get commonError => 'An error occurred';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonClose => 'Close';

  @override
  String get commonBack => 'Back';

  @override
  String get commonDone => 'Done';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonSave => 'Save';

  @override
  String get commonCopied => 'Copied to clipboard';

  @override
  String get heroBoardCta => 'Community Board';

  @override
  String get featureZeroFriction => 'Zero Friction';

  @override
  String get featureZeroFrictionDesc =>
      'Connect perfectly with a single link, no complex procedures.';

  @override
  String get featureAnonymity => 'Complete Anonymity';

  @override
  String get featureAnonymityDesc =>
      'No accounts, no profiles. Only the conversation matters.';

  @override
  String get featureDestruction => 'Auto Destruction';

  @override
  String get featureDestructionDesc =>
      'When everyone leaves, all traces disappear permanently.';

  @override
  String get errorRateLimit => 'Too many requests. Please try again later.';

  @override
  String get errorGeneric => 'An error occurred.';

  @override
  String get chatConnected => 'End-to-end encrypted connection established';

  @override
  String get chatPasswordTitle => 'Enter Access Key';

  @override
  String get chatPasswordSubtitle =>
      'Share the access key with your conversation partner';

  @override
  String get chatPasswordJoin => 'Join';

  @override
  String get chatPasswordInvalid => 'Invalid access key';

  @override
  String get chatRoomNotFound => 'Room not found';

  @override
  String get chatRoomDestroyed => 'Room has been destroyed';

  @override
  String get chatExpired => 'Room has expired';

  @override
  String get chatRoomFull => 'Room is full';

  @override
  String get chatCreatedTitle => 'CHANNEL CREATED';

  @override
  String get chatCreatedWarning => 'SAVE THIS KEY. IT CANNOT BE RECOVERED.';

  @override
  String get chatAccessKey => 'ACCESS KEY';

  @override
  String get chatShareLink => 'SHARE LINK';

  @override
  String get chatPeerConnected => 'PEER CONNECTED';

  @override
  String chatShareMessage(String link, String password) {
    return 'Join my BLIP chat!\n\n$link\nPassword: $password';
  }

  @override
  String get chatIncludeKey => 'Include password in link';

  @override
  String get chatIncludeKeyWarning =>
      'Anyone with this link can join without entering a password';

  @override
  String chatShareMessageLinkOnly(String link) {
    return 'Join my BLIP chat!\n\n$link';
  }

  @override
  String get chatWaitingPeer => 'Waiting for someone to join...';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeDark => 'Dark Mode';

  @override
  String get settingsThemeLight => 'Light Mode';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsAbout => 'About';

  @override
  String get boardTitle => 'Community Board';

  @override
  String get boardCreated => 'Community created successfully!';

  @override
  String get boardDestroyed => 'This community has been destroyed.';

  @override
  String get boardEmpty => 'No posts yet. Be the first to write!';

  @override
  String get boardWritePost => 'Write Post';

  @override
  String get problemTitle => 'Your conversations last too long.';

  @override
  String get problemDescription =>
      'Server logs, screenshots, forgotten group chats...\nNot every conversation needs a record. Some should vanish like smoke.';

  @override
  String get solutionFrictionTitle => '0 Friction';

  @override
  String get solutionFrictionDesc => 'Zero setup. Send a link, start talking.';

  @override
  String get solutionAnonymityTitle => 'Total Anonymity';

  @override
  String get solutionAnonymityDesc =>
      'We don\'t ask who you are. No ID, no profile needed.';

  @override
  String get solutionDestructionTitle => 'Complete Destruction';

  @override
  String get solutionDestructionDesc =>
      'Except for you and the recipient, even we cannot see it.';

  @override
  String get solutionAutoshredTitle => 'Auto-Shred';

  @override
  String get solutionAutoshredDesc =>
      'Only the last few messages stay on screen. Older ones are destroyed in real time — no scrollback, no context.';

  @override
  String get solutionCaptureGuardTitle => 'Capture Guard';

  @override
  String get solutionCaptureGuardDesc =>
      'Screenshot and screen-recording attempts are detected. Messages blur instantly — nothing to capture.';

  @override
  String get solutionOpensourceTitle => 'Transparent Code';

  @override
  String get solutionOpensourceDesc =>
      '100% Open Source. You can verify with the code that we never spy on your conversations.';

  @override
  String get communityLabel => 'NEW';

  @override
  String get communityTitle => 'Build your own private community. Encrypted.';

  @override
  String get communitySubtitle =>
      'Create a private community with a single password.\nPosts are stored as unreadable ciphertext — the server can never see your content.\nMarkdown, images, anonymous posting. All end-to-end encrypted.';

  @override
  String get communityCta => 'Create Private Community';

  @override
  String get communityPasswordTitle => 'Password = Key';

  @override
  String get communityPasswordDesc =>
      'One shared password encrypts everything. No accounts, no sign-ups. Share the password, share the space.';

  @override
  String get communityServerBlindTitle => 'Server-Blind';

  @override
  String get communityServerBlindDesc =>
      'We store your posts, but we can never read them. The decryption key never leaves your device.';

  @override
  String get communityModerationTitle => 'Community-Moderated';

  @override
  String get communityModerationDesc =>
      'Report system with auto-blinding. No admin needs to read content to keep the space safe.';

  @override
  String get philosophyText1 =>
      'BLIP is not a messenger. It\'s a disposable communication tool.';

  @override
  String get philosophyText2 =>
      'We don\'t want to keep you here. Say your piece, then leave.';

  @override
  String get footerEasterEgg => 'This page might disappear soon too.';

  @override
  String get footerSupportProtocol => 'Support the Protocol';

  @override
  String get footerCopyright => '© 2026 BLIP PROTOCOL';

  @override
  String get footerNoRights => 'NO RIGHTS RESERVED';

  @override
  String get navHome => 'Home';

  @override
  String get navChat => 'Chat';

  @override
  String get navCommunity => 'Community';

  @override
  String get chatListTitle => 'My Chat Rooms';

  @override
  String get chatListEmpty =>
      'No chat rooms yet.\nCreate a room from the Home tab.';

  @override
  String get chatListCreateNew => 'Create New Room';

  @override
  String get chatListJoinById => 'Join by Room ID';

  @override
  String get chatListJoinDialogTitle => 'Join Chat Room';

  @override
  String get chatListJoinDialogHint => 'Room ID or link';

  @override
  String get chatListJoinDialogJoin => 'Join';

  @override
  String get chatListStatusActive => 'Active';

  @override
  String get chatListStatusDestroyed => 'Destroyed';

  @override
  String get chatListStatusExpired => 'Expired';

  @override
  String get communityListTitle => 'My Communities';

  @override
  String get communityListEmpty => 'No communities joined yet.';

  @override
  String get communityListCreate => 'Create New';

  @override
  String get communityListJoinById => 'Join by ID';

  @override
  String get communityListJoinDialogTitle => 'Join Community';

  @override
  String get communityListJoinDialogHint => 'Enter Board ID';

  @override
  String get communityListJoinDialogJoin => 'Join';

  @override
  String get communityListJoinedAt => 'Joined:';

  @override
  String get contactButton => 'Contact';

  @override
  String get contactConfirmTitle => 'Send Notification?';

  @override
  String get contactConfirmMessage =>
      'A push notification will be sent to the other person. No chat content will be shared.';

  @override
  String get contactSent => 'Notification sent';

  @override
  String get contactNotReady => 'Push notification is not available yet';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'OK';

  @override
  String get boardRefresh => 'Refresh';

  @override
  String get boardAdminPanel => 'Admin Panel';

  @override
  String get boardAdminRegister => 'Register Admin Token';

  @override
  String get boardAdminTokenPlaceholder => 'Enter admin token...';

  @override
  String get boardAdminConfirmRegister => 'Register';

  @override
  String get boardAdminForgetToken => 'Remove Admin Token';

  @override
  String get boardAdminEditSubtitle => 'Edit Subtitle';

  @override
  String get boardAdminSubtitlePlaceholder => 'Community subtitle (optional)';

  @override
  String get boardAdminSubtitleSave => 'Save';

  @override
  String get boardCreateSubtitlePlaceholder => 'Subtitle (optional)';

  @override
  String get termsAgree => 'I agree to the Terms of Service';

  @override
  String get termsAgreeLink => 'Terms of Service';

  @override
  String get termsMustAgree =>
      'You must agree to the Terms of Service to continue.';

  @override
  String get termsViewInChat => 'Terms';

  @override
  String get termsTitle => 'Terms of Use';

  @override
  String get termsLastUpdated => 'Last updated: February 2026';

  @override
  String get termsIntro =>
      'By using BLIP, you agree to these terms. They\'re short, honest, and written in plain language—just like our code.';

  @override
  String get termsSection1Title => 'What BLIP Is';

  @override
  String get termsSection1Content =>
      'BLIP is a free, open-source, end-to-end encrypted ephemeral chat service. It provides temporary communication channels that are destroyed after use. BLIP is not a messenger, social network, or data storage platform. It\'s a disposable communication tool.';

  @override
  String get termsSection2Title => 'No Accounts Required';

  @override
  String get termsSection2Content =>
      'BLIP operates without user registration, login credentials, or personal profiles. Access is granted through temporary room links and shared passwords. You are responsible for safeguarding your room passwords—we cannot recover them.';

  @override
  String get termsSection3Title => 'Acceptable Use';

  @override
  String get termsSection3Content =>
      'You agree not to use BLIP for: distributing illegal content, harassment or threats, transmission of malware, automated spam or abuse, or any activity that violates applicable law. While we cannot monitor encrypted content, we reserve the right to restrict access to our infrastructure if abuse is detected at the network level.';

  @override
  String get termsSection4Title => 'No Data Recovery';

  @override
  String get termsSection4Content =>
      'Messages are not stored in any database. Once a chat room is destroyed, all conversation data is permanently and irreversibly lost. This is by design, not a limitation. Do not use BLIP for communications that you need to preserve.';

  @override
  String get termsSection5Title => 'Open Source';

  @override
  String get termsSection5Content =>
      'BLIP\'s source code is publicly available. You are free to inspect, fork, and contribute to the codebase. The transparency of our code is our strongest guarantee of privacy. You can verify every claim we make.';

  @override
  String get termsSection6Title => 'Service Availability';

  @override
  String get termsSection6Content =>
      'BLIP is provided on an \'as-is\' basis. We make no guarantees of uptime, availability, or uninterrupted service. We may modify, suspend, or discontinue the service at any time without prior notice.';

  @override
  String get termsSection7Title => 'Limitation of Liability';

  @override
  String get termsSection7Content =>
      'To the maximum extent permitted by law, BLIP and its operators shall not be liable for any direct, indirect, incidental, or consequential damages arising from your use of the service.';

  @override
  String get termsSection8Title => 'Intellectual Property';

  @override
  String get termsSection8Content =>
      'The BLIP name, logo, and brand assets are protected. The service codebase is released under an open-source license. User-generated content in chat rooms belongs to the users—though by design, it ceases to exist after the room is destroyed.';

  @override
  String get termsSection9Title => 'Changes & Governing Law';

  @override
  String get termsSection9Content =>
      'We reserve the right to modify these terms at any time. Continued use of BLIP after changes constitutes acceptance of the updated terms. These terms are governed by the laws of the Republic of Korea.';
}
