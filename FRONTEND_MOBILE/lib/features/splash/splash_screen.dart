import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/bootstrap/app_bootstrap.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import 'widgets/brand_logo.dart';
import 'widgets/brand_wordmark.dart';
import 'widgets/splash_loading_footer.dart';

/// Branded launch screen.
///
/// Renders the Forth Ports Dundee identity over the port backdrop while
/// [AppBootstrap] performs real startup work. Progress is reflected live and,
/// once everything is ready, the app transitions to [onComplete]'s screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onComplete});

  /// Builds the destination shown once initialisation finishes.
  final WidgetBuilder onComplete;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  late final Animation<double> _fade;
  late final Animation<double> _logoScale;
  late final Animation<Offset> _wordmarkSlide;

  StreamSubscription<BootstrapProgress>? _bootstrapSub;
  BootstrapProgress _progress = const BootstrapProgress(
    value: 0,
    label: AppStrings.loading,
  );
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _entrance, curve: Curves.easeOut);
    _logoScale = Tween<double>(
      begin: 0.86,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _entrance, curve: Curves.easeOutBack));
    _wordmarkSlide =
        Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entrance,
            curve: const Interval(0.3, 1, curve: Curves.easeOutCubic),
          ),
        );

    // Start work after the first frame so [context] (and MediaQuery) is ready
    // for image pre-caching.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _entrance.forward();
      _startBootstrap();
    });
  }

  void _startBootstrap() {
    _bootstrapSub = AppBootstrap(context).run().listen(
      (BootstrapProgress progress) {
        if (!mounted) return;
        setState(() => _progress = progress);
        if (progress.isComplete) _goToNextScreen();
      },
      onError: (_) {
        // Even if a non-critical step fails, never trap the user on the splash.
        if (mounted) _goToNextScreen();
      },
    );
  }

  void _goToNextScreen() {
    if (_navigated || !mounted) return;
    _navigated = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 550),
        pageBuilder: (_, _, _) => widget.onComplete(context),
        transitionsBuilder: (_, Animation<double> animation, _, Widget child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _bootstrapSub?.cancel();
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets padding = MediaQuery.paddingOf(context);
    final double logoSize = context.scale(132, min: 0.9, max: 1.6);
    final double wordmarkSize = context.scale(30, min: 0.9, max: 1.5);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.navyDeep,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.navy,
        body: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            _Backdrop(),
            Padding(
              padding: EdgeInsets.only(
                top: padding.top + 24,
                bottom: padding.bottom + 28,
                left: 24,
                right: 24,
              ),
              child: Column(
                children: <Widget>[
                  const Spacer(flex: 5),
                  FadeTransition(
                    opacity: _fade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: BrandLogo(size: logoSize),
                    ),
                  ),
                  SizedBox(height: context.scale(28)),
                  FadeTransition(
                    opacity: _fade,
                    child: SlideTransition(
                      position: _wordmarkSlide,
                      child: BrandWordmark(fontSize: wordmarkSize),
                    ),
                  ),
                  const Spacer(flex: 7),
                  FadeTransition(
                    opacity: _fade,
                    child: SplashLoadingFooter(
                      progress: _progress.value,
                      statusLabel: AppStrings.loading,
                      barWidth: (context.screenWidth * 0.62).clamp(180, 360),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-bleed port photograph with a navy gradient overlay that keeps the top
/// third solid for the logo while letting the ship show through below.
class _Backdrop extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Image.asset(
          AppAssets.splashBackground,
          fit: BoxFit.cover,
          alignment: Alignment.bottomCenter,
          errorBuilder: (_, _, _) => const ColoredBox(color: AppColors.navy),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: <double>[0.0, 0.45, 1.0],
              colors: <Color>[
                AppColors.navy,
                Color(0x990A2240),
                Color(0xCC061528),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
