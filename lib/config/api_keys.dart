/// Build-time configuration. Keep real keys in an ignored local JSON file.
class ApiKeys {
  static const String rawgApiKey = String.fromEnvironment('RAWG_API_KEY');
}
