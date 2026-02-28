import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
    Locale('zh', 'TW'),
  ];

  /// Main hero title
  ///
  /// In en, this message translates to:
  /// **'Talk. Then Vanish.'**
  String get heroTitle;

  /// Hero subtitle
  ///
  /// In en, this message translates to:
  /// **'No accounts. No traces. No history.\nOnly the conversation of this moment exists.'**
  String get heroSubtitle;

  /// Hero call-to-action button
  ///
  /// In en, this message translates to:
  /// **'Click to Create Chat Room'**
  String get heroCta;

  /// Link share description
  ///
  /// In en, this message translates to:
  /// **'Connect perfectly with a single link, no complex procedures.'**
  String get heroLinkShare;

  /// Rate limit error message
  ///
  /// In en, this message translates to:
  /// **'Room creation limit reached. Please try again later.'**
  String get heroRateLimited;

  /// Room creation failed message
  ///
  /// In en, this message translates to:
  /// **'Failed to create room. Please try again.'**
  String get heroCreateFailed;

  /// Chat exit button
  ///
  /// In en, this message translates to:
  /// **'EXIT'**
  String get chatHeaderExit;

  /// Online user count
  ///
  /// In en, this message translates to:
  /// **'{count} online'**
  String chatHeaderOnline(int count);

  /// E2EE badge text
  ///
  /// In en, this message translates to:
  /// **'End-to-End Encrypted'**
  String get chatHeaderE2ee;

  /// Message input placeholder
  ///
  /// In en, this message translates to:
  /// **'Type message...'**
  String get chatInputPlaceholder;

  /// Send button
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get chatInputSend;

  /// Channel created title
  ///
  /// In en, this message translates to:
  /// **'CHANNEL CREATED'**
  String get chatCreateTitle;

  /// Access key label
  ///
  /// In en, this message translates to:
  /// **'ACCESS KEY'**
  String get chatCreatePassword;

  /// Share link label
  ///
  /// In en, this message translates to:
  /// **'Share link'**
  String get chatCreateShareLink;

  /// Key save warning
  ///
  /// In en, this message translates to:
  /// **'SAVE THIS KEY. IT CANNOT BE RECOVERED.'**
  String get chatCreateWarning;

  /// Enter channel button
  ///
  /// In en, this message translates to:
  /// **'ENTER CHANNEL'**
  String get chatCreateEnter;

  /// Join channel title
  ///
  /// In en, this message translates to:
  /// **'ENTER ACCESS KEY'**
  String get chatJoinTitle;

  /// Connect button
  ///
  /// In en, this message translates to:
  /// **'CONNECT'**
  String get chatJoinConnect;

  /// Invalid key error
  ///
  /// In en, this message translates to:
  /// **'INVALID_KEY'**
  String get chatJoinInvalidKey;

  /// Channel expired error
  ///
  /// In en, this message translates to:
  /// **'CHANNEL_EXPIRED'**
  String get chatJoinExpired;

  /// Channel full error
  ///
  /// In en, this message translates to:
  /// **'CHANNEL_FULL'**
  String get chatJoinFull;

  /// Leave confirmation title
  ///
  /// In en, this message translates to:
  /// **'EXIT CHANNEL?'**
  String get chatLeaveTitle;

  /// Leave confirmation description
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave?'**
  String get chatLeaveDescription;

  /// Last person warning
  ///
  /// In en, this message translates to:
  /// **'You are the last participant. Leaving will permanently destroy this channel.'**
  String get chatLeaveLastPersonWarning;

  /// Confirm leave button
  ///
  /// In en, this message translates to:
  /// **'EXIT'**
  String get chatLeaveConfirm;

  /// Cancel leave button
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get chatLeaveCancel;

  /// Channel destroyed title
  ///
  /// In en, this message translates to:
  /// **'No trace remains.'**
  String get chatDestroyedTitle;

  /// Channel destroyed subtitle
  ///
  /// In en, this message translates to:
  /// **'This channel has been permanently destroyed.'**
  String get chatDestroyedSubtitle;

  /// Start new channel button
  ///
  /// In en, this message translates to:
  /// **'Start New Channel'**
  String get chatDestroyedNewChat;

  /// Room full title
  ///
  /// In en, this message translates to:
  /// **'Channel is full.'**
  String get chatRoomFullTitle;

  /// Room full subtitle
  ///
  /// In en, this message translates to:
  /// **'This channel already has 2 participants.'**
  String get chatRoomFullSubtitle;

  /// Start new channel from full room
  ///
  /// In en, this message translates to:
  /// **'Start New Channel'**
  String get chatRoomFullNewChat;

  /// Attach media button
  ///
  /// In en, this message translates to:
  /// **'Attach media'**
  String get chatMediaAttachFile;

  /// File too large error
  ///
  /// In en, this message translates to:
  /// **'File exceeds maximum size ({maxSize})'**
  String chatMediaFileTooLarge(String maxSize);

  /// File sending status
  ///
  /// In en, this message translates to:
  /// **'Sending file...'**
  String get chatMediaSendingFile;

  /// P2P connecting status
  ///
  /// In en, this message translates to:
  /// **'Establishing secure P2P connection...'**
  String get chatMediaP2pConnecting;

  /// P2P connection failed
  ///
  /// In en, this message translates to:
  /// **'P2P connection failed. Text only.'**
  String get chatMediaP2pFailed;

  /// P2P connected status
  ///
  /// In en, this message translates to:
  /// **'P2P media channel ready'**
  String get chatMediaP2pConnected;

  /// Video load failed
  ///
  /// In en, this message translates to:
  /// **'Video failed to load'**
  String get chatMediaVideoLoadFailed;

  /// Unsupported file type
  ///
  /// In en, this message translates to:
  /// **'Unsupported file type'**
  String get chatMediaUnsupportedType;

  /// Board created title
  ///
  /// In en, this message translates to:
  /// **'COMMUNITY CREATED'**
  String get boardCreateTitle;

  /// Board create subtitle
  ///
  /// In en, this message translates to:
  /// **'Create Private Community'**
  String get boardCreateSubtitle;

  /// Create community button
  ///
  /// In en, this message translates to:
  /// **'Create Community'**
  String get boardCreateButton;

  /// Community name placeholder
  ///
  /// In en, this message translates to:
  /// **'Community name'**
  String get boardCreateNamePlaceholder;

  /// Community password label
  ///
  /// In en, this message translates to:
  /// **'Community Password'**
  String get boardCreatePassword;

  /// Admin token label
  ///
  /// In en, this message translates to:
  /// **'Admin Token'**
  String get boardCreateAdminToken;

  /// Admin token warning
  ///
  /// In en, this message translates to:
  /// **'Save this token — it cannot be recovered'**
  String get boardCreateAdminTokenWarning;

  /// Share link label
  ///
  /// In en, this message translates to:
  /// **'Share Link'**
  String get boardCreateShareLink;

  /// Enter community button
  ///
  /// In en, this message translates to:
  /// **'Enter Community'**
  String get boardCreateEnter;

  /// E2E encrypted badge
  ///
  /// In en, this message translates to:
  /// **'E2E Encrypted'**
  String get boardHeaderEncrypted;

  /// Admin panel button
  ///
  /// In en, this message translates to:
  /// **'Admin Panel'**
  String get boardHeaderAdmin;

  /// Forget password button
  ///
  /// In en, this message translates to:
  /// **'Forget saved password'**
  String get boardHeaderForgetPassword;

  /// Forget password confirmation
  ///
  /// In en, this message translates to:
  /// **'The saved password on this device will be deleted. You will need to enter the password again on your next visit.'**
  String get boardHeaderForgetPasswordConfirm;

  /// Cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get boardHeaderCancel;

  /// Confirm forget button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get boardHeaderConfirmForget;

  /// Register admin token
  ///
  /// In en, this message translates to:
  /// **'Register Admin Token'**
  String get boardHeaderRegisterAdmin;

  /// Admin token placeholder
  ///
  /// In en, this message translates to:
  /// **'Paste admin token here'**
  String get boardHeaderAdminTokenPlaceholder;

  /// Confirm register button
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get boardHeaderConfirmRegister;

  /// Post input placeholder
  ///
  /// In en, this message translates to:
  /// **'Write something... (Markdown supported)'**
  String get boardPostPlaceholder;

  /// Post submit button
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get boardPostSubmit;

  /// New post button
  ///
  /// In en, this message translates to:
  /// **'New Post'**
  String get boardPostCompose;

  /// Post detail title
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get boardPostDetail;

  /// Empty posts message
  ///
  /// In en, this message translates to:
  /// **'No posts yet'**
  String get boardPostEmpty;

  /// Write first post prompt
  ///
  /// In en, this message translates to:
  /// **'Write the first post'**
  String get boardPostWriteFirst;

  /// Refresh button
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get boardPostRefresh;

  /// Attach image button
  ///
  /// In en, this message translates to:
  /// **'Attach image'**
  String get boardPostAttachImage;

  /// Max images notice
  ///
  /// In en, this message translates to:
  /// **'Max 4 images'**
  String get boardPostMaxImages;

  /// Image too large error
  ///
  /// In en, this message translates to:
  /// **'Image too large'**
  String get boardPostImageTooLarge;

  /// Uploading status
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get boardPostUploading;

  /// Attach media button
  ///
  /// In en, this message translates to:
  /// **'Attach media'**
  String get boardPostAttachMedia;

  /// Max media notice
  ///
  /// In en, this message translates to:
  /// **'Max {count} files'**
  String boardPostMaxMedia(int count);

  /// Video too long error
  ///
  /// In en, this message translates to:
  /// **'Video too long (max {seconds}s)'**
  String boardPostVideoTooLong(int seconds);

  /// Video too large error
  ///
  /// In en, this message translates to:
  /// **'Video too large after compression'**
  String get boardPostVideoTooLarge;

  /// Compressing status
  ///
  /// In en, this message translates to:
  /// **'Compressing...'**
  String get boardPostCompressing;

  /// Post title placeholder
  ///
  /// In en, this message translates to:
  /// **'Title (optional)'**
  String get boardPostTitlePlaceholder;

  /// Insert inline button
  ///
  /// In en, this message translates to:
  /// **'Insert in content'**
  String get boardPostInsertInline;

  /// Edit button
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get boardPostEdit;

  /// Edit post title
  ///
  /// In en, this message translates to:
  /// **'Edit Post'**
  String get boardPostEditTitle;

  /// Save button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get boardPostSave;

  /// Delete button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get boardPostDelete;

  /// Admin delete button
  ///
  /// In en, this message translates to:
  /// **'Delete (Admin)'**
  String get boardPostAdminDelete;

  /// Delete warning message
  ///
  /// In en, this message translates to:
  /// **'This post will be permanently deleted. This cannot be undone.'**
  String get boardPostDeleteWarning;

  /// Confirm delete button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get boardPostConfirmDelete;

  /// Report post title
  ///
  /// In en, this message translates to:
  /// **'Report Post'**
  String get boardReportTitle;

  /// Spam report option
  ///
  /// In en, this message translates to:
  /// **'Spam'**
  String get boardReportSpam;

  /// Abuse report option
  ///
  /// In en, this message translates to:
  /// **'Abuse / Harassment'**
  String get boardReportAbuse;

  /// Illegal content report option
  ///
  /// In en, this message translates to:
  /// **'Illegal Content'**
  String get boardReportIllegal;

  /// Other report option
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get boardReportOther;

  /// Report submit button
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get boardReportSubmit;

  /// Report cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get boardReportCancel;

  /// Already reported message
  ///
  /// In en, this message translates to:
  /// **'Already reported'**
  String get boardReportAlreadyReported;

  /// Blinded post message
  ///
  /// In en, this message translates to:
  /// **'Blinded by community reports'**
  String get boardBlindedMessage;

  /// Admin panel title
  ///
  /// In en, this message translates to:
  /// **'Admin Panel'**
  String get boardAdminTitle;

  /// Destroy community button
  ///
  /// In en, this message translates to:
  /// **'Destroy Community'**
  String get boardAdminDestroy;

  /// Destroy warning
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete the community and all posts. This cannot be undone.'**
  String get boardAdminDestroyWarning;

  /// Admin cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get boardAdminCancel;

  /// Confirm destroy button
  ///
  /// In en, this message translates to:
  /// **'Destroy'**
  String get boardAdminConfirmDestroy;

  /// Community destroyed title
  ///
  /// In en, this message translates to:
  /// **'Community Destroyed'**
  String get boardDestroyedTitle;

  /// Community destroyed message
  ///
  /// In en, this message translates to:
  /// **'This community has been permanently deleted.'**
  String get boardDestroyedMessage;

  /// Settings label
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get commonSettings;

  /// Theme label
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get commonTheme;

  /// Language label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get commonLanguage;

  /// Copy action
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get commonCopy;

  /// Share action
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get commonShare;

  /// Cancel action
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// Confirm action
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// Loading indicator
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get commonLoading;

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get commonError;

  /// Retry action
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// Close action
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// Back action
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// Done action
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// Delete action
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// Save action
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// Copied confirmation
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get commonCopied;

  /// Board CTA button on home
  ///
  /// In en, this message translates to:
  /// **'Community Board'**
  String get heroBoardCta;

  /// Feature card title
  ///
  /// In en, this message translates to:
  /// **'Zero Friction'**
  String get featureZeroFriction;

  /// Feature card description
  ///
  /// In en, this message translates to:
  /// **'Connect perfectly with a single link, no complex procedures.'**
  String get featureZeroFrictionDesc;

  /// Feature card title
  ///
  /// In en, this message translates to:
  /// **'Complete Anonymity'**
  String get featureAnonymity;

  /// Feature card description
  ///
  /// In en, this message translates to:
  /// **'No accounts, no profiles. Only the conversation matters.'**
  String get featureAnonymityDesc;

  /// Feature card title
  ///
  /// In en, this message translates to:
  /// **'Auto Destruction'**
  String get featureDestruction;

  /// Feature card description
  ///
  /// In en, this message translates to:
  /// **'When everyone leaves, all traces disappear permanently.'**
  String get featureDestructionDesc;

  /// Rate limit error
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please try again later.'**
  String get errorRateLimit;

  /// Generic error
  ///
  /// In en, this message translates to:
  /// **'An error occurred.'**
  String get errorGeneric;

  /// Chat connected status
  ///
  /// In en, this message translates to:
  /// **'End-to-end encrypted connection established'**
  String get chatConnected;

  /// Password entry title
  ///
  /// In en, this message translates to:
  /// **'Enter Access Key'**
  String get chatPasswordTitle;

  /// Password entry subtitle
  ///
  /// In en, this message translates to:
  /// **'Share the access key with your conversation partner'**
  String get chatPasswordSubtitle;

  /// Join button
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get chatPasswordJoin;

  /// Invalid password error
  ///
  /// In en, this message translates to:
  /// **'Invalid access key'**
  String get chatPasswordInvalid;

  /// Room not found error
  ///
  /// In en, this message translates to:
  /// **'Room not found'**
  String get chatRoomNotFound;

  /// Room destroyed error
  ///
  /// In en, this message translates to:
  /// **'Room has been destroyed'**
  String get chatRoomDestroyed;

  /// Room expired error
  ///
  /// In en, this message translates to:
  /// **'Room has expired'**
  String get chatExpired;

  /// Room full error
  ///
  /// In en, this message translates to:
  /// **'Room is full'**
  String get chatRoomFull;

  /// Room created title
  ///
  /// In en, this message translates to:
  /// **'CHANNEL CREATED'**
  String get chatCreatedTitle;

  /// Warning about saving access key
  ///
  /// In en, this message translates to:
  /// **'SAVE THIS KEY. IT CANNOT BE RECOVERED.'**
  String get chatCreatedWarning;

  /// Access key label
  ///
  /// In en, this message translates to:
  /// **'ACCESS KEY'**
  String get chatAccessKey;

  /// Share link label
  ///
  /// In en, this message translates to:
  /// **'SHARE LINK'**
  String get chatShareLink;

  /// Peer connected status
  ///
  /// In en, this message translates to:
  /// **'PEER CONNECTED'**
  String get chatPeerConnected;

  /// Share message with link
  ///
  /// In en, this message translates to:
  /// **'Join my BLIP chat!\n\n{link}\nPassword: {password}'**
  String chatShareMessage(String link, String password);

  /// Toggle label for including password in shared link
  ///
  /// In en, this message translates to:
  /// **'Include password in link'**
  String get chatIncludeKey;

  /// Warning when password is included in link
  ///
  /// In en, this message translates to:
  /// **'Anyone with this link can join without entering a password'**
  String get chatIncludeKeyWarning;

  /// Share message with link only (password embedded)
  ///
  /// In en, this message translates to:
  /// **'Join my BLIP chat!\n\n{link}'**
  String chatShareMessageLinkOnly(String link);

  /// Waiting for peer
  ///
  /// In en, this message translates to:
  /// **'Waiting for someone to join...'**
  String get chatWaitingPeer;

  /// Settings page title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Theme setting
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// Dark theme label
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get settingsThemeDark;

  /// Light theme label
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get settingsThemeLight;

  /// Language setting
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// About setting
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// Board page title
  ///
  /// In en, this message translates to:
  /// **'Community Board'**
  String get boardTitle;

  /// Board created message
  ///
  /// In en, this message translates to:
  /// **'Community created successfully!'**
  String get boardCreated;

  /// Board destroyed message
  ///
  /// In en, this message translates to:
  /// **'This community has been destroyed.'**
  String get boardDestroyed;

  /// Empty board message
  ///
  /// In en, this message translates to:
  /// **'No posts yet. Be the first to write!'**
  String get boardEmpty;

  /// Write post button
  ///
  /// In en, this message translates to:
  /// **'Write Post'**
  String get boardWritePost;

  /// Problem section title
  ///
  /// In en, this message translates to:
  /// **'Your conversations last too long.'**
  String get problemTitle;

  /// Problem section description
  ///
  /// In en, this message translates to:
  /// **'Server logs, screenshots, forgotten group chats...\nNot every conversation needs a record. Some should vanish like smoke.'**
  String get problemDescription;

  /// Solution feature title
  ///
  /// In en, this message translates to:
  /// **'0 Friction'**
  String get solutionFrictionTitle;

  /// Solution feature description
  ///
  /// In en, this message translates to:
  /// **'Zero setup. Send a link, start talking.'**
  String get solutionFrictionDesc;

  /// Solution feature title
  ///
  /// In en, this message translates to:
  /// **'Total Anonymity'**
  String get solutionAnonymityTitle;

  /// Solution feature description
  ///
  /// In en, this message translates to:
  /// **'We don\'t ask who you are. No ID, no profile needed.'**
  String get solutionAnonymityDesc;

  /// Solution feature title
  ///
  /// In en, this message translates to:
  /// **'Complete Destruction'**
  String get solutionDestructionTitle;

  /// Solution feature description
  ///
  /// In en, this message translates to:
  /// **'Except for you and the recipient, even we cannot see it.'**
  String get solutionDestructionDesc;

  /// Solution feature title
  ///
  /// In en, this message translates to:
  /// **'Auto-Shred'**
  String get solutionAutoshredTitle;

  /// Solution feature description
  ///
  /// In en, this message translates to:
  /// **'Only the last few messages stay on screen. Older ones are destroyed in real time — no scrollback, no context.'**
  String get solutionAutoshredDesc;

  /// Solution feature title
  ///
  /// In en, this message translates to:
  /// **'Capture Guard'**
  String get solutionCaptureGuardTitle;

  /// Solution feature description
  ///
  /// In en, this message translates to:
  /// **'Screenshot and screen-recording attempts are detected. Messages blur instantly — nothing to capture.'**
  String get solutionCaptureGuardDesc;

  /// Solution feature title
  ///
  /// In en, this message translates to:
  /// **'Transparent Code'**
  String get solutionOpensourceTitle;

  /// Solution feature description
  ///
  /// In en, this message translates to:
  /// **'100% Open Source. You can verify with the code that we never spy on your conversations.'**
  String get solutionOpensourceDesc;

  /// Community board label
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get communityLabel;

  /// Community board title
  ///
  /// In en, this message translates to:
  /// **'Build your own private community. Encrypted.'**
  String get communityTitle;

  /// Community board subtitle
  ///
  /// In en, this message translates to:
  /// **'Create a private community with a single password.\nPosts are stored as unreadable ciphertext — the server can never see your content.\nMarkdown, images, anonymous posting. All end-to-end encrypted.'**
  String get communitySubtitle;

  /// Community board CTA
  ///
  /// In en, this message translates to:
  /// **'Create Private Community'**
  String get communityCta;

  /// Community feature title
  ///
  /// In en, this message translates to:
  /// **'Password = Key'**
  String get communityPasswordTitle;

  /// Community feature description
  ///
  /// In en, this message translates to:
  /// **'One shared password encrypts everything. No accounts, no sign-ups. Share the password, share the space.'**
  String get communityPasswordDesc;

  /// Community feature title
  ///
  /// In en, this message translates to:
  /// **'Server-Blind'**
  String get communityServerBlindTitle;

  /// Community feature description
  ///
  /// In en, this message translates to:
  /// **'We store your posts, but we can never read them. The decryption key never leaves your device.'**
  String get communityServerBlindDesc;

  /// Community feature title
  ///
  /// In en, this message translates to:
  /// **'Community-Moderated'**
  String get communityModerationTitle;

  /// Community feature description
  ///
  /// In en, this message translates to:
  /// **'Report system with auto-blinding. No admin needs to read content to keep the space safe.'**
  String get communityModerationDesc;

  /// Philosophy text 1
  ///
  /// In en, this message translates to:
  /// **'BLIP is not a messenger. It\'s a disposable communication tool.'**
  String get philosophyText1;

  /// Philosophy text 2
  ///
  /// In en, this message translates to:
  /// **'We don\'t want to keep you here. Say your piece, then leave.'**
  String get philosophyText2;

  /// Footer easter egg
  ///
  /// In en, this message translates to:
  /// **'This page might disappear soon too.'**
  String get footerEasterEgg;

  /// Footer support link
  ///
  /// In en, this message translates to:
  /// **'Support the Protocol'**
  String get footerSupportProtocol;

  /// Footer copyright
  ///
  /// In en, this message translates to:
  /// **'© 2026 BLIP PROTOCOL'**
  String get footerCopyright;

  /// Footer no rights
  ///
  /// In en, this message translates to:
  /// **'NO RIGHTS RESERVED'**
  String get footerNoRights;

  /// Bottom nav home tab
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Bottom nav chat tab
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get navChat;

  /// Bottom nav community tab
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get navCommunity;

  /// Chat list page title
  ///
  /// In en, this message translates to:
  /// **'My Chat Rooms'**
  String get chatListTitle;

  /// Chat list empty state
  ///
  /// In en, this message translates to:
  /// **'No chat rooms yet.\nCreate a room from the Home tab.'**
  String get chatListEmpty;

  /// Create new room button
  ///
  /// In en, this message translates to:
  /// **'Create New Room'**
  String get chatListCreateNew;

  /// Join room by ID button
  ///
  /// In en, this message translates to:
  /// **'Join by Room ID'**
  String get chatListJoinById;

  /// Join room dialog title
  ///
  /// In en, this message translates to:
  /// **'Join Chat Room'**
  String get chatListJoinDialogTitle;

  /// Join room dialog hint
  ///
  /// In en, this message translates to:
  /// **'Room ID or link'**
  String get chatListJoinDialogHint;

  /// Join room dialog join button
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get chatListJoinDialogJoin;

  /// Chat room active status
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get chatListStatusActive;

  /// Chat room destroyed status
  ///
  /// In en, this message translates to:
  /// **'Destroyed'**
  String get chatListStatusDestroyed;

  /// Chat room expired status
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get chatListStatusExpired;

  /// Community list page title
  ///
  /// In en, this message translates to:
  /// **'My Communities'**
  String get communityListTitle;

  /// Community list empty state
  ///
  /// In en, this message translates to:
  /// **'No communities joined yet.'**
  String get communityListEmpty;

  /// Create new community button
  ///
  /// In en, this message translates to:
  /// **'Create New'**
  String get communityListCreate;

  /// Join community by ID button
  ///
  /// In en, this message translates to:
  /// **'Join by ID'**
  String get communityListJoinById;

  /// Join by ID dialog title
  ///
  /// In en, this message translates to:
  /// **'Join Community'**
  String get communityListJoinDialogTitle;

  /// Join by ID input hint
  ///
  /// In en, this message translates to:
  /// **'Enter Board ID'**
  String get communityListJoinDialogHint;

  /// Join button in dialog
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get communityListJoinDialogJoin;

  /// Community joined date label
  ///
  /// In en, this message translates to:
  /// **'Joined:'**
  String get communityListJoinedAt;

  /// Contact button
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contactButton;

  /// Contact confirm dialog title
  ///
  /// In en, this message translates to:
  /// **'Send Notification?'**
  String get contactConfirmTitle;

  /// Contact confirm dialog message
  ///
  /// In en, this message translates to:
  /// **'A push notification will be sent to the other person. No chat content will be shared.'**
  String get contactConfirmMessage;

  /// Contact notification sent
  ///
  /// In en, this message translates to:
  /// **'Notification sent'**
  String get contactSent;

  /// Push notification not ready
  ///
  /// In en, this message translates to:
  /// **'Push notification is not available yet'**
  String get contactNotReady;

  /// Cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Confirm button
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get confirm;

  /// Board refresh button
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get boardRefresh;

  /// Admin panel button
  ///
  /// In en, this message translates to:
  /// **'Admin Panel'**
  String get boardAdminPanel;

  /// Register admin token
  ///
  /// In en, this message translates to:
  /// **'Register Admin Token'**
  String get boardAdminRegister;

  /// Admin token placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter admin token...'**
  String get boardAdminTokenPlaceholder;

  /// Confirm register button
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get boardAdminConfirmRegister;

  /// Remove admin token button
  ///
  /// In en, this message translates to:
  /// **'Remove Admin Token'**
  String get boardAdminForgetToken;

  /// Edit subtitle button
  ///
  /// In en, this message translates to:
  /// **'Edit Subtitle'**
  String get boardAdminEditSubtitle;

  /// Subtitle input placeholder
  ///
  /// In en, this message translates to:
  /// **'Community subtitle (optional)'**
  String get boardAdminSubtitlePlaceholder;

  /// Save subtitle button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get boardAdminSubtitleSave;

  /// Rotate invite code button
  String get boardAdminRotateInviteCode;

  /// Invite code rotation description
  String get boardAdminRotateInviteCodeDesc;

  /// New invite code label
  String get boardAdminNewInviteCode;

  /// Warning after invite code rotation
  String get boardAdminOldLinksInvalidated;

  /// Reassurance after invite code rotation
  String get boardAdminExistingMembersUnaffected;

  /// Snackbar after copying invite link
  String get boardAdminInviteLinkCopied;

  /// Subtitle placeholder on create form
  ///
  /// In en, this message translates to:
  /// **'Subtitle (optional)'**
  String get boardCreateSubtitlePlaceholder;

  /// Terms agreement checkbox label
  ///
  /// In en, this message translates to:
  /// **'I agree to the Terms of Service'**
  String get termsAgree;

  /// Clickable terms link text
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsAgreeLink;

  /// Terms agreement required error
  ///
  /// In en, this message translates to:
  /// **'You must agree to the Terms of Service to continue.'**
  String get termsMustAgree;

  /// Terms button in chat header
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get termsViewInChat;

  /// Terms dialog title
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get termsTitle;

  /// Terms last updated date
  ///
  /// In en, this message translates to:
  /// **'Last updated: February 2026'**
  String get termsLastUpdated;

  /// Terms introduction
  ///
  /// In en, this message translates to:
  /// **'By using BLIP, you agree to these terms. They\'re short, honest, and written in plain language—just like our code.'**
  String get termsIntro;

  /// Terms section 1 title
  ///
  /// In en, this message translates to:
  /// **'What BLIP Is'**
  String get termsSection1Title;

  /// Terms section 1 content
  ///
  /// In en, this message translates to:
  /// **'BLIP is a free, open-source, end-to-end encrypted ephemeral chat service. It provides temporary communication channels that are destroyed after use. BLIP is not a messenger, social network, or data storage platform. It\'s a disposable communication tool.'**
  String get termsSection1Content;

  /// Terms section 2 title
  ///
  /// In en, this message translates to:
  /// **'No Accounts Required'**
  String get termsSection2Title;

  /// Terms section 2 content
  ///
  /// In en, this message translates to:
  /// **'BLIP operates without user registration, login credentials, or personal profiles. Access is granted through temporary room links and shared passwords. You are responsible for safeguarding your room passwords—we cannot recover them.'**
  String get termsSection2Content;

  /// Terms section 3 title
  ///
  /// In en, this message translates to:
  /// **'Acceptable Use'**
  String get termsSection3Title;

  /// Terms section 3 content
  ///
  /// In en, this message translates to:
  /// **'You agree not to use BLIP for: distributing illegal content, harassment or threats, transmission of malware, automated spam or abuse, or any activity that violates applicable law. While we cannot monitor encrypted content, we reserve the right to restrict access to our infrastructure if abuse is detected at the network level.'**
  String get termsSection3Content;

  /// Terms section 4 title
  ///
  /// In en, this message translates to:
  /// **'No Data Recovery'**
  String get termsSection4Title;

  /// Terms section 4 content
  ///
  /// In en, this message translates to:
  /// **'Messages are not stored in any database. Once a chat room is destroyed, all conversation data is permanently and irreversibly lost. This is by design, not a limitation. Do not use BLIP for communications that you need to preserve.'**
  String get termsSection4Content;

  /// Terms section 5 title
  ///
  /// In en, this message translates to:
  /// **'Open Source'**
  String get termsSection5Title;

  /// Terms section 5 content
  ///
  /// In en, this message translates to:
  /// **'BLIP\'s source code is publicly available. You are free to inspect, fork, and contribute to the codebase. The transparency of our code is our strongest guarantee of privacy. You can verify every claim we make.'**
  String get termsSection5Content;

  /// Terms section 6 title
  ///
  /// In en, this message translates to:
  /// **'Service Availability'**
  String get termsSection6Title;

  /// Terms section 6 content
  ///
  /// In en, this message translates to:
  /// **'BLIP is provided on an \'as-is\' basis. We make no guarantees of uptime, availability, or uninterrupted service. We may modify, suspend, or discontinue the service at any time without prior notice.'**
  String get termsSection6Content;

  /// Terms section 7 title
  ///
  /// In en, this message translates to:
  /// **'Limitation of Liability'**
  String get termsSection7Title;

  /// Terms section 7 content
  ///
  /// In en, this message translates to:
  /// **'To the maximum extent permitted by law, BLIP and its operators shall not be liable for any direct, indirect, incidental, or consequential damages arising from your use of the service.'**
  String get termsSection7Content;

  /// Terms section 8 title
  ///
  /// In en, this message translates to:
  /// **'Intellectual Property'**
  String get termsSection8Title;

  /// Terms section 8 content
  ///
  /// In en, this message translates to:
  /// **'The BLIP name, logo, and brand assets are protected. The service codebase is released under an open-source license. User-generated content in chat rooms belongs to the users—though by design, it ceases to exist after the room is destroyed.'**
  String get termsSection8Content;

  /// Terms section 9 title
  ///
  /// In en, this message translates to:
  /// **'Changes & Governing Law'**
  String get termsSection9Title;

  /// Terms section 9 content
  ///
  /// In en, this message translates to:
  /// **'We reserve the right to modify these terms at any time. Continued use of BLIP after changes constitutes acceptance of the updated terms. These terms are governed by the laws of the Republic of Korea.'**
  String get termsSection9Content;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'ja',
    'ko',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'TW':
            return AppLocalizationsZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
