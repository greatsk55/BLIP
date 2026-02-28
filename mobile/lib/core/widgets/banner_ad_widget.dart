import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../constants/app_constants.dart';

/// 재사용 가능한 AdMob 배너 광고 위젯
/// - Adaptive banner: 디바이스 화면 너비에 맞게 자동 확장
/// - 다른 화면 갔다가 복귀 시 자동 리로드 (플랫폼 뷰 렌더링 복구)
/// - 로드 실패 시 공간 차지 없음 (SizedBox.shrink)
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _wasHidden = false;

  static String get _adUnitId => Platform.isAndroid
      ? AppConstants.admobBannerAndroid
      : AppConstants.admobBannerIos;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isCurrent = ModalRoute.of(context)?.isCurrent ?? true;

    if (!isCurrent) {
      // 다른 풀스크린 라우트가 위에 쌓임 → 숨겨진 상태
      _wasHidden = true;
      return;
    }

    // 화면이 다시 보이는 상태
    if (_wasHidden) {
      // 복귀: 기존 광고 해제 후 새로 로드 (플랫폼 뷰 렌더링 이슈 방지)
      _wasHidden = false;
      _disposeAd();
      _loadAd();
    } else if (_bannerAd == null && !_isLoaded) {
      // 최초 로드
      _loadAd();
    }
  }

  void _loadAd() {
    final width = MediaQuery.of(context).size.width.truncate();
    final adSize = AdSize(width: width, height: 50);

    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[BLIP] BannerAd failed: code=${error.code} '
              'domain=${error.domain} message=${error.message}');
          ad.dispose();
          if (mounted) setState(() => _bannerAd = null);
        },
      ),
    )..load();
  }

  void _disposeAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isLoaded = false;
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
