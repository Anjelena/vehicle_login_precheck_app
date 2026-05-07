import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rfid_scanner_app/core/routing/app_routes.dart';
import 'package:rfid_scanner_app/core/session/session.dart';
import 'package:rfid_scanner_app/core/theme/app_theme.dart';
import 'package:rfid_scanner_app/features/auth/data/auth_repository.dart';
import 'package:rfid_scanner_app/features/auth/presentation/login_screen.dart';
import 'package:rfid_scanner_app/features/prestart/data/prestart_repository.dart';
import 'package:rfid_scanner_app/features/prestart/presentation/prestart_screen.dart';
import 'package:rfid_scanner_app/features/welcome/presentation/welcome_screen.dart';

class App extends StatelessWidget {
  const App({
    super.key,
    required this.authRepository,
    required this.prestartRepository,
  });

  /// Injected at app startup. Replace with production implementations when
  /// integrating with the main app — these two values are the only data-layer
  /// glue points.
  final AuthRepository authRepository;
  final PrestartRepository prestartRepository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthRepository>.value(value: authRepository),
        Provider<PrestartRepository>.value(value: prestartRepository),
        ChangeNotifierProvider<Session>(create: (_) => Session()),
      ],
      child: MaterialApp(
        title: 'Vehicle Login',
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        initialRoute: AppRoutes.login,
        routes: {
          AppRoutes.login: (_) => const LoginScreen(),
          AppRoutes.prestart: (_) => const PrestartScreen(),
          AppRoutes.welcome: (_) => const WelcomeScreen(),
        },
      ),
    );
  }
}
