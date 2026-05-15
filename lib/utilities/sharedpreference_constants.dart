class SharedPreferencesConstants{
  static const String token = 'token';
  // Dynamic-key (rotating HMAC, 2026-05-08). Server emite junto al token
  // en login. Sent en header `x-dynamic-key` en cada request autenticado.
  static const String dynamicKey = 'dynamic_key';
  static const String theme = 'theme';
  static const String uid = 'uid';
  // doctor_id de la tabla `doctors`. Lo persistimos en login para que
  // los services (DoctorsService, AppointmentService, DashboardService)
  // filtren por el doctor real, no por user_id. Wendy = user_id 12,
  // doctor_id 5; antes se mezclaban y traía 0 resultados.
  static const String doctorId = 'doctor_id';
  static const String phone = 'phone';
  static const String name = 'name';
  static const String login = 'login';
  static const String email = 'email';
  static const String password = 'password';
  static const String crownImage = 'crownImage';
  static const String clinicId = 'clinicId';
  static const String languageCode = 'language_code';
  static const String allLanguages = 'languages';

  static String loginProvider='login_provider';

  static String googleLoginAt='google_login_at';

  // Refresh-token Fase 2 (2026-05-13). Backend Node emite refresh_token
  // junto al session-JWT en login. Lo usamos para renovar el JWT (12h)
  // sin pedir re-login. Persistimos también timestamps para diagnóstico
  // y para futura policy de expiración cliente-side.
  static const String refreshToken = 'refresh_token';
  static const String refreshTokenCreatedAt = 'refresh_token_created_at';
  static const String sessionTokenCreatedAt = 'session_token_created_at';

  // Auditoría / banner UI cuando un dev (Super Admin/Developer) está
  // suplantando a otro usuario via POST /v1/login/dev. Persistidos al
  // hacer login con impersonate_email; vacíos en login normal.
  static const String impersonatorId = 'impersonator_id';
  static const String impersonatorEmail = 'impersonator_email';
}