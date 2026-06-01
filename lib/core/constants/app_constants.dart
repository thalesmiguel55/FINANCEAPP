class AppConstants {
  AppConstants._();

  // Supabase
  // Configure com:
  // flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://SEU_PROJECT.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'SUA_ANON_KEY',
  );

  // brapi.dev API - https://brapi.dev/docs
  // Configure com: flutter run --dart-define=BRAPI_TOKEN=seu_token
  static const String brapiApiToken = String.fromEnvironment('BRAPI_TOKEN');
  static const String brapiBaseUrl = 'https://brapi.dev/api';

  // Alpha Vantage API - https://www.alphavantage.co/support/#api-key
  // Mantida como fallback para ativos internacionais.
  static const String alphaVantageApiKey = String.fromEnvironment(
    'ALPHA_VANTAGE_KEY',
    defaultValue: 'SUA_ALPHA_VANTAGE_KEY',
  );
  static const String alphaVantageBaseUrl = 'https://www.alphavantage.co/query';

  // App
  static const String appName = 'FinanceApp';
  static const String appVersion = '1.0.0';

  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String themeKey = 'theme_mode';
  static const String biometricKey = 'biometric_enabled';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Pagination
  static const int pageSize = 20;

  // Categorias de transação
  static const List<String> transactionCategories = [
    'Alimentação',
    'Transporte',
    'Moradia',
    'Saúde',
    'Educação',
    'Lazer',
    'Roupas',
    'Tecnologia',
    'Investimentos',
    'Salário',
    'Freelance',
    'Outros',
  ];
}
