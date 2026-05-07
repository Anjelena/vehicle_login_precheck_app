import 'dart:io';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

class _PassFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => true;
}

class _FileLogOutput extends LogOutput {
  IOSink? _sink;
  String? path;

  @override
  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    path = '${dir.path}/rfid_scanner.log';
    _sink = File(path!).openWrite(mode: FileMode.append);
  }

  @override
  void output(OutputEvent event) {
    _sink?.writeln(event.lines.join('\n'));
  }

  @override
  Future<void> destroy() async {
    try {
      await _sink?.flush();
      await _sink?.close();
    } catch (_) {}
  }
}

class AppLogger {
  static late final Logger logger;
  static final _fileOutput = _FileLogOutput();

  static Future<void> init() async {
    await _fileOutput.init();
    logger = Logger(
      filter: _PassFilter(),
      printer: SimplePrinter(printTime: true, colors: false),
      output: MultiOutput([ConsoleOutput(), _fileOutput]),
    );
    logger.i('[AppLogger] Logging to ${_fileOutput.path}');
  }

  static String _location() {
    final trace = StackTrace.current;
    final frames = trace.toString().split('\n');
    if (frames.length > 2) {
      final frame = frames[2];
      final data = frame.split('.');
      return data[0].split(' ').last;
    }
    return 'Unknown';
  }

  static void i(dynamic message) => logger.i('[${_location()}] $message');
  static void d(dynamic message) => logger.d('[${_location()}] $message');
  static void w(dynamic message) => logger.w('[${_location()}] $message');
  static void e(dynamic message) => logger.e('[${_location()}] $message');
}
