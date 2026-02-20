import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../constants/app_constants.dart';

/// AdMob 광고 서비스 (Singleton)
/// - 전면광고: N번에 1번 표시
/// - 오프닝광고: 앱 실행 / 포그라운드 복귀 시 표시
class AdService with WidgetsBindingObserver {
  AdService._();
  static final AdService instance = AdService._();

  bool _initialized = false;
  InterstitialAd? _interstitialAd;
  AppOpenAd? _appOpenAd;
  int _actionCount = 0;
  bool _isShowingAd = false;

  static String get _interstitialAdUnitId => Platform.isAndroid
      ? AppConstants.admobInterstitialAndroid
      : AppConstants.admobInterstitialIos;

  static String get _appOpenAdUnitId => Platform.isAndroid
      ? AppConstants.admobAppOpenAndroid
      : AppConstants.admobAppOpenIos;

  Future<void> init() async {
    if (_initialized) return;
    await MobileAds.instance.initialize();
    _initialized = true;
    _loadInterstitial();
    _loadAppOpenAd();
    WidgetsBinding.instance.addObserver(this);
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
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (_) => _interstitialAd = null,
      ),
    );
  }

  /// 액션 수행 시 호출 — N번에 1번 전면광고 표시
  Future<bool> maybeShowInterstitial() async {
    _actionCount++;
    if (_actionCount % AppConstants.interstitialFrequency != 0) return false;
    if (_interstitialAd == null) return false;

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
    AppOpenAd.load(
      adUnitId: _appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) => _appOpenAd = ad,
        onAdFailedToLoad: (_) => _appOpenAd = null,
      ),
    );
  }

  /// 오프닝 광고 표시 (앱 실행 / 포그라운드 복귀)
  void _showAppOpenAd() {
    if (_isShowingAd) return; // 다른 광고 표시 중이면 스킵
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
