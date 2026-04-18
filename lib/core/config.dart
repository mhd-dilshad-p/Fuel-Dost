class AppConfig {
  static const String orsApiKey = String.fromEnvironment(
    'ORS_API_KEY',
    defaultValue: 'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjdjZTU3M2NiYTA3YzQ5NTdiM2IyZjVkMmI5YzYyYWY0IiwiaCI6Im11cm11cjY0In0=',
  );

  static const String indianApiKey = String.fromEnvironment(
    'INDIAN_API_KEY',
    defaultValue: 'sk-live-iRkVVnefSOj6I53zUCztFUvf6Rb7Jhki4yBIDw7A',
  );
}
