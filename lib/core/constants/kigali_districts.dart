// Owner: Member 1
// The three districts of Kigali, spelled exactly as they are saved in
// users.district. Use these instead of typing a district name, so the
// client and driver sides always save the same spelling.
class KigaliDistricts {
  KigaliDistricts._();

  static const String gasabo = 'Gasabo';
  static const String kicukiro = 'Kicukiro';
  static const String nyarugenge = 'Nyarugenge';

  static const List<String> all = [gasabo, kicukiro, nyarugenge];
}
