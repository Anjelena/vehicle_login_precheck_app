import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rfid_scanner_app/core/power/power_monitor.dart';
import 'package:rfid_scanner_app/core/power/power_sleep_coordinator.dart';
import 'package:rfid_scanner_app/core/power/power_shutdown_overlay.dart';
import 'package:rfid_scanner_app/core/routing/app_routes.dart';
import 'package:rfid_scanner_app/core/session/session.dart';
import 'package:rfid_scanner_app/core/theme/app_theme.dart';
import 'package:rfid_scanner_app/features/auth/data/auth_repository.dart';
import 'package:rfid_scanner_app/features/auth/presentation/login_screen.dart';
import 'package:rfid_scanner_app/features/no_power/presentation/no_power_screen.dart';
import 'package:rfid_scanner_app/features/prestart/data/prestart_repository.dart';
import 'package:rfid_scanner_app/features/prestart/presentation/prestart_screen.dart';
import 'package:rfid_scanner_app/features/welcome/presentation/welcome_screen.dart';

class App extends StatelessWidget {
  App({
    super.key,
    required this.authRepository,
    required this.prestartRepository,
    required this.powerMonitor,
  });

  /// Injected at app startup. Replace with production implementations when
  /// integrating with the main app — these two values are the only data-layer
  /// glue points.
  final AuthRepository authRepository;
  final PrestartRepository prestartRepository;

  /// Started in `main()` before `runApp` so that `hasPower` reflects the real
  /// state and we can pick the correct initial route.
  final PowerMonitor powerMonitor;

  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final initialRoute =
        powerMonitor.hasPower ? AppRoutes.login : AppRoutes.noPower;

    return MultiProvider(
      providers: [
        Provider<AuthRepository>.value(value: authRepository),
        Provider<PrestartRepository>.value(value: prestartRepository),
        ChangeNotifierProvider<PowerMonitor>.value(value: powerMonitor),
        ChangeNotifierProvider<Session>(create: (_) => Session()),
        ChangeNotifierProxyProvider2<PowerMonitor, Session,
            PowerSleepCoordinator>(
          create: (ctx) => PowerSleepCoordinator(
            powerMonitor: ctx.read<PowerMonitor>(),
            session: ctx.read<Session>(),
            navigatorKey: _navigatorKey,
          ),
          update: (_, __, ___, previous) => previous!,
        ),
      ],
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'Vehicle Login',
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        initialRoute: initialRoute,
        routes: {
          AppRoutes.login: (_) => const LoginScreen(),
          AppRoutes.prestart: (_) => const PrestartScreen(),
          AppRoutes.welcome: (_) => const WelcomeScreen(),
          AppRoutes.noPower: (_) => const NoPowerScreen(),
        },
        builder: (context, child) => Stack(
          children: [
            child ?? const SizedBox.shrink(),
            const PowerShutdownOverlay(),
          ],
        ),
      ),
    );
  }
}
