import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rfid_scanner_app/core/routing/app_routes.dart';
import 'package:rfid_scanner_app/core/session/session.dart';
import 'package:rfid_scanner_app/core/theme/app_theme.dart';
import 'package:rfid_scanner_app/features/auth/data/auth_repository.dart';
import 'package:rfid_scanner_app/features/auth/presentation/keyboard_card_reader.dart';
import 'package:rfid_scanner_app/features/auth/presentation/login_controller.dart';
import 'package:rfid_scanner_app/features/auth/presentation/serial_card_reader.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final LoginController _controller;
  late final KeyboardCardReader _keyboardReader;
  late final SerialCardReader _serialReader;
  final FocusNode _focusNode = FocusNode();
  bool _navScheduled = false;

  @override
  void initState() {
    super.initState();
    _controller = LoginController(
      authRepository: context.read<AuthRepository>(),
      session: context.read<Session>(),
    );
    _controller.addListener(_onControllerChange);
    _keyboardReader = KeyboardCardReader(onCardScanned: _controller.submitCard);
    _serialReader = SerialCardReader(onCardScanned: _controller.submitCard);
    _serialReader.start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChange);
    _controller.dispose();
    _keyboardReader.dispose();
    _serialReader.stop();
    _focusNode.dispose();
    super.dispose();
  }

  void _onControllerChange() {
    if (_controller.status == LoginStatus.success && !_navScheduled) {
      _navScheduled = true;
      // Brief delay so the operator sees "Card Authorised — Welcome, X"
      // before transitioning to prestart.
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(AppRoutes.prestart);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      body: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _keyboardReader.handleKey,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => _buildBody(
                _controller.status,
                _controller.errorMessage,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(LoginStatus status, String? errorMessage) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StatusIcon(status),
        const SizedBox(height: 20),
        _StatusText(status: status, errorMessage: errorMessage),
      ],
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon(this.status);
  final LoginStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case LoginStatus.validating:
        return const CircularProgressIndicator(
          strokeWidth: 4,
          color: AppTheme.accent,
        );
      case LoginStatus.success:
        return const Icon(Icons.check_circle, size: 100, color: AppTheme.success);
      case LoginStatus.failure:
        return const Icon(Icons.cancel, size: 100, color: AppTheme.error);
      case LoginStatus.idle:
        return Icon(
          Icons.nfc_rounded,
          size: 96,
          color: AppTheme.secondaryText.withValues(alpha: 0.5),
        );
    }
  }
}

class _StatusText extends StatelessWidget {
  const _StatusText({required this.status, required this.errorMessage});
  final LoginStatus status;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return Text(
        errorMessage!,
        style: AppTheme.headingLarge.copyWith(color: AppTheme.error),
      );
    }

    switch (status) {
      case LoginStatus.validating:
        return const Text('Verifying...', style: AppTheme.headingLarge);
      case LoginStatus.success:
        final user = context.read<Session>().user;
        return Column(
          children: [
            Text(
              'Card Authorised',
              style: AppTheme.headingLarge.copyWith(color: AppTheme.success),
            ),
            if (user != null) ...[
              const SizedBox(height: 8),
              Text(
                'Welcome, ${user.name}',
                style: AppTheme.headingMedium.copyWith(color: AppTheme.primaryText),
              ),
            ],
          ],
        );
      case LoginStatus.failure:
        return Text(
          'Card Denied',
          style: AppTheme.headingLarge.copyWith(color: AppTheme.error),
        );
      case LoginStatus.idle:
        return Text(
          'Scan your RFID card',
          style: AppTheme.headingLarge.copyWith(color: AppTheme.secondaryText),
        );
    }
  }
}
