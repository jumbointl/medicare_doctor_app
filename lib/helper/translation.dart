import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../service/languages_service.dart';

class Translation extends Translations {
  static final Map<String, Map<String, String>> _assetKeys = {};

  Map<String, Map<String, String>> get _defaultKeys => {
    'en': {
      // ... DEJA AQUÍ TODO TU MAPA ACTUAL
    },
  };

  static Future<void> loadFromAssets({
    String code = 'es',
    String scope = 'doctor_app',
  }) async {
    final data = await LanguagesService.loadLocalTranslations(
      code: code,
      scope: scope,
    );

    _assetKeys[code] = data;

    if (kDebugMode) {
      print('Loaded asset translations for $code: ${data.length}');
    }
  }

  static void printData(String code) {
    if (kDebugMode) {
      print("ASSET TRANSLATION DATA [$code]: ${_assetKeys[code]}");
    }
  }

  static bool get hasAssets => _assetKeys.isNotEmpty;

  @override
  Map<String, Map<String, String>> get keys {
    return {
      ..._defaultKeys,
      ..._assetKeys,
    };
  }
}