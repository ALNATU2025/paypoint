/// Backend base URL. Override at build time with
/// `flutter build apk --dart-define=API_BASE_URL=https://your-api.example.com`.
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://paypoint-backend-aj52.onrender.com',
);
