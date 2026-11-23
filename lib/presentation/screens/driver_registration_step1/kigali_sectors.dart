import 'package:imuka_kigali/core/constants/kigali_districts.dart';

/// The 35 sectors of the City of Kigali, grouped by the district each one
/// belongs to. A driver picks the sectors they usually work from.
const Map<String, List<String>> kigaliSectorsByDistrict = {
  KigaliDistricts.gasabo: [
    'Bumbogo',
    'Gatsata',
    'Gikomero',
    'Gisozi',
    'Jabana',
    'Jali',
    'Kacyiru',
    'Kimihurura',
    'Kimironko',
    'Kinyinya',
    'Ndera',
    'Nduba',
    'Remera',
    'Rusororo',
    'Rutunga',
  ],
  KigaliDistricts.kicukiro: [
    'Gahanga',
    'Gatenga',
    'Gikondo',
    'Kagarama',
    'Kanombe',
    'Kicukiro',
    'Kigarama',
    'Masaka',
    'Niboye',
    'Nyarugunga',
  ],
  KigaliDistricts.nyarugenge: [
    'Gitega',
    'Kanyinya',
    'Kigali',
    'Kimisagara',
    'Mageragere',
    'Muhima',
    'Nyakabanda',
    'Nyamirambo',
    'Nyarugenge',
    'Rwezamenyo',
  ],
};

/// Returns the district that [sector] is in, for example "Gasabo" for
/// "Kimihurura", or null if [sector] is not a Kigali sector.
String? districtOfSector(String sector) {
  for (final entry in kigaliSectorsByDistrict.entries) {
    if (entry.value.contains(sector)) {
      return entry.key;
    }
  }
  return null;
}
