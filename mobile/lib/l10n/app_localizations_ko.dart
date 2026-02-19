// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get heroTitle => '말하고, 사라지세요.';

  @override
  String get heroSubtitle => '로그인 없음. 기록 없음. 흔적 없음.\n오직 지금 이 순간의 대화만 존재합니다.';

  @override
  String get heroCta => '눌러서 채팅방 개설';

  @override
  String get heroLinkShare => '복잡한 절차 없이, 링크 하나로 완벽하게 연결됩니다.';

  @override
  String get heroRateLimited => '방 생성 제한에 도달했습니다. 잠시 후 다시 시도해주세요.';

  @override
  String get heroCreateFailed => '방 생성에 실패했습니다. 다시 시도해주세요.';

  @override
  String get chatHeaderExit => 'EXIT';

  @override
  String chatHeaderOnline(int count) {
    return '$count명 접속';
  }

  @override
  String get chatHeaderE2ee => '종단간 암호화';

  @override
  String get chatInputPlaceholder => '메시지 입력...';

  @override
  String get chatInputSend => '전송';

  @override
  String get chatCreateTitle => 'CHANNEL CREATED';

  @override
  String get chatCreatePassword => 'ACCESS KEY';

  @override
  String get chatCreateShareLink => '공유 링크';

  @override
  String get chatCreateWarning => '이 비밀번호를 저장하세요. 복구할 수 없습니다.';

  @override
  String get chatCreateEnter => '채팅방 입장';

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
  String get chatLeaveDescription => '채팅을 떠나시겠습니까?';

  @override
  String get chatLeaveLastPersonWarning =>
      '당신이 마지막 참여자입니다. 퇴장 시 이 채널은 영구 파쇄됩니다.';

  @override
  String get chatLeaveConfirm => 'EXIT';

  @override
  String get chatLeaveCancel => 'CANCEL';

  @override
  String get chatDestroyedTitle => '흔적 없이 사라졌습니다.';

  @override
  String get chatDestroyedSubtitle => '이 채널은 영구적으로 파쇄되었습니다.';

  @override
  String get chatDestroyedNewChat => '새 채팅 시작';

  @override
  String get chatRoomFullTitle => '채널이 가득 찼습니다.';

  @override
  String get chatRoomFullSubtitle => '이 채널에는 이미 2명이 참여 중입니다.';

  @override
  String get chatRoomFullNewChat => '새 채팅 시작';

  @override
  String get chatMediaAttachFile => '미디어 첨부';

  @override
  String chatMediaFileTooLarge(String maxSize) {
    return '파일 크기 초과 (최대 $maxSize)';
  }

  @override
  String get chatMediaSendingFile => '파일 전송 중...';

  @override
  String get chatMediaP2pConnecting => '보안 P2P 연결 수립 중...';

  @override
  String get chatMediaP2pFailed => 'P2P 연결 실패. 텍스트만 가능합니다.';

  @override
  String get chatMediaP2pConnected => 'P2P 미디어 채널 준비 완료';

  @override
  String get chatMediaVideoLoadFailed => '동영상 로드 실패';

  @override
  String get chatMediaUnsupportedType => '지원하지 않는 파일 형식';

  @override
  String get boardCreateTitle => '커뮤니티 생성됨';

  @override
  String get boardCreateSubtitle => '프라이빗 커뮤니티 만들기';

  @override
  String get boardCreateButton => '커뮤니티 만들기';

  @override
  String get boardCreateNamePlaceholder => '커뮤니티 이름';

  @override
  String get boardCreatePassword => '커뮤니티 비밀번호';

  @override
  String get boardCreateAdminToken => '관리자 토큰';

  @override
  String get boardCreateAdminTokenWarning => '이 토큰을 저장하세요 — 복구할 수 없습니다';

  @override
  String get boardCreateShareLink => '공유 링크';

  @override
  String get boardCreateEnter => '커뮤니티 입장';

  @override
  String get boardHeaderEncrypted => '종단간 암호화';

  @override
  String get boardHeaderAdmin => '관리자 패널';

  @override
  String get boardHeaderForgetPassword => '저장된 비밀번호 삭제';

  @override
  String get boardHeaderForgetPasswordConfirm =>
      '이 기기에 저장된 비밀번호가 삭제됩니다. 다음 접속 시 비밀번호를 다시 입력해야 합니다.';

  @override
  String get boardHeaderCancel => '취소';

  @override
  String get boardHeaderConfirmForget => '삭제';

  @override
  String get boardHeaderRegisterAdmin => '관리자 토큰 등록';

  @override
  String get boardHeaderAdminTokenPlaceholder => '관리자 토큰을 붙여넣기';

  @override
  String get boardHeaderConfirmRegister => '등록';

  @override
  String get boardPostPlaceholder => '무언가 작성하세요... (마크다운 지원)';

  @override
  String get boardPostSubmit => '게시';

  @override
  String get boardPostCompose => '새 글 쓰기';

  @override
  String get boardPostDetail => '게시글';

  @override
  String get boardPostEmpty => '아직 게시물이 없습니다';

  @override
  String get boardPostWriteFirst => '첫 글을 작성해보세요';

  @override
  String get boardPostRefresh => '새로고침';

  @override
  String get boardPostAttachImage => '이미지 첨부';

  @override
  String get boardPostMaxImages => '최대 4장';

  @override
  String get boardPostImageTooLarge => '이미지가 너무 큽니다';

  @override
  String get boardPostUploading => '업로드 중...';

  @override
  String get boardPostAttachMedia => '미디어 첨부';

  @override
  String boardPostMaxMedia(int count) {
    return '최대 $count개 파일';
  }

  @override
  String boardPostVideoTooLong(int seconds) {
    return '동영상이 너무 깁니다 (최대 $seconds초)';
  }

  @override
  String get boardPostVideoTooLarge => '압축 후에도 동영상이 너무 큽니다';

  @override
  String get boardPostCompressing => '압축 중...';

  @override
  String get boardPostTitlePlaceholder => '제목 (선택사항)';

  @override
  String get boardPostInsertInline => '본문에 삽입';

  @override
  String get boardPostEdit => '수정';

  @override
  String get boardPostEditTitle => '글 수정';

  @override
  String get boardPostSave => '저장';

  @override
  String get boardPostDelete => '삭제';

  @override
  String get boardPostAdminDelete => '삭제 (관리자)';

  @override
  String get boardPostDeleteWarning => '이 게시글이 영구 삭제됩니다. 되돌릴 수 없습니다.';

  @override
  String get boardPostConfirmDelete => '삭제';

  @override
  String get boardReportTitle => '게시물 신고';

  @override
  String get boardReportSpam => '스팸';

  @override
  String get boardReportAbuse => '욕설 / 괴롭힘';

  @override
  String get boardReportIllegal => '불법 콘텐츠';

  @override
  String get boardReportOther => '기타';

  @override
  String get boardReportSubmit => '신고';

  @override
  String get boardReportCancel => '취소';

  @override
  String get boardReportAlreadyReported => '이미 신고됨';

  @override
  String get boardBlindedMessage => '커뮤니티 신고에 의해 블라인드 처리됨';

  @override
  String get boardAdminTitle => '관리자 패널';

  @override
  String get boardAdminDestroy => '커뮤니티 폭파';

  @override
  String get boardAdminDestroyWarning =>
      '커뮤니티와 모든 게시물이 영구적으로 삭제됩니다. 되돌릴 수 없습니다.';

  @override
  String get boardAdminCancel => '취소';

  @override
  String get boardAdminConfirmDestroy => '폭파';

  @override
  String get boardDestroyedTitle => '커뮤니티 폭파됨';

  @override
  String get boardDestroyedMessage => '이 커뮤니티는 영구적으로 삭제되었습니다.';

  @override
  String get commonSettings => '설정';

  @override
  String get commonTheme => '테마';

  @override
  String get commonLanguage => '언어';

  @override
  String get commonCopy => '복사';

  @override
  String get commonShare => '공유';

  @override
  String get commonCancel => '취소';

  @override
  String get commonConfirm => '확인';

  @override
  String get commonLoading => '로딩 중...';

  @override
  String get commonError => '오류가 발생했습니다';

  @override
  String get commonRetry => '재시도';

  @override
  String get commonClose => '닫기';

  @override
  String get commonBack => '뒤로';

  @override
  String get commonDone => '완료';

  @override
  String get commonDelete => '삭제';

  @override
  String get commonSave => '저장';

  @override
  String get commonCopied => '클립보드에 복사됨';

  @override
  String get heroBoardCta => '커뮤니티 게시판';

  @override
  String get featureZeroFriction => '제로 마찰';

  @override
  String get featureZeroFrictionDesc => '복잡한 절차 없이, 링크 하나로 완벽하게 연결됩니다.';

  @override
  String get featureAnonymity => '완전한 익명성';

  @override
  String get featureAnonymityDesc => '계정도, 프로필도 없습니다. 오직 대화만이 중요합니다.';

  @override
  String get featureDestruction => '자동 파쇄';

  @override
  String get featureDestructionDesc => '모두가 떠나면, 모든 흔적이 영구적으로 사라집니다.';

  @override
  String get errorRateLimit => '요청이 너무 많습니다. 잠시 후 다시 시도해주세요.';

  @override
  String get errorGeneric => '오류가 발생했습니다.';

  @override
  String get chatConnected => '종단간 암호화 연결됨';

  @override
  String get chatPasswordTitle => '접속 키를 입력하세요';

  @override
  String get chatPasswordSubtitle => '대화 상대에게 접속 키를 공유하세요';

  @override
  String get chatPasswordJoin => '참여';

  @override
  String get chatPasswordInvalid => '잘못된 접속 키';

  @override
  String get chatRoomNotFound => '방을 찾을 수 없습니다';

  @override
  String get chatRoomDestroyed => '방이 파쇄되었습니다';

  @override
  String get chatExpired => '방이 만료되었습니다';

  @override
  String get chatRoomFull => '방이 가득 찼습니다';

  @override
  String get chatCreatedTitle => '방이 생성되었습니다';

  @override
  String chatShareMessage(String link, String password) {
    return 'BLIP 채팅에 참여하세요!\n\n$link\n비밀번호: $password';
  }

  @override
  String get chatWaitingPeer => '누군가 참여하기를 기다리는 중...';

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsTheme => '테마';

  @override
  String get settingsThemeDark => '다크 모드';

  @override
  String get settingsThemeLight => '라이트 모드';

  @override
  String get settingsLanguage => '언어';

  @override
  String get settingsAbout => '정보';

  @override
  String get boardTitle => '커뮤니티 게시판';

  @override
  String get boardCreated => '커뮤니티가 생성되었습니다!';

  @override
  String get boardDestroyed => '이 커뮤니티는 파쇄되었습니다.';

  @override
  String get boardEmpty => '아직 게시글이 없습니다. 첫 글을 작성해보세요!';

  @override
  String get boardWritePost => '글 작성';

  @override
  String get problemTitle => '당신의 대화는 너무 오래 남습니다.';

  @override
  String get problemDescription =>
      '서버에 남는 로그, 캡처된 스크린샷, 잊고 있던 단톡방...\n모든 대화가 기록될 필요는 없습니다. 어떤 대화는 연기처럼 사라져야 합니다.';

  @override
  String get solutionFrictionTitle => '0 Friction';

  @override
  String get solutionFrictionDesc => '준비는 0초. 링크만 보내면 대화 시작.';

  @override
  String get solutionAnonymityTitle => 'Total Anonymity';

  @override
  String get solutionAnonymityDesc => '당신이 누구인지 묻지 않습니다. 아이디도, 프로필도 필요 없습니다.';

  @override
  String get solutionDestructionTitle => 'Complete Destruction';

  @override
  String get solutionDestructionDesc => '당신과 상대방 외엔 저희도 볼 수 없습니다.';

  @override
  String get solutionAutoshredTitle => 'Auto-Shred';

  @override
  String get solutionAutoshredDesc =>
      '최근 메시지만 화면에 남고, 오래된 메시지는 실시간으로 파쇄됩니다. 스크롤백도, 맥락도 없습니다.';

  @override
  String get solutionCaptureGuardTitle => 'Capture Guard';

  @override
  String get solutionCaptureGuardDesc =>
      '스크린샷·화면 녹화 시도를 감지합니다. 메시지가 즉시 블러 처리되어 캡처할 수 없습니다.';

  @override
  String get solutionOpensourceTitle => 'Transparent Code';

  @override
  String get solutionOpensourceDesc =>
      '100% 오픈소스. 우리가 당신의 대화를 훔쳐보지 않는다는 사실을, 코드로 직접 검증할 수 있습니다.';

  @override
  String get communityLabel => 'NEW';

  @override
  String get communityTitle => '나만의 프라이빗 커뮤니티를 만드세요. 암호화된 채로.';

  @override
  String get communitySubtitle =>
      '비밀번호 하나로 프라이빗 커뮤니티를 만드세요.\n게시글은 읽을 수 없는 암호문으로 저장됩니다 — 서버는 절대 내용을 볼 수 없습니다.\n마크다운, 이미지, 익명 게시. 모두 종단간 암호화.';

  @override
  String get communityCta => '프라이빗 커뮤니티 만들기';

  @override
  String get communityPasswordTitle => '비밀번호 = 열쇠';

  @override
  String get communityPasswordDesc =>
      '하나의 공유 비밀번호가 모든 것을 암호화합니다. 계정도, 가입도 없습니다. 비밀번호를 공유하면, 공간을 공유합니다.';

  @override
  String get communityServerBlindTitle => '서버는 눈이 멀었습니다';

  @override
  String get communityServerBlindDesc =>
      '게시글을 저장하지만, 절대 읽을 수 없습니다. 복호화 키는 당신의 기기를 떠나지 않습니다.';

  @override
  String get communityModerationTitle => '커뮤니티 자정';

  @override
  String get communityModerationDesc =>
      '신고 기반 자동 블라인드. 관리자가 내용을 읽을 필요 없이 공간을 안전하게 유지합니다.';

  @override
  String get philosophyText1 => 'BLIP은 메신저가 아닙니다. 쓰고 버리는 통신 도구입니다.';

  @override
  String get philosophyText2 => '우리는 당신을 붙잡아두고 싶지 않습니다. 할 말만 하고, 떠나세요.';

  @override
  String get footerEasterEgg => '이 페이지도 곧 사라질지 모릅니다.';

  @override
  String get footerSupportProtocol => '프로토콜 유지하기';

  @override
  String get footerCopyright => '© 2026 BLIP PROTOCOL';

  @override
  String get footerNoRights => 'NO RIGHTS RESERVED';

  @override
  String get navHome => '홈';

  @override
  String get navChat => '채팅';

  @override
  String get navCommunity => '커뮤니티';

  @override
  String get chatListTitle => '내 채팅방';

  @override
  String get chatListEmpty => '채팅방이 없습니다.\n홈 탭에서 방을 만들어보세요.';

  @override
  String get chatListCreateNew => '새 방 만들기';

  @override
  String get chatListJoinById => '방 ID로 참여';

  @override
  String get chatListJoinDialogTitle => '채팅방 참여';

  @override
  String get chatListJoinDialogHint => '방 ID 또는 링크';

  @override
  String get chatListJoinDialogJoin => '참여';

  @override
  String get chatListStatusActive => '활성';

  @override
  String get chatListStatusDestroyed => '파쇄됨';

  @override
  String get chatListStatusExpired => '만료됨';

  @override
  String get communityListTitle => '내 커뮤니티';

  @override
  String get communityListEmpty => '아직 참여한 커뮤니티가 없습니다.';

  @override
  String get communityListCreate => '새로 만들기';

  @override
  String get communityListJoinById => 'ID로 참여';

  @override
  String get communityListJoinDialogTitle => '커뮤니티 참여';

  @override
  String get communityListJoinDialogHint => '보드 ID 입력';

  @override
  String get communityListJoinDialogJoin => '참여';

  @override
  String get communityListJoinedAt => '참여일:';

  @override
  String get contactButton => '연락하기';

  @override
  String get contactConfirmTitle => '알림을 보낼까요?';

  @override
  String get contactConfirmMessage => '상대방에게 푸시 알림이 전송됩니다. 채팅 내용은 공유되지 않습니다.';

  @override
  String get contactSent => '알림이 전송되었습니다';

  @override
  String get contactNotReady => '아직 푸시 알림을 사용할 수 없습니다';

  @override
  String get cancel => '취소';

  @override
  String get confirm => '확인';

  @override
  String get boardRefresh => '새로고침';

  @override
  String get boardAdminPanel => '관리자 패널';

  @override
  String get boardAdminRegister => '관리자 토큰 등록';

  @override
  String get boardAdminTokenPlaceholder => '관리자 토큰 입력...';

  @override
  String get boardAdminConfirmRegister => '등록';

  @override
  String get boardAdminForgetToken => '관리자 토큰 해제';
}
