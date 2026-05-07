import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rfid_scanner_app/core/routing/app_routes.dart';
import 'package:rfid_scanner_app/core/session/session.dart';
import 'package:rfid_scanner_app/core/theme/app_theme.dart';

/// Terminal screen reached after a successful login + prestart submission.
///
/// For chunk 2: shows the operator name and a live clock, plus a manual
/// logout button. Chunk 3 will replace the manual logout with a power-loss
/// trigger and 10-second sleep timer.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  Timer? _clock;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  void _logout() {
    context.read<Session>().logout();
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<Session>().user;
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                color: AppTheme.secondaryText,
                tooltip: 'Logout',
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    user != null ? 'Welcome, ${user.name}' : 'Welcome',
                    style: AppTheme.headingLarge.copyWith(fontSize: 36),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _formatTime(_now),
                    style: const TextStyle(
                      color: AppTheme.secondaryText,
                      fontSize: 28,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w300,
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

  String _formatTime(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
  }
}
