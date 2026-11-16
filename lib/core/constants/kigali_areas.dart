/// A Kigali area the client can pick as pickup or drop-off.
/// Coordinates are approximate centres, which is enough for a fare estimate.
class KigaliArea {
  const KigaliArea({
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final double latitude;
  final double longitude;
}

class KigaliAreas {
  KigaliAreas._();

  static const List<KigaliArea> all = [
    KigaliArea(name: 'City Centre', latitude: -1.9441, longitude: 30.0619),
    KigaliArea(name: 'Nyabugogo', latitude: -1.9386, longitude: 30.0446),
    KigaliArea(name: 'Nyamirambo', latitude: -1.9780, longitude: 30.0420),
    KigaliArea(name: 'Gikondo', latitude: -1.9720, longitude: 30.0720),
    KigaliArea(name: 'Kicukiro', latitude: -1.9790, longitude: 30.0850),
    KigaliArea(name: 'Kanombe', latitude: -1.9680, longitude: 30.1330),
    KigaliArea(name: 'Remera', latitude: -1.9570, longitude: 30.1130),
    KigaliArea(name: 'Kimironko', latitude: -1.9535, longitude: 30.1260),
    KigaliArea(name: 'Kacyiru', latitude: -1.9390, longitude: 30.0720),
    KigaliArea(name: 'Gisozi', latitude: -1.9100, longitude: 30.0600),
  ];
}
