import 'l10n/l10n.dart';

/// Broad world regions used by the Explore filter.
enum Region { africa, americas, asia, europe, oceania }

const Map<Region, String> _regionCodes = {
  Region.africa:
      'AO BF BI BJ BW CD CF CG CI CM CV DJ DZ EG ER ET GA GH GM GN GQ GW KE KM LR LS LY MA MG ML MR MU MW MZ NA NE NG RW SC SD SL SN SO SS ST SZ TD TG TN TZ UG ZA ZM ZW',
  Region.americas:
      'AG AR BB BO BR BS BZ CA CL CO CR CU DM DO EC GD GT GY HN HT JM KN LC MX NI PA PE PY SR SV TT US UY VC VE',
  Region.asia:
      'AE AF AM AZ BD BH BN BT CN GE HK ID IL IN IQ IR JO JP KG KH KP KR KW KZ LA LB LK MM MN MO MV MY NP OM PH PK PS QA SA SG SY TH TJ TL TM TR TW UZ VN YE',
  Region.europe:
      'AD AL AT BA BE BG BY CH CY CZ DE DK EE ES FI FR GB GR HR HU IE IS IT LI LT LU LV MC MD ME MK MT NL NO PL PT RO RS RU SE SI SK SM UA VA XK',
  Region.oceania: 'AU FJ FM KI MH NR NZ PG PW SB TO TV VU WS',
};

final Map<String, Region> _byCode = {
  for (final e in _regionCodes.entries)
    for (final code in e.value.split(' ')) code: e.key,
};

/// The region of a country, or null for a code this app does not know.
Region? regionOf(String code) => _byCode[code];

extension RegionText on Region {
  String label(AppLocalizations l) => switch (this) {
        Region.africa => l.regionAfrica,
        Region.americas => l.regionAmericas,
        Region.asia => l.regionAsia,
        Region.europe => l.regionEurope,
        Region.oceania => l.regionOceania,
      };
}
