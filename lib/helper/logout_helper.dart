import 'package:doctor_app/helper/route_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utilities/sharedpreference_constants.dart';

Future<void> forceLogoutDoctorApp() async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.remove(SharedPreferencesConstants.token);
  await prefs.remove(SharedPreferencesConstants.uid);
  await prefs.remove(SharedPreferencesConstants.name);
  await prefs.remove(SharedPreferencesConstants.email);
  await prefs.remove(SharedPreferencesConstants.password);
  await prefs.remove(SharedPreferencesConstants.clinicId);
  await prefs.setBool(SharedPreferencesConstants.login, false);
  await prefs.remove(SharedPreferencesConstants.googleLoginAt);
  await prefs.remove(SharedPreferencesConstants.loginProvider);
  // Refresh-token Fase 2 (2026-05-13). Limpiar también las keys de
  // refresh para que un logout real (manual o por session expirada
  // sin posibilidad de refresh) deje el storage limpio.
  await prefs.remove(SharedPreferencesConstants.refreshToken);
  await prefs.remove(SharedPreferencesConstants.refreshTokenCreatedAt);
  await prefs.remove(SharedPreferencesConstants.sessionTokenCreatedAt);

  try {
    await FirebaseAuth.instance.signOut();
  } catch (_) {}

  try {
    final googleSignIn = GoogleSignIn.instance;
    await googleSignIn.initialize();
    await googleSignIn.disconnect();
  } catch (_) {
    try {
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.signOut();
    } catch (_) {}
  }

  Get.offAllNamed(RouteHelper.getLoginPageRoute());
}