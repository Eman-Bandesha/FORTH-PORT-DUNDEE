import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/token_storage.dart';
import '../constants/app_assets.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/items/data/items_repository.dart';
import '../../features/movements/data/movements_repository.dart';

/// A single, labelled startup task.
typedef BootstrapStep = ({String label, Future<void> Function() run});

/// Snapshot of bootstrap progress, emitted as initialisation advances.
@immutable
class BootstrapProgress {
  const BootstrapProgress({required this.value, required this.label});

  /// Completion ratio in the range `0.0`–`1.0`.
  final double value;

  /// Human-readable description of the step that just completed.
  final String label;

  bool get isComplete => value >= 1.0;
}

/// Orchestrates everything that must be ready before the first screen renders.
///
/// The work is modelled as an ordered list of [BootstrapStep]s so progress can
/// be reported deterministically to the splash screen. Image pre-caching needs
/// a [BuildContext], so it is injected here and runs as one of the steps —
/// guaranteeing the brand artwork is decoded before the UI shows it.
class AppBootstrap {
  AppBootstrap(this._context);

  final BuildContext _context;

  /// Minimum time the splash stays visible, so fast cold-starts still feel
  /// intentional rather than flashing past the user.
  static const Duration _minimumSplashDuration = Duration(milliseconds: 1800);

  late final List<BootstrapStep> _steps = <BootstrapStep>[
    (label: 'Preparing interface', run: _configureSystemChrome),
    (label: 'Loading brand assets', run: _precacheArtwork),
    (label: 'Initialising services', run: _warmUpServices),
    (label: 'Finalising', run: _finalise),
  ];

  /// Runs all startup steps in order, emitting progress as a [Stream].
  ///
  /// A minimum splash duration is enforced in parallel with the real work so
  /// the experience is smooth regardless of device speed.
  Stream<BootstrapProgress> run() async* {
    final Stopwatch stopwatch = Stopwatch()..start();
    final int total = _steps.length;

    yield const BootstrapProgress(value: 0, label: 'Starting up');

    for (int i = 0; i < total; i++) {
      final BootstrapStep step = _steps[i];
      await step.run();
      yield BootstrapProgress(value: (i + 1) / total, label: step.label);
    }

    final Duration remaining = _minimumSplashDuration - stopwatch.elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }

    yield const BootstrapProgress(value: 1, label: 'Ready');
  }

  Future<void> _configureSystemChrome() async {
    // Lock to portrait — the stock workflow is designed vertically.
    await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  Future<void> _precacheArtwork() async {
    if (!_context.mounted) return;
    await Future.wait<void>(<Future<void>>[
      precacheImage(const AssetImage(AppAssets.logo), _context),
      precacheImage(const AssetImage(AppAssets.splashBackground), _context),
    ]);
  }

  Future<void> _warmUpServices() async {
    ItemsRepository.enableApi();
    MovementsRepository.enableApi();
    AuthRepository.mockMode = false;
    await TokenStorage.load();
    await AuthRepository.instance.restoreSession();
  }

  Future<void> _finalise() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }
}
