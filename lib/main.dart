import 'package:flutter/material.dart';
import 'package:rfid_scanner_app/app.dart';
import 'package:rfid_scanner_app/core/db/app_database.dart';
import 'package:rfid_scanner_app/core/logging/app_logger.dart';
import 'package:rfid_scanner_app/features/auth/data/sqlite_auth_repository.dart';
import 'package:rfid_scanner_app/features/prestart/data/sqlite_prestart_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLogger.init();

  final database = await AppDatabase.open();
  final authRepository = SqliteAuthRepository(database.db);
  final prestartRepository = SqlitePrestartRepository(database.db);

  runApp(App(
    authRepository: authRepository,
    prestartRepository: prestartRepository,
  ));
}
