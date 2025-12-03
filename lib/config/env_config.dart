class EnvConfig {
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyAPpZYwp6IjJhNDshFTxTsTaa05NxiTE3U', // Only for dev
  );
}