import 'package:flutter/foundation.dart';
import 'dart:io';

class AppConfig {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    }
    if (Platform.isAndroid) {
      // IP lokal laptop Anda agar HP Vivo Anda bisa terhubung
      return 'http://10.21.178.241:3000';
    }
    // Desktop (Windows/macOS/Linux)
    return 'http://localhost:3000';
  }
}
