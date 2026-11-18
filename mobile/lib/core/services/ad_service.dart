import 'dart:async';
import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// AdMob 광고 서비스 (Singleton)
/// - 전면광고: N번에 1번 표시
/// - 오프닝광고: 3회차 실행부터 표시 (첫 2회는 스킵)
class AdService with WidgetsBindingObserver {
  AdService._();
  static final AdService instance = AdService._();

  static const _launchCountKey = 'ad_launch_count';
  static const _appOpenMinLaunches = 3; // 3회차부터 App Open 광고

  bool _initialized = false;
  Future<void>? _initializing;
  final canLoadAds = ValueNotifier<bool>(false);
  InterstitialAd? _interstitialAd;
  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;
  int _launchCount = 0;

  static String get _interstitialAdUnitId => Platform.isAndroid
      ? AppConstants.admobInterstitialAndroid
      : AppConstants.admobInterstitialIos;

  static String get _appOpenAdUnitId => Platform.isAndroid
      ? AppConstants.admobAppOpenAndroid
      : AppConstants.admobAppOpenIos;

  Future<void> init() => _initializing ??= _initialize();

  Future<void> _initialize() async {
    if (_initialized) return;

    // UMP decides whether ads may be requested before any ad format loads.
    final consentUpdate = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        await ConsentForm.loadAndShowConsentFormIfRequired((_) {});
        if (!consentUpdate.isCompleted) consentUpdate.complete();
      },
      (_) {
        if (!consentUpdate.isCompleted) consentUpdate.complete();
      },
    );
    try {
      await consentUpdate.future.timeout(const Duration(seconds: 15));
    } on TimeoutException {
      return;
    }
    if (!await ConsentInformation.instance.canRequestAds()) return;

    // iOS: ATT 권한 요청 (14.5+ 필수 — 없으면 광고 fill rate 급감)
    if (Platform.isIOS) {
      try {
        final status =
            await AppTrackingTransparency.trackingAuthorizationStatus;
        if (status == TrackingStatus.notDetermined) {
          // 첫 프레임 렌더링 후 요청 (Apple 가이드라인)
          await Future<void>.delayed(const Duration(seconds: 1));
          await AppTrackingTransparency.requestTrackingAuthorization();
        }
      } catch (e) {
        debugPrint('[BLIP] ATT request failed: $e');
      }
    }

    try {
      await MobileAds.instance.initialize();
    } catch (e) {
      debugPrint('[BLIP] MobileAds init failed: $e');
      return; // AdMob 실패 시 광고 기능 비활성 상태로 유지
    }
    _initialized = true;
    canLoadAds.value = true;

    // 런치 카운트 증가 및 저장
    try {
      final prefs = await SharedPreferences.getInstance();
      _launchCount = (prefs.getInt(_launchCountKey) ?? 0) + 1;
      await prefs.setInt(_launchCountKey, _launchCount);
    } catch (e) {
      debugPrint('[BLIP] SharedPreferences failed: $e');
    }

    _loadInterstitial();
    _loadAppOpenAd();
    WidgetsBinding.instance.addObserver(this);
  }

  Future<bool> showPrivacyOptions() async {
    if (await ConsentInformation.instance
            .getPrivacyOptionsRequirementStatus() !=
        PrivacyOptionsRequirementStatus.required) {
      return false;
    }
    await ConsentForm.showPrivacyOptionsForm((error) {
      if (error != null) throw StateError('Ad privacy form unavailable');
    });
    final allowed = await ConsentInformation.instance.canRequestAds();
    canLoadAds.value = allowed && _initialized;
    if (!allowed) {
      _interstitialAd?.dispose();
      _interstitialAd = null;
      _appOpenAd?.dispose();
      _appOpenAd = null;
    }
    return true;
  }

  /// 앱 라이프사이클 감지 — 포그라운드 복귀 시 오프닝 광고
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _showAppOpenAd();
    }
  }

  // ─── 전면광고 ───

  void _loadInterstitial() {
    if (!canLoadAds.value) return;
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          if (canLoadAds.value) {
            _interstitialAd = ad;
          } else {
            ad.dispose();
          }
        },
        onAdFailedToLoad: (_) => _interstitialAd = null,
      ),
    );
  }

  /// 전면광고 즉시 표시 (채팅 생성 등 매번 표시할 때)
  Future<bool> showInterstitial() async {
    if (_interstitialAd == null || _isShowingAd) return false;
    return _showAndDispose();
  }

  /// N번에 1번 전면광고 표시 (글 조회 등 빈도 조절 필요 시)
  /// [frequency]를 넘기면 해당 빈도 사용, 없으면 기본값
  final Map<String, int> _counters = {};

  Future<bool> maybeShowInterstitial({
    String key = 'default',
    int? frequency,
  }) async {
    final freq = frequency ?? AppConstants.interstitialFrequency;
    _counters[key] = (_counters[key] ?? 0) + 1;
    if (_counters[key]! % freq != 0) return false;
    if (_interstitialAd == null || _isShowingAd) return false;
    return _showAndDispose();
  }

  Future<bool> _showAndDispose() async {
    if (!canLoadAds.value) return false;
    final ad = _interstitialAd!;
    _interstitialAd = null;
    _isShowingAd = true;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _isShowingAd = false;
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _isShowingAd = false;
        _loadInterstitial();
      },
    );

    await ad.show();
    return true;
  }

  // ─── 오프닝(앱 오픈) 광고 ───

  void _loadAppOpenAd() {
    if (!canLoadAds.value) return;
    AppOpenAd.load(
      adUnitId: _appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          if (canLoadAds.value) {
            _appOpenAd = ad;
          } else {
            ad.dispose();
          }
        },
        onAdFailedToLoad: (_) => _appOpenAd = null,
      ),
    );
  }

  /// 오프닝 광고 표시 — 3회차 실행부터만 표시
  void _showAppOpenAd() {
    if (!canLoadAds.value) return;
    if (_launchCount < _appOpenMinLaunches) return; // 첫 2회 스킵
    if (_isShowingAd) return;
    if (_appOpenAd == null) return;

    final ad = _appOpenAd!;
    _appOpenAd = null;
    _isShowingAd = true;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _isShowingAd = false;
        _loadAppOpenAd();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _isShowingAd = false;
        _loadAppOpenAd();
      },
    );

    ad.show();
  }

  /// 초기 앱 실행 시 오프닝 광고 (init 후 호출)
  void showInitialAppOpenAd() {
    _showAppOpenAd();
  }
}
