// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get heroTitle => '話して、消える。';

  @override
  String get heroSubtitle => 'ログイン不要。記録なし。痕跡なし。\nただ、今この瞬間の会話だけが存在します。';

  @override
  String get heroCta => 'クリックしてチャットルームを作成';

  @override
  String get heroLinkShare => '複雑な手続きなしで、リンク一つで完璧につながります。';

  @override
  String get heroRateLimited => 'ルーム作成の制限に達しました。しばらくしてから再度お試しください。';

  @override
  String get heroCreateFailed => 'ルームの作成に失敗しました。もう一度お試しください。';

  @override
  String get chatHeaderExit => 'EXIT';

  @override
  String chatHeaderOnline(int count) {
    return '$count人オンライン';
  }

  @override
  String get chatHeaderE2ee => 'エンドツーエンド暗号化';

  @override
  String get chatInputPlaceholder => 'メッセージを入力...';

  @override
  String get chatInputSend => '送信';

  @override
  String get chatCreateTitle => 'CHANNEL CREATED';

  @override
  String get chatCreatePassword => 'ACCESS KEY';

  @override
  String get chatCreateShareLink => '共有リンク';

  @override
  String get chatCreateWarning => 'このキーを保存してください。復元できません。';

  @override
  String get chatCreateEnter => 'チャンネルに入る';

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
  String get chatLeaveDescription => 'チャットを離れますか？';

  @override
  String get chatLeaveLastPersonWarning =>
      'あなたが最後の参加者です。退出するとこのチャンネルは永久に破棄されます。';

  @override
  String get chatLeaveConfirm => 'EXIT';

  @override
  String get chatLeaveCancel => 'CANCEL';

  @override
  String get chatDestroyedTitle => '痕跡は残りません。';

  @override
  String get chatDestroyedSubtitle => 'このチャンネルは永久に破棄されました。';

  @override
  String get chatDestroyedNewChat => '新しいチャットを始める';

  @override
  String get chatRoomFullTitle => 'チャンネルが満員です。';

  @override
  String get chatRoomFullSubtitle => 'このチャンネルにはすでに2名が参加しています。';

  @override
  String get chatRoomFullNewChat => '新しいチャットを始める';

  @override
  String get chatMediaAttachFile => 'メディアを添付';

  @override
  String chatMediaFileTooLarge(String maxSize) {
    return 'ファイルサイズ超過（最大$maxSize）';
  }

  @override
  String get chatMediaSendingFile => 'ファイル送信中...';

  @override
  String get chatMediaP2pConnecting => 'セキュアP2P接続を確立中...';

  @override
  String get chatMediaP2pFailed => 'P2P接続に失敗しました。テキストのみ利用可能です。';

  @override
  String get chatMediaP2pConnected => 'P2Pメディアチャンネル準備完了';

  @override
  String get chatMediaVideoLoadFailed => '動画の読み込みに失敗';

  @override
  String get chatMediaUnsupportedType => 'サポートされていないファイル形式';

  @override
  String get boardCreateTitle => 'コミュニティ作成完了';

  @override
  String get boardCreateSubtitle => 'プライベートコミュニティを作成';

  @override
  String get boardCreateButton => 'コミュニティを作成';

  @override
  String get boardCreateNamePlaceholder => 'コミュニティ名';

  @override
  String get boardCreatePassword => 'コミュニティパスワード';

  @override
  String get boardCreateAdminToken => '管理者トークン';

  @override
  String get boardCreateAdminTokenWarning => 'このトークンを保存してください — 復元できません';

  @override
  String get boardCreateShareLink => '共有リンク';

  @override
  String get boardCreateEnter => 'コミュニティに入る';

  @override
  String get boardHeaderEncrypted => 'E2E暗号化';

  @override
  String get boardHeaderAdmin => '管理者パネル';

  @override
  String get boardHeaderForgetPassword => '保存したパスワードを削除';

  @override
  String get boardHeaderForgetPasswordConfirm =>
      'この端末に保存されたパスワードが削除されます。次回アクセス時にパスワードの再入力が必要です。';

  @override
  String get boardHeaderCancel => 'キャンセル';

  @override
  String get boardHeaderConfirmForget => '削除';

  @override
  String get boardHeaderRegisterAdmin => '管理者トークンを登録';

  @override
  String get boardHeaderAdminTokenPlaceholder => '管理者トークンを貼り付け';

  @override
  String get boardHeaderConfirmRegister => '登録';

  @override
  String get boardPostPlaceholder => '何か書いてください...（Markdown対応）';

  @override
  String get boardPostSubmit => '投稿';

  @override
  String get boardPostCompose => '新規投稿';

  @override
  String get boardPostDetail => '投稿';

  @override
  String get boardPostEmpty => 'まだ投稿がありません';

  @override
  String get boardPostWriteFirst => '最初の投稿を書く';

  @override
  String get boardPostRefresh => '更新';

  @override
  String get boardPostAttachImage => '画像を添付';

  @override
  String get boardPostMaxImages => '最大4枚';

  @override
  String get boardPostImageTooLarge => '画像が大きすぎます';

  @override
  String get boardPostUploading => 'アップロード中...';

  @override
  String get boardPostAttachMedia => 'メディア添付';

  @override
  String boardPostMaxMedia(int count) {
    return '最大$countファイル';
  }

  @override
  String boardPostVideoTooLong(int seconds) {
    return '動画が長すぎます（最大$seconds秒）';
  }

  @override
  String get boardPostVideoTooLarge => '圧縮後も動画が大きすぎます';

  @override
  String get boardPostCompressing => '圧縮中...';

  @override
  String get boardPostTitlePlaceholder => 'タイトル（任意）';

  @override
  String get boardPostInsertInline => '本文に挿入';

  @override
  String get boardPostEdit => '編集';

  @override
  String get boardPostEditTitle => '投稿を編集';

  @override
  String get boardPostSave => '保存';

  @override
  String get boardPostDelete => '削除';

  @override
  String get boardPostAdminDelete => '削除（管理者）';

  @override
  String get boardPostDeleteWarning => 'この投稿は完全に削除されます。元に戻せません。';

  @override
  String get boardPostConfirmDelete => '削除';

  @override
  String get boardPostShare => '共有';

  @override
  String get boardPostLinkCopied => 'リンクをコピーしました！';

  @override
  String get boardReportTitle => '投稿を報告';

  @override
  String get boardReportSpam => 'スパム';

  @override
  String get boardReportAbuse => '悪用 / 嫌がらせ';

  @override
  String get boardReportIllegal => '違法コンテンツ';

  @override
  String get boardReportOther => 'その他';

  @override
  String get boardReportSubmit => '報告';

  @override
  String get boardReportCancel => 'キャンセル';

  @override
  String get boardReportAlreadyReported => '報告済み';

  @override
  String get boardBlindedMessage => 'コミュニティの報告によりブラインド処理されました';

  @override
  String get boardAdminTitle => '管理者パネル';

  @override
  String get boardAdminDestroy => 'コミュニティを破棄';

  @override
  String get boardAdminDestroyWarning => 'コミュニティとすべての投稿が永久に削除されます。元に戻せません。';

  @override
  String get boardAdminCancel => 'キャンセル';

  @override
  String get boardAdminConfirmDestroy => '破棄';

  @override
  String get boardDestroyedTitle => 'コミュニティ破棄済み';

  @override
  String get boardDestroyedMessage => 'このコミュニティは永久に削除されました。';

  @override
  String get commonSettings => '設定';

  @override
  String get commonTheme => 'テーマ';

  @override
  String get commonLanguage => '言語';

  @override
  String get commonCopy => 'コピー';

  @override
  String get commonShare => '共有';

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get commonConfirm => '確認';

  @override
  String get commonLoading => '読み込み中...';

  @override
  String get commonError => 'エラーが発生しました';

  @override
  String get commonRetry => '再試行';

  @override
  String get commonClose => '閉じる';

  @override
  String get commonBack => '戻る';

  @override
  String get commonDone => '完了';

  @override
  String get commonDelete => '削除';

  @override
  String get commonSave => '保存';

  @override
  String get commonCopied => 'クリップボードにコピーしました';

  @override
  String get heroBoardCta => 'コミュニティ掲示板';

  @override
  String get featureZeroFriction => 'ゼロフリクション';

  @override
  String get featureZeroFrictionDesc => '複雑な手続き不要、リンク一つで完璧につながります。';

  @override
  String get featureAnonymity => '完全な匿名性';

  @override
  String get featureAnonymityDesc => 'アカウントもプロフィールも不要。大切なのは会話だけ。';

  @override
  String get featureDestruction => '自動破棄';

  @override
  String get featureDestructionDesc => '全員が退出すると、すべての痕跡が永久に消えます。';

  @override
  String get errorRateLimit => 'リクエストが多すぎます。しばらくしてからもう一度お試しください。';

  @override
  String get errorGeneric => 'エラーが発生しました。';

  @override
  String get chatConnected => 'エンドツーエンド暗号化接続が確立されました';

  @override
  String get chatPasswordTitle => 'アクセスキーを入力';

  @override
  String get chatPasswordSubtitle => '会話相手にアクセスキーを共有してください';

  @override
  String get chatPasswordJoin => '参加';

  @override
  String get chatPasswordInvalid => '無効なアクセスキー';

  @override
  String get chatRoomNotFound => 'ルームが見つかりません';

  @override
  String get chatRoomDestroyed => 'ルームは破棄されました';

  @override
  String get chatExpired => 'ルームの有効期限が切れました';

  @override
  String get chatRoomFull => 'ルームが満員です';

  @override
  String get chatCreatedTitle => 'チャンネル作成完了';

  @override
  String get chatCreatedWarning => 'このキーを保存してください。復旧できません。';

  @override
  String get chatAccessKey => 'アクセスキー';

  @override
  String get chatShareLink => '共有リンク';

  @override
  String get chatPeerConnected => '相手が接続しました';

  @override
  String chatShareMessage(String link, String password) {
    return 'BLIPチャットに参加してください！\n\n$link\nパスワード: $password';
  }

  @override
  String get chatIncludeKey => 'リンクにパスワードを含める';

  @override
  String get chatIncludeKeyWarning => 'このリンクを持つ人は誰でもパスワードなしで参加できます';

  @override
  String chatShareMessageLinkOnly(String link) {
    return 'BLIPチャットに参加してください！\n\n$link';
  }

  @override
  String get chatWaitingPeer => '誰かの参加を待っています...';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsTheme => 'テーマ';

  @override
  String get settingsThemeDark => 'ダークモード';

  @override
  String get settingsThemeLight => 'ライトモード';

  @override
  String get settingsLanguage => '言語';

  @override
  String get settingsAbout => '情報';

  @override
  String get boardTitle => 'コミュニティ掲示板';

  @override
  String get boardCreated => 'コミュニティが作成されました！';

  @override
  String get boardDestroyed => 'このコミュニティは破棄されました。';

  @override
  String get boardEmpty => 'まだ投稿がありません。最初の投稿を書いてみましょう！';

  @override
  String get boardWritePost => '投稿する';

  @override
  String get problemTitle => 'あなたの会話は長く残りすぎます。';

  @override
  String get problemDescription =>
      'サーバーに残るログ、スクリーンショット、忘れられたグループチャット...\nすべての会話を記録する必要はありません。一部の会話は煙のように消えるべきです。';

  @override
  String get solutionFrictionTitle => '0 Friction';

  @override
  String get solutionFrictionDesc => '準備は0秒。リンクを送るだけで会話開始。';

  @override
  String get solutionAnonymityTitle => 'Total Anonymity';

  @override
  String get solutionAnonymityDesc => 'あなたが誰であるか尋ねません。IDもプロフィールも不要です。';

  @override
  String get solutionDestructionTitle => 'Complete Destruction';

  @override
  String get solutionDestructionDesc => 'あなたと受信者以外、私たちでさえ見ることはできません。';

  @override
  String get solutionAutoshredTitle => 'Auto-Shred';

  @override
  String get solutionAutoshredDesc =>
      '最新メッセージだけが画面に残り、古いメッセージはリアルタイムで破棄されます。スクロールバックも文脈もありません。';

  @override
  String get solutionCaptureGuardTitle => 'Capture Guard';

  @override
  String get solutionCaptureGuardDesc =>
      'スクリーンショットや画面録画の試行を検知します。メッセージは即座にぼかし処理され、キャプチャできません。';

  @override
  String get solutionOpensourceTitle => 'Transparent Code';

  @override
  String get solutionOpensourceDesc =>
      '100%オープンソース。私たちがあなたの会話を盗み見ないことを、コードで直接検証できます。';

  @override
  String get communityLabel => 'NEW';

  @override
  String get communityTitle => '自分だけのプライベートコミュニティを。暗号化で。';

  @override
  String get communitySubtitle =>
      'パスワード一つでプライベートコミュニティを作成。\n投稿は読めない暗号文として保存 — サーバーはコンテンツを見ることができません。\nMarkdown、画像、匿名投稿。すべてエンドツーエンド暗号化。';

  @override
  String get communityCta => 'プライベートコミュニティを作成';

  @override
  String get communityPasswordTitle => 'パスワード = 鍵';

  @override
  String get communityPasswordDesc =>
      '共有パスワード一つですべてを暗号化。アカウント不要、登録不要。パスワードを共有すれば、空間を共有。';

  @override
  String get communityServerBlindTitle => 'サーバーは盲目';

  @override
  String get communityServerBlindDesc =>
      '投稿を保存しますが、読むことはできません。復号鍵はデバイスから離れません。';

  @override
  String get communityModerationTitle => 'コミュニティ自浄';

  @override
  String get communityModerationDesc => '通報による自動ブラインド。管理者がコンテンツを読まなくても安全を保てます。';

  @override
  String get philosophyText1 => 'BLIPはメッセンジャーではありません。使い捨ての通信ツールです。';

  @override
  String get philosophyText2 => '私たちはあなたを引き留めたくありません。話して、立ち去ってください。';

  @override
  String get footerEasterEgg => 'このページもすぐに消えるかもしれません。';

  @override
  String get footerSupportProtocol => 'プロトコルを維持する';

  @override
  String get footerCopyright => '© 2026 BLIP PROTOCOL';

  @override
  String get footerNoRights => 'NO RIGHTS RESERVED';

  @override
  String get navHome => 'ホーム';

  @override
  String get navChat => 'チャット';

  @override
  String get navCommunity => 'コミュニティ';

  @override
  String get chatListTitle => 'マイチャットルーム';

  @override
  String get chatListEmpty => 'チャットルームがありません。\nホームタブからルームを作成してください。';

  @override
  String get chatListCreateNew => '新しいルームを作成';

  @override
  String get chatListJoinById => 'ルームIDで参加';

  @override
  String get chatListJoinDialogTitle => 'チャットルームに参加';

  @override
  String get chatListJoinDialogHint => 'ルームIDまたはリンク';

  @override
  String get chatListJoinDialogJoin => '参加';

  @override
  String get chatListStatusActive => 'アクティブ';

  @override
  String get chatListStatusDestroyed => '破棄済み';

  @override
  String get chatListStatusExpired => '期限切れ';

  @override
  String get communityListTitle => 'マイコミュニティ';

  @override
  String get communityListEmpty => 'まだ参加しているコミュニティがありません。';

  @override
  String get communityListCreate => '新規作成';

  @override
  String get communityListJoinById => 'IDで参加';

  @override
  String get communityListJoinDialogTitle => 'コミュニティに参加';

  @override
  String get communityListJoinDialogHint => 'ボードIDを入力';

  @override
  String get communityListJoinDialogJoin => '参加';

  @override
  String get communityListJoinedAt => '参加日:';

  @override
  String get contactButton => '連絡する';

  @override
  String get contactConfirmTitle => '通知を送信しますか？';

  @override
  String get contactConfirmMessage => '相手にプッシュ通知が送信されます。チャット内容は共有されません。';

  @override
  String get contactSent => '通知を送信しました';

  @override
  String get contactNotReady => 'プッシュ通知はまだ利用できません';

  @override
  String get cancel => 'キャンセル';

  @override
  String get confirm => 'OK';

  @override
  String get boardRefresh => '更新';

  @override
  String get boardAdminPanel => '管理者パネル';

  @override
  String get boardAdminRegister => '管理者トークン登録';

  @override
  String get boardAdminTokenPlaceholder => '管理者トークンを入力...';

  @override
  String get boardAdminConfirmRegister => '登録';

  @override
  String get boardAdminForgetToken => '管理者トークン解除';

  @override
  String get boardAdminEditSubtitle => 'サブタイトル編集';

  @override
  String get boardAdminSubtitlePlaceholder => 'コミュニティのサブタイトル（任意）';

  @override
  String get boardAdminSubtitleSave => '保存';

  @override
  String get boardAdminRotateInviteCode => '招待リンクを再生成';

  @override
  String get boardAdminRotateInviteCodeDesc =>
      '新しい招待リンクを生成します。以前共有されたリンクは無効になりますが、既存メンバーには影響ありません。';

  @override
  String get boardAdminNewInviteCode => '新しい招待リンク';

  @override
  String get boardAdminOldLinksInvalidated => '以前の招待リンクはすべて無効になりました';

  @override
  String get boardAdminExistingMembersUnaffected => '既存メンバーは引き続きご利用いただけます';

  @override
  String get boardAdminInviteLinkCopied => '招待リンクがコピーされました';

  @override
  String get boardCreateSubtitlePlaceholder => 'サブタイトル（任意）';

  @override
  String get termsAgree => '利用規約に同意します';

  @override
  String get termsAgreeLink => '利用規約';

  @override
  String get termsMustAgree => '続行するには利用規約に同意する必要があります。';

  @override
  String get termsViewInChat => '利用規約';

  @override
  String get termsTitle => '利用規約';

  @override
  String get termsLastUpdated => '最終更新日：2026年2月';

  @override
  String get termsIntro =>
      'BLIPを使用することで、これらの規約に同意したことになります。私たちのコードと同様に—短く、正直で、平易な言葉で書かれています。';

  @override
  String get termsSection1Title => 'BLIPとは';

  @override
  String get termsSection1Content =>
      'BLIPは無料のオープンソース、エンドツーエンド暗号化の使い捨てチャットサービスです。使用後に破棄される一時的な通信チャネルを提供します。';

  @override
  String get termsSection2Title => 'アカウント不要';

  @override
  String get termsSection2Content =>
      'BLIPはユーザー登録、ログイン資格情報、個人プロフィールなしで運営されます。一時的なルームリンクと共有パスワードでアクセスできます。';

  @override
  String get termsSection3Title => '許容される使用';

  @override
  String get termsSection3Content =>
      'BLIPを違法コンテンツの配布、ハラスメント、マルウェアの送信、自動スパム、または法律に違反する活動に使用しないことに同意します。';

  @override
  String get termsSection4Title => 'データ復旧不可';

  @override
  String get termsSection4Content =>
      'メッセージはデータベースに保存されません。チャットルームが破棄されると、すべての会話データは永久に失われます。これは制限ではなく設計です。';

  @override
  String get termsSection5Title => 'オープンソース';

  @override
  String get termsSection5Content =>
      'BLIPのソースコードは公開されています。コードの透明性がプライバシーに対する最も強力な保証です。';

  @override
  String get termsSection6Title => 'サービスの可用性';

  @override
  String get termsSection6Content =>
      'BLIPは「現状のまま」提供されます。稼働時間、可用性、中断のないサービスを保証しません。';

  @override
  String get termsSection7Title => '責任の制限';

  @override
  String get termsSection7Content =>
      '法律で許容される最大限の範囲で、BLIPとその運営者はサービスの使用から生じるいかなる損害に対しても責任を負いません。';

  @override
  String get termsSection8Title => '知的財産権';

  @override
  String get termsSection8Content =>
      'BLIPの名前、ロゴ、ブランド資産は保護されています。サービスのコードベースはオープンソースライセンスで公開されています。';

  @override
  String get termsSection9Title => '変更と準拠法';

  @override
  String get termsSection9Content =>
      'これらの規約はいつでも変更される場合があります。変更後もBLIPの使用を継続することは、更新された規約への同意とみなされます。';

  @override
  String get boardCommentTitle => 'コメント';

  @override
  String get boardCommentPlaceholder => 'コメントを入力...';

  @override
  String get boardCommentSubmit => '送信';

  @override
  String get boardCommentEmpty => 'コメントはまだありません';

  @override
  String get boardCommentWriteFirst => '最初のコメントを書こう';

  @override
  String get boardCommentLoadMore => 'もっと見る';

  @override
  String get boardCommentAttachImage => '画像';
}
