class AppConstants{
  static const appName="SEMedicare Doctor"; //current app name
  static const apiKey = "solexpress_2026_api_key_x9LmP2Qa7vK81"; //

  // Habilita la entrada a LoginDevPage (login para desarrollo + impersonate
  // opcional por email). Default = true. El nombre refleja la decisión de
  // Pablo: la feature de impersonate es para debugear bugs reportados por
  // clientes reales en prod, así que se activa cuando el build apunta a
  // entorno productivo. Bajar a false para esconder la entrada en builds
  // de QA / desarrollo local.
  static const bool isProductionMode = true;
}