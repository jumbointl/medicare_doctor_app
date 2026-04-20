
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'helper/get_di.dart' as di;
import 'helper/route_helper.dart';
import 'languages/language_controller.dart';
import 'controller/theme_controller.dart';
import 'languages/translation.dart';
import 'theme/dark_theme.dart';
import 'theme/light_theme.dart';
import 'utilities/app_constans.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await di.init();

  final languageController = Get.find<LanguageController>();
  await languageController.loadSavedLanguage();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return GetBuilder<ThemeController>(
      init: Get.find<ThemeController>(),
      builder: (themeController) {
        return Obx(() {
          final languageController = Get.find<LanguageController>();

          return GetMaterialApp(
            locale: languageController.currentLocale,
            fallbackLocale: const Locale('es'),
            translations: Translation(),
            title: AppConstants.appName,
            initialRoute: RouteHelper.getHomePageRoute(),
            debugShowCheckedModeBanner: false,
            theme: themeController.darkTheme ? dark : light,
            getPages: RouteHelper.routes,
          );
        });
      },
    );
  }
}
/*
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import './utilities/app_constans.dart';
import './helper/get_di.dart' as di;
import 'controller/theme_controller.dart';
import 'helper/language_storage_helper.dart';
import 'helper/route_helper.dart';
import 'helper/translation.dart';
import 'theme/dark_theme.dart';
import 'theme/light_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();

  String lngCode = await LanguageStorage.getLanguageCode();

  if (lngCode.isEmpty) {
    lngCode = "es";
    await LanguageStorage.saveLanguageCode(lngCode);
  }

  await Translation.loadFromAssets(
    code: lngCode,
    scope: 'doctor_app',
  );

  runApp(MyApp(lngCode));
}

class MyApp extends StatelessWidget {
  final String lngCode;
  const MyApp(this.lngCode, {super.key});

  Locale _parseLocale(String code) {
    if (code.contains('-')) {
      final parts = code.split('-');
      if (parts.length >= 2) {
        return Locale(parts[0], parts[1]);
      }
    }

    if (code.contains('_')) {
      final parts = code.split('_');
      if (parts.length >= 2) {
        return Locale(parts[0], parts[1]);
      }
    }

    return Locale(code);
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return GetBuilder<ThemeController>(
      builder: (themeController) {
        return GetMaterialApp(
          locale: _parseLocale(lngCode),
          fallbackLocale: const Locale('es'),
          translations: Translation(),
          title: AppConstants.appName,
          initialRoute: RouteHelper.getHomePageRoute(),
          debugShowCheckedModeBanner: false,
          theme: themeController.darkTheme ? dark : light,
          getPages: RouteHelper.routes,
        );
      },
    );
  }
}*/
