// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get heroTitle => '交谈。然后消失。';

  @override
  String get heroSubtitle => '无需账号。无需记录。不留痕迹。\n只有此刻的对话存在。';

  @override
  String get heroCta => '点击创建聊天室';

  @override
  String get heroLinkShare => '无需复杂手续，仅需一个链接即可完美连接。';

  @override
  String get heroRateLimited => '房间创建限制已达上限，请稍后再试。';

  @override
  String get heroCreateFailed => '房间创建失败，请重试。';

  @override
  String get chatHeaderExit => 'EXIT';

  @override
  String chatHeaderOnline(int count) {
    return '$count人在线';
  }

  @override
  String get chatHeaderE2ee => '端到端加密';

  @override
  String get chatInputPlaceholder => '输入消息...';

  @override
  String get chatInputSend => '发送';

  @override
  String get chatCreateTitle => 'CHANNEL CREATED';

  @override
  String get chatCreatePassword => 'ACCESS KEY';

  @override
  String get chatCreateShareLink => '分享链接';

  @override
  String get chatCreateWarning => '请保存此密钥。无法恢复。';

  @override
  String get chatCreateEnter => '进入频道';

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
  String get chatLeaveDescription => '确定要离开吗？';

  @override
  String get chatLeaveLastPersonWarning => '你是最后一个参与者。离开将永久销毁此频道。';

  @override
  String get chatLeaveConfirm => 'EXIT';

  @override
  String get chatLeaveCancel => 'CANCEL';

  @override
  String get chatDestroyedTitle => '不留痕迹。';

  @override
  String get chatDestroyedSubtitle => '此频道已被永久销毁。';

  @override
  String get chatDestroyedNewChat => '开始新聊天';

  @override
  String get chatRoomFullTitle => '频道已满。';

  @override
  String get chatRoomFullSubtitle => '此频道已有2名参与者。';

  @override
  String get chatRoomFullNewChat => '开始新聊天';

  @override
  String get chatMediaAttachFile => '附加媒体';

  @override
  String chatMediaFileTooLarge(String maxSize) {
    return '文件大小超限（最大$maxSize）';
  }

  @override
  String get chatMediaSendingFile => '文件发送中...';

  @override
  String get chatMediaP2pConnecting => '正在建立安全P2P连接...';

  @override
  String get chatMediaP2pFailed => 'P2P连接失败，仅可发送文字。';

  @override
  String get chatMediaP2pConnected => 'P2P媒体通道就绪';

  @override
  String get chatMediaVideoLoadFailed => '视频加载失败';

  @override
  String get chatMediaUnsupportedType => '不支持的文件格式';

  @override
  String get boardCreateTitle => '社区已创建';

  @override
  String get boardCreateSubtitle => '创建私密社区';

  @override
  String get boardCreateButton => '创建社区';

  @override
  String get boardCreateNamePlaceholder => '社区名称';

  @override
  String get boardCreatePassword => '社区密码';

  @override
  String get boardCreateAdminToken => '管理员令牌';

  @override
  String get boardCreateAdminTokenWarning => '请保存此令牌 — 无法恢复';

  @override
  String get boardCreateShareLink => '分享链接';

  @override
  String get boardCreateEnter => '进入社区';

  @override
  String get boardHeaderEncrypted => '端到端加密';

  @override
  String get boardHeaderAdmin => '管理员面板';

  @override
  String get boardHeaderForgetPassword => '删除已保存的密码';

  @override
  String get boardHeaderForgetPasswordConfirm => '此设备上保存的密码将被删除。下次访问时需要重新输入密码。';

  @override
  String get boardHeaderCancel => '取消';

  @override
  String get boardHeaderConfirmForget => '删除';

  @override
  String get boardHeaderRegisterAdmin => '注册管理员令牌';

  @override
  String get boardHeaderAdminTokenPlaceholder => '粘贴管理员令牌';

  @override
  String get boardHeaderConfirmRegister => '注册';

  @override
  String get boardPostPlaceholder => '写点什么...（支持Markdown）';

  @override
  String get boardPostSubmit => '发布';

  @override
  String get boardPostCompose => '发新帖';

  @override
  String get boardPostDetail => '帖子';

  @override
  String get boardPostEmpty => '暂无帖子';

  @override
  String get boardPostWriteFirst => '写下第一篇帖子';

  @override
  String get boardPostRefresh => '刷新';

  @override
  String get boardPostAttachImage => '添加图片';

  @override
  String get boardPostMaxImages => '最多4张';

  @override
  String get boardPostImageTooLarge => '图片太大';

  @override
  String get boardPostUploading => '上传中...';

  @override
  String get boardPostAttachMedia => '附加媒体';

  @override
  String boardPostMaxMedia(int count) {
    return '最多$count个文件';
  }

  @override
  String boardPostVideoTooLong(int seconds) {
    return '视频太长（最长$seconds秒）';
  }

  @override
  String get boardPostVideoTooLarge => '压缩后视频仍然太大';

  @override
  String get boardPostCompressing => '压缩中...';

  @override
  String get boardPostTitlePlaceholder => '标题（可选）';

  @override
  String get boardPostInsertInline => '插入正文';

  @override
  String get boardPostEdit => '编辑';

  @override
  String get boardPostEditTitle => '编辑帖子';

  @override
  String get boardPostSave => '保存';

  @override
  String get boardPostDelete => '删除';

  @override
  String get boardPostAdminDelete => '删除（管理员）';

  @override
  String get boardPostDeleteWarning => '此帖子将被永久删除，无法恢复。';

  @override
  String get boardPostConfirmDelete => '删除';

  @override
  String get boardReportTitle => '举报帖子';

  @override
  String get boardReportSpam => '垃圾信息';

  @override
  String get boardReportAbuse => '辱骂 / 骚扰';

  @override
  String get boardReportIllegal => '违法内容';

  @override
  String get boardReportOther => '其他';

  @override
  String get boardReportSubmit => '举报';

  @override
  String get boardReportCancel => '取消';

  @override
  String get boardReportAlreadyReported => '已举报';

  @override
  String get boardBlindedMessage => '因社区举报已被屏蔽';

  @override
  String get boardAdminTitle => '管理员面板';

  @override
  String get boardAdminDestroy => '销毁社区';

  @override
  String get boardAdminDestroyWarning => '这将永久删除社区和所有帖子。此操作不可撤销。';

  @override
  String get boardAdminCancel => '取消';

  @override
  String get boardAdminConfirmDestroy => '销毁';

  @override
  String get boardDestroyedTitle => '社区已销毁';

  @override
  String get boardDestroyedMessage => '此社区已被永久删除。';

  @override
  String get commonSettings => '设置';

  @override
  String get commonTheme => '主题';

  @override
  String get commonLanguage => '语言';

  @override
  String get commonCopy => '复制';

  @override
  String get commonShare => '分享';

  @override
  String get commonCancel => '取消';

  @override
  String get commonConfirm => '确认';

  @override
  String get commonLoading => '加载中...';

  @override
  String get commonError => '发生错误';

  @override
  String get commonRetry => '重试';

  @override
  String get commonClose => '关闭';

  @override
  String get commonBack => '返回';

  @override
  String get commonDone => '完成';

  @override
  String get commonDelete => '删除';

  @override
  String get commonSave => '保存';

  @override
  String get commonCopied => '已复制到剪贴板';

  @override
  String get heroBoardCta => '社区公告板';

  @override
  String get featureZeroFriction => '零摩擦';

  @override
  String get featureZeroFrictionDesc => '无需复杂流程，一个链接即可完美连接。';

  @override
  String get featureAnonymity => '完全匿名';

  @override
  String get featureAnonymityDesc => '无需账号，无需个人资料。只有对话才重要。';

  @override
  String get featureDestruction => '自动销毁';

  @override
  String get featureDestructionDesc => '当所有人离开后，一切痕迹将永久消失。';

  @override
  String get errorRateLimit => '请求过于频繁，请稍后再试。';

  @override
  String get errorGeneric => '发生了错误。';

  @override
  String get chatConnected => '端到端加密连接已建立';

  @override
  String get chatPasswordTitle => '输入访问密钥';

  @override
  String get chatPasswordSubtitle => '请与对话伙伴分享访问密钥';

  @override
  String get chatPasswordJoin => '加入';

  @override
  String get chatPasswordInvalid => '无效的访问密钥';

  @override
  String get chatRoomNotFound => '未找到房间';

  @override
  String get chatRoomDestroyed => '房间已被销毁';

  @override
  String get chatExpired => '房间已过期';

  @override
  String get chatRoomFull => '房间已满';

  @override
  String get chatCreatedTitle => '频道已创建';

  @override
  String get chatCreatedWarning => '请保存此密钥，无法恢复。';

  @override
  String get chatAccessKey => '访问密钥';

  @override
  String get chatShareLink => '分享链接';

  @override
  String get chatPeerConnected => '对方已连接';

  @override
  String chatShareMessage(String link, String password) {
    return '加入我的BLIP聊天！\n\n$link\n密码: $password';
  }

  @override
  String get chatIncludeKey => '在链接中包含密码';

  @override
  String get chatIncludeKeyWarning => '任何拥有此链接的人都可以无需输入密码直接加入';

  @override
  String chatShareMessageLinkOnly(String link) {
    return '加入我的BLIP聊天！\n\n$link';
  }

  @override
  String get chatWaitingPeer => '正在等待其他人加入...';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsTheme => '主题';

  @override
  String get settingsThemeDark => '深色模式';

  @override
  String get settingsThemeLight => '浅色模式';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsAbout => '关于';

  @override
  String get boardTitle => '社区公告板';

  @override
  String get boardCreated => '社区创建成功！';

  @override
  String get boardDestroyed => '此社区已被销毁。';

  @override
  String get boardEmpty => '还没有帖子。来写第一篇吧！';

  @override
  String get boardWritePost => '写帖子';

  @override
  String get problemTitle => '你的对话保留得太久了。';

  @override
  String get problemDescription =>
      '服务器日志、截图、被遗忘的群聊...\n不是所有的对话都需要记录。有些应该像烟雾一样消失。';

  @override
  String get solutionFrictionTitle => '0 Friction';

  @override
  String get solutionFrictionDesc => '零准备。发送链接，开始交谈。';

  @override
  String get solutionAnonymityTitle => 'Total Anonymity';

  @override
  String get solutionAnonymityDesc => '我们不问你是谁。无需ID，无需个人资料。';

  @override
  String get solutionDestructionTitle => 'Complete Destruction';

  @override
  String get solutionDestructionDesc => '除了你和收件人，连我们也看不到。';

  @override
  String get solutionAutoshredTitle => 'Auto-Shred';

  @override
  String get solutionAutoshredDesc => '仅最新消息留在屏幕上，旧消息实时销毁。没有回滚，没有上下文。';

  @override
  String get solutionCaptureGuardTitle => 'Capture Guard';

  @override
  String get solutionCaptureGuardDesc => '检测截屏和录屏尝试。消息立即模糊处理——无法截取任何内容。';

  @override
  String get solutionOpensourceTitle => 'Transparent Code';

  @override
  String get solutionOpensourceDesc => '100%开源。你可以通过代码验证我们绝不会窥探你的对话。';

  @override
  String get communityLabel => 'NEW';

  @override
  String get communityTitle => '打造你的私密社区。全程加密。';

  @override
  String get communitySubtitle =>
      '用一个密码创建私密社区。\n帖子以不可读的密文存储 — 服务器永远无法看到您的内容。\nMarkdown、图片、匿名发帖。全部端到端加密。';

  @override
  String get communityCta => '创建私密社区';

  @override
  String get communityPasswordTitle => '密码 = 钥匙';

  @override
  String get communityPasswordDesc => '一个共享密码加密一切。无需账户，无需注册。分享密码，分享空间。';

  @override
  String get communityServerBlindTitle => '服务器是盲的';

  @override
  String get communityServerBlindDesc => '我们存储您的帖子，但永远无法阅读。解密密钥永远不会离开您的设备。';

  @override
  String get communityModerationTitle => '社区自治';

  @override
  String get communityModerationDesc => '基于举报的自动屏蔽。管理员无需阅读内容即可保持空间安全。';

  @override
  String get philosophyText1 => 'BLIP不是信使。它是用完即弃的通讯工具。';

  @override
  String get philosophyText2 => '我们不想留住你。说完就走。';

  @override
  String get footerEasterEgg => '这个页面也可能很快消失。';

  @override
  String get footerSupportProtocol => '支持协议';

  @override
  String get footerCopyright => '© 2026 BLIP PROTOCOL';

  @override
  String get footerNoRights => 'NO RIGHTS RESERVED';

  @override
  String get navHome => '首页';

  @override
  String get navChat => '聊天';

  @override
  String get navCommunity => '社区';

  @override
  String get chatListTitle => '我的聊天室';

  @override
  String get chatListEmpty => '还没有聊天室。\n请从首页标签创建房间。';

  @override
  String get chatListCreateNew => '创建新房间';

  @override
  String get chatListJoinById => '通过房间ID加入';

  @override
  String get chatListJoinDialogTitle => '加入聊天室';

  @override
  String get chatListJoinDialogHint => '房间ID或链接';

  @override
  String get chatListJoinDialogJoin => '加入';

  @override
  String get chatListStatusActive => '活跃';

  @override
  String get chatListStatusDestroyed => '已销毁';

  @override
  String get chatListStatusExpired => '已过期';

  @override
  String get communityListTitle => '我的社区';

  @override
  String get communityListEmpty => '还没有加入任何社区。';

  @override
  String get communityListCreate => '新建';

  @override
  String get communityListJoinById => '通过ID加入';

  @override
  String get communityListJoinDialogTitle => '加入社区';

  @override
  String get communityListJoinDialogHint => '输入Board ID';

  @override
  String get communityListJoinDialogJoin => '加入';

  @override
  String get communityListJoinedAt => '加入时间:';

  @override
  String get contactButton => '联系';

  @override
  String get contactConfirmTitle => '发送通知？';

  @override
  String get contactConfirmMessage => '将向对方发送推送通知。聊天内容不会被共享。';

  @override
  String get contactSent => '通知已发送';

  @override
  String get contactNotReady => '推送通知暂不可用';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确定';

  @override
  String get boardRefresh => '刷新';

  @override
  String get boardAdminPanel => '管理员面板';

  @override
  String get boardAdminRegister => '注册管理员令牌';

  @override
  String get boardAdminTokenPlaceholder => '输入管理员令牌...';

  @override
  String get boardAdminConfirmRegister => '注册';

  @override
  String get boardAdminForgetToken => '移除管理员令牌';

  @override
  String get boardAdminEditSubtitle => '编辑副标题';

  @override
  String get boardAdminSubtitlePlaceholder => '社区副标题（可选）';

  @override
  String get boardAdminSubtitleSave => '保存';

  @override
  String get boardCreateSubtitlePlaceholder => '副标题（可选）';

  @override
  String get termsAgree => '我同意使用条款';

  @override
  String get termsAgreeLink => '使用条款';

  @override
  String get termsMustAgree => '继续前请同意使用条款。';

  @override
  String get termsViewInChat => '使用条款';

  @override
  String get termsTitle => '使用条款';

  @override
  String get termsLastUpdated => '最后更新：2026年2月';

  @override
  String get termsIntro => '使用BLIP即表示你同意这些条款。像我们的代码一样——简短、诚实、用简明语言编写。';

  @override
  String get termsSection1Title => 'BLIP是什么';

  @override
  String get termsSection1Content =>
      'BLIP是一个免费的开源端到端加密临时聊天服务。它提供使用后即销毁的临时通信频道。';

  @override
  String get termsSection2Title => '无需账户';

  @override
  String get termsSection2Content => 'BLIP无需用户注册、登录凭证或个人资料。通过临时房间链接和共享密码即可访问。';

  @override
  String get termsSection3Title => '可接受的使用';

  @override
  String get termsSection3Content =>
      '你同意不将BLIP用于：分发非法内容、骚扰或威胁、传播恶意软件、自动垃圾信息或滥用，或任何违反法律的活动。';

  @override
  String get termsSection4Title => '数据不可恢复';

  @override
  String get termsSection4Content =>
      '消息不存储在任何数据库中。聊天室销毁后，所有对话数据将永久不可逆地丢失。这是设计特性，不是限制。';

  @override
  String get termsSection5Title => '开源';

  @override
  String get termsSection5Content => 'BLIP的源代码是公开的。代码的透明性是我们对隐私最有力的保证。';

  @override
  String get termsSection6Title => '服务可用性';

  @override
  String get termsSection6Content => 'BLIP按\'原样\'提供。我们不保证正常运行时间、可用性或不间断服务。';

  @override
  String get termsSection7Title => '责任限制';

  @override
  String get termsSection7Content =>
      '在法律允许的最大范围内，BLIP及其运营者不对因使用服务而产生的任何损害承担责任。';

  @override
  String get termsSection8Title => '知识产权';

  @override
  String get termsSection8Content => 'BLIP的名称、标志和品牌资产受到保护。服务代码库以开源许可证发布。';

  @override
  String get termsSection9Title => '变更与适用法律';

  @override
  String get termsSection9Content => '我们保留随时修改这些条款的权利。在变更后继续使用BLIP即表示接受更新后的条款。';
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

  @override
  String get heroTitle => '交談。然後消失。';

  @override
  String get heroSubtitle => '不需要帳號。不留痕跡。沒有紀錄。\n只有此刻的對話存在。';

  @override
  String get heroCta => '點擊建立聊天室';

  @override
  String get heroLinkShare => '不需要繁瑣的流程，只要一個連結就能完美連線。';

  @override
  String get heroRateLimited => '已達房間建立上限，請稍後再試。';

  @override
  String get heroCreateFailed => '建立房間失敗，請重試。';

  @override
  String get chatHeaderExit => 'EXIT';

  @override
  String chatHeaderOnline(int count) {
    return '$count 人在線';
  }

  @override
  String get chatHeaderE2ee => '端對端加密';

  @override
  String get chatInputPlaceholder => '輸入訊息...';

  @override
  String get chatInputSend => '傳送';

  @override
  String get chatCreateTitle => 'CHANNEL CREATED';

  @override
  String get chatCreatePassword => 'ACCESS KEY';

  @override
  String get chatCreateShareLink => '分享連結';

  @override
  String get chatCreateWarning => '請保存此金鑰。一旦遺失將無法復原。';

  @override
  String get chatCreateEnter => '進入頻道';

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
  String get chatLeaveDescription => '確定要離開嗎？';

  @override
  String get chatLeaveLastPersonWarning => '你是最後一位參與者。離開後此頻道將永久銷毀。';

  @override
  String get chatLeaveConfirm => 'EXIT';

  @override
  String get chatLeaveCancel => 'CANCEL';

  @override
  String get chatDestroyedTitle => '不留痕跡。';

  @override
  String get chatDestroyedSubtitle => '此頻道已被永久銷毀。';

  @override
  String get chatDestroyedNewChat => '建立新頻道';

  @override
  String get chatRoomFullTitle => '頻道已滿。';

  @override
  String get chatRoomFullSubtitle => '此頻道已有 2 位參與者。';

  @override
  String get chatRoomFullNewChat => '建立新頻道';

  @override
  String get chatMediaAttachFile => '附加媒體';

  @override
  String chatMediaFileTooLarge(String maxSize) {
    return '檔案超過大小上限（$maxSize）';
  }

  @override
  String get chatMediaSendingFile => '檔案傳送中...';

  @override
  String get chatMediaP2pConnecting => '正在建立安全 P2P 連線...';

  @override
  String get chatMediaP2pFailed => 'P2P 連線失敗，僅能傳送文字。';

  @override
  String get chatMediaP2pConnected => 'P2P 媒體通道就緒';

  @override
  String get chatMediaVideoLoadFailed => '影片載入失敗';

  @override
  String get chatMediaUnsupportedType => '不支援的檔案類型';

  @override
  String get boardCreateTitle => '社群已建立';

  @override
  String get boardCreateSubtitle => '建立私密社群';

  @override
  String get boardCreateButton => '建立社群';

  @override
  String get boardCreateNamePlaceholder => '社群名稱';

  @override
  String get boardCreatePassword => '社群密碼';

  @override
  String get boardCreateAdminToken => '管理員權杖';

  @override
  String get boardCreateAdminTokenWarning => '請保存此權杖 — 一旦遺失將無法復原';

  @override
  String get boardCreateShareLink => '分享連結';

  @override
  String get boardCreateEnter => '進入社群';

  @override
  String get boardHeaderEncrypted => '端對端加密';

  @override
  String get boardHeaderAdmin => '管理員面板';

  @override
  String get boardHeaderForgetPassword => '清除已儲存的密碼';

  @override
  String get boardHeaderForgetPasswordConfirm => '此裝置上儲存的密碼將被刪除。下次造訪時需要重新輸入密碼。';

  @override
  String get boardHeaderCancel => '取消';

  @override
  String get boardHeaderConfirmForget => '刪除';

  @override
  String get boardHeaderRegisterAdmin => '註冊管理員權杖';

  @override
  String get boardHeaderAdminTokenPlaceholder => '在此貼上管理員權杖';

  @override
  String get boardHeaderConfirmRegister => '註冊';

  @override
  String get boardPostPlaceholder => '寫點什麼...（支援 Markdown）';

  @override
  String get boardPostSubmit => '發佈';

  @override
  String get boardPostCompose => '發表新文章';

  @override
  String get boardPostDetail => '文章';

  @override
  String get boardPostEmpty => '還沒有任何文章';

  @override
  String get boardPostWriteFirst => '撰寫第一篇文章';

  @override
  String get boardPostRefresh => '重新整理';

  @override
  String get boardPostAttachImage => '附加圖片';

  @override
  String get boardPostMaxImages => '最多 4 張圖片';

  @override
  String get boardPostImageTooLarge => '圖片太大';

  @override
  String get boardPostUploading => '上傳中...';

  @override
  String get boardPostAttachMedia => '附加媒體';

  @override
  String boardPostMaxMedia(int count) {
    return '最多 $count 個檔案';
  }

  @override
  String boardPostVideoTooLong(int seconds) {
    return '影片過長（最長 $seconds 秒）';
  }

  @override
  String get boardPostVideoTooLarge => '壓縮後影片仍然過大';

  @override
  String get boardPostCompressing => '壓縮中...';

  @override
  String get boardPostTitlePlaceholder => '標題（選填）';

  @override
  String get boardPostInsertInline => '插入至內文';

  @override
  String get boardPostEdit => '編輯';

  @override
  String get boardPostEditTitle => '編輯文章';

  @override
  String get boardPostSave => '儲存';

  @override
  String get boardPostDelete => '刪除';

  @override
  String get boardPostAdminDelete => '刪除（管理員）';

  @override
  String get boardPostDeleteWarning => '此文章將被永久刪除，無法復原。';

  @override
  String get boardPostConfirmDelete => '刪除';

  @override
  String get boardReportTitle => '檢舉文章';

  @override
  String get boardReportSpam => '垃圾訊息';

  @override
  String get boardReportAbuse => '辱罵 / 騷擾';

  @override
  String get boardReportIllegal => '違法內容';

  @override
  String get boardReportOther => '其他';

  @override
  String get boardReportSubmit => '檢舉';

  @override
  String get boardReportCancel => '取消';

  @override
  String get boardReportAlreadyReported => '已檢舉過';

  @override
  String get boardBlindedMessage => '因社群檢舉已被遮蔽';

  @override
  String get boardAdminTitle => '管理員面板';

  @override
  String get boardAdminDestroy => '銷毀社群';

  @override
  String get boardAdminDestroyWarning => '此操作將永久刪除社群及所有文章，無法復原。';

  @override
  String get boardAdminCancel => '取消';

  @override
  String get boardAdminConfirmDestroy => '銷毀';

  @override
  String get boardDestroyedTitle => '社群已銷毀';

  @override
  String get boardDestroyedMessage => '此社群已被永久刪除。';

  @override
  String get commonSettings => '設定';

  @override
  String get commonTheme => '主題';

  @override
  String get commonLanguage => '語言';

  @override
  String get commonCopy => '複製';

  @override
  String get commonShare => '分享';

  @override
  String get commonCancel => '取消';

  @override
  String get commonConfirm => '確認';

  @override
  String get commonLoading => '載入中...';

  @override
  String get commonError => '發生錯誤';

  @override
  String get commonRetry => '重試';

  @override
  String get commonClose => '關閉';

  @override
  String get commonBack => '返回';

  @override
  String get commonDone => '完成';

  @override
  String get commonDelete => '刪除';

  @override
  String get commonSave => '儲存';

  @override
  String get commonCopied => '已複製到剪貼簿';

  @override
  String get heroBoardCta => '社群佈告欄';

  @override
  String get featureZeroFriction => '零阻力';

  @override
  String get featureZeroFrictionDesc => '不需要繁瑣的流程，一個連結就能完美連線。';

  @override
  String get featureAnonymity => '完全匿名';

  @override
  String get featureAnonymityDesc => '不需要帳號，不需要個人資料。只有對話才重要。';

  @override
  String get featureDestruction => '自動銷毀';

  @override
  String get featureDestructionDesc => '當所有人離開後，一切痕跡將永久消失。';

  @override
  String get errorRateLimit => '請求過於頻繁，請稍後再試。';

  @override
  String get errorGeneric => '發生了錯誤。';

  @override
  String get chatConnected => '端對端加密連線已建立';

  @override
  String get chatPasswordTitle => '輸入存取金鑰';

  @override
  String get chatPasswordSubtitle => '請將存取金鑰分享給你的對話夥伴';

  @override
  String get chatPasswordJoin => '加入';

  @override
  String get chatPasswordInvalid => '存取金鑰無效';

  @override
  String get chatRoomNotFound => '找不到房間';

  @override
  String get chatRoomDestroyed => '房間已被銷毀';

  @override
  String get chatExpired => '房間已過期';

  @override
  String get chatRoomFull => '房間已滿';

  @override
  String get chatCreatedTitle => '頻道已建立';

  @override
  String get chatCreatedWarning => '請儲存此金鑰，無法恢復。';

  @override
  String get chatAccessKey => '存取金鑰';

  @override
  String get chatShareLink => '分享連結';

  @override
  String get chatPeerConnected => '對方已連線';

  @override
  String chatShareMessage(String link, String password) {
    return '加入我的 BLIP 聊天！\n\n$link\n密碼：$password';
  }

  @override
  String get chatIncludeKey => '在連結中包含密碼';

  @override
  String get chatIncludeKeyWarning => '任何擁有此連結的人都可以無需輸入密碼直接加入';

  @override
  String chatShareMessageLinkOnly(String link) {
    return '加入我的 BLIP 聊天！\n\n$link';
  }

  @override
  String get chatWaitingPeer => '正在等待其他人加入...';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsTheme => '主題';

  @override
  String get settingsThemeDark => '深色模式';

  @override
  String get settingsThemeLight => '淺色模式';

  @override
  String get settingsLanguage => '語言';

  @override
  String get settingsAbout => '關於';

  @override
  String get boardTitle => '社群佈告欄';

  @override
  String get boardCreated => '社群建立成功！';

  @override
  String get boardDestroyed => '此社群已被銷毀。';

  @override
  String get boardEmpty => '還沒有任何文章。來撰寫第一篇吧！';

  @override
  String get boardWritePost => '撰寫文章';

  @override
  String get problemTitle => '你的對話保留得太久了。';

  @override
  String get problemDescription =>
      '伺服器日誌、螢幕截圖、被遺忘的群組聊天...\n不是所有的對話都需要紀錄。有些應該像煙霧一樣消散。';

  @override
  String get solutionFrictionTitle => '0 阻力';

  @override
  String get solutionFrictionDesc => '零準備。傳送連結，立即開聊。';

  @override
  String get solutionAnonymityTitle => '完全匿名';

  @override
  String get solutionAnonymityDesc => '我們不會問你是誰。不需要 ID，不需要個人資料。';

  @override
  String get solutionDestructionTitle => '徹底銷毀';

  @override
  String get solutionDestructionDesc => '除了你和收訊者之外，連我們也無法看到。';

  @override
  String get solutionAutoshredTitle => '自動粉碎';

  @override
  String get solutionAutoshredDesc => '只有最近的幾則訊息留在畫面上，較舊的訊息即時銷毀 — 無法回捲，沒有上下文。';

  @override
  String get solutionCaptureGuardTitle => '截圖防護';

  @override
  String get solutionCaptureGuardDesc => '偵測螢幕截圖及錄影行為。訊息立即模糊處理 — 什麼都截取不到。';

  @override
  String get solutionOpensourceTitle => '透明程式碼';

  @override
  String get solutionOpensourceDesc => '100% 開源。你可以透過程式碼驗證我們絕不會窺探你的對話。';

  @override
  String get communityLabel => 'NEW';

  @override
  String get communityTitle => '打造你的私密社群。全程加密。';

  @override
  String get communitySubtitle =>
      '用一組密碼建立私密社群。\n文章以無法閱讀的密文儲存 — 伺服器永遠無法看到你的內容。\nMarkdown、圖片、匿名發文。全部端對端加密。';

  @override
  String get communityCta => '建立私密社群';

  @override
  String get communityPasswordTitle => '密碼 = 鑰匙';

  @override
  String get communityPasswordDesc => '一組共享密碼加密所有內容。不需要帳號，不需要註冊。分享密碼，共享空間。';

  @override
  String get communityServerBlindTitle => '伺服器全盲';

  @override
  String get communityServerBlindDesc => '我們儲存你的文章，但永遠無法閱讀。解密金鑰絕不會離開你的裝置。';

  @override
  String get communityModerationTitle => '社群自治';

  @override
  String get communityModerationDesc => '檢舉機制搭配自動遮蔽。管理員無需閱讀內容即可維持空間安全。';

  @override
  String get philosophyText1 => 'BLIP 不是通訊軟體。它是用完即丟的通訊工具。';

  @override
  String get philosophyText2 => '我們不想留住你。說完你的話，然後離開。';

  @override
  String get footerEasterEgg => '這個頁面也可能很快就消失了。';

  @override
  String get footerSupportProtocol => '支持此協定';

  @override
  String get footerCopyright => '© 2026 BLIP PROTOCOL';

  @override
  String get footerNoRights => 'NO RIGHTS RESERVED';

  @override
  String get navHome => '首頁';

  @override
  String get navChat => '聊天';

  @override
  String get navCommunity => '社群';

  @override
  String get chatListTitle => '我的聊天室';

  @override
  String get chatListEmpty => '還沒有聊天室。\n請從首頁建立房間。';

  @override
  String get chatListCreateNew => '建立新房間';

  @override
  String get chatListJoinById => '透過房間 ID 加入';

  @override
  String get chatListJoinDialogTitle => '加入聊天室';

  @override
  String get chatListJoinDialogHint => '房間 ID 或連結';

  @override
  String get chatListJoinDialogJoin => '加入';

  @override
  String get chatListStatusActive => '進行中';

  @override
  String get chatListStatusDestroyed => '已銷毀';

  @override
  String get chatListStatusExpired => '已過期';

  @override
  String get communityListTitle => '我的社群';

  @override
  String get communityListEmpty => '尚未加入任何社群。';

  @override
  String get communityListCreate => '新建';

  @override
  String get communityListJoinById => '透過 ID 加入';

  @override
  String get communityListJoinDialogTitle => '加入社群';

  @override
  String get communityListJoinDialogHint => '輸入 Board ID';

  @override
  String get communityListJoinDialogJoin => '加入';

  @override
  String get communityListJoinedAt => '加入時間：';

  @override
  String get contactButton => '聯繫';

  @override
  String get contactConfirmTitle => '傳送通知？';

  @override
  String get contactConfirmMessage => '將會向對方傳送推播通知。聊天內容不會被分享。';

  @override
  String get contactSent => '通知已傳送';

  @override
  String get contactNotReady => '推播通知尚未就緒';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '確定';

  @override
  String get boardRefresh => '重新整理';

  @override
  String get boardAdminPanel => '管理員面板';

  @override
  String get boardAdminRegister => '註冊管理員權杖';

  @override
  String get boardAdminTokenPlaceholder => '輸入管理員權杖...';

  @override
  String get boardAdminConfirmRegister => '註冊';

  @override
  String get boardAdminForgetToken => '移除管理員權杖';

  @override
  String get boardAdminEditSubtitle => '編輯副標題';

  @override
  String get boardAdminSubtitlePlaceholder => '社群副標題（選填）';

  @override
  String get boardAdminSubtitleSave => '儲存';

  @override
  String get boardCreateSubtitlePlaceholder => '副標題（選填）';

  @override
  String get termsAgree => '我同意使用條款';

  @override
  String get termsAgreeLink => '使用條款';

  @override
  String get termsMustAgree => '繼續前請同意使用條款。';

  @override
  String get termsViewInChat => '使用條款';

  @override
  String get termsTitle => '使用條款';

  @override
  String get termsLastUpdated => '最後更新：2026年2月';

  @override
  String get termsIntro => '使用BLIP即表示你同意這些條款。它們簡短、誠實，以簡單的語言撰寫——就像我們的程式碼一樣。';

  @override
  String get termsSection1Title => 'BLIP是什麼';

  @override
  String get termsSection1Content =>
      'BLIP是一個免費的開源端對端加密臨時聊天服務。它提供使用後即銷毀的臨時通訊頻道。';

  @override
  String get termsSection2Title => '無需帳戶';

  @override
  String get termsSection2Content => 'BLIP無需用戶註冊、登入憑證或個人資料。透過臨時房間連結和共享密碼即可存取。';

  @override
  String get termsSection3Title => '可接受的使用';

  @override
  String get termsSection3Content =>
      '你同意不將BLIP用於：散布非法內容、騷擾或威脅、傳播惡意軟體、自動垃圾訊息或濫用，或任何違反法律的活動。';

  @override
  String get termsSection4Title => '資料不可復原';

  @override
  String get termsSection4Content =>
      '訊息不儲存在任何資料庫中。聊天室銷毀後，所有對話資料將永久不可逆地遺失。這是設計特性，不是限制。';

  @override
  String get termsSection5Title => '開源';

  @override
  String get termsSection5Content => 'BLIP的原始碼是公開的。程式碼的透明性是我們對隱私最有力的保證。';

  @override
  String get termsSection6Title => '服務可用性';

  @override
  String get termsSection6Content => 'BLIP按\'現況\'提供。我們不保證正常運作時間、可用性或不中斷服務。';

  @override
  String get termsSection7Title => '責任限制';

  @override
  String get termsSection7Content =>
      '在法律允許的最大範圍內，BLIP及其營運者不對因使用服務而產生的任何損害承擔責任。';

  @override
  String get termsSection8Title => '智慧財產權';

  @override
  String get termsSection8Content => 'BLIP的名稱、標誌和品牌資產受到保護。服務程式碼庫以開源授權發布。';

  @override
  String get termsSection9Title => '變更與準據法';

  @override
  String get termsSection9Content => '我們保留隨時修改這些條款的權利。在變更後繼續使用BLIP即表示接受更新後的條款。';
}
