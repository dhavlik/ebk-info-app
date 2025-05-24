import '../l10n/app_localizations.dart';

class ImportantLink {
  final String title;
  final String url;
  final String icon;
  final String description;

  ImportantLink({
    required this.title,
    required this.url,
    required this.icon,
    required this.description,
  });

  static List<ImportantLink> getDefaultLinks(AppLocalizations l10n) {
    return [
      ImportantLink(
        title: l10n.website,
        url: 'https://www.eigenbaukombinat.de',
        icon: '🌐',
        description: l10n.officialWebsite,
      ),
      ImportantLink(
        title: l10n.email,
        url: 'mailto:kontakt@eigenbaukombinat.de',
        icon: '✉️',
        description: l10n.sendEmail,
      ),
      ImportantLink(
        title: l10n.officialLinkCollection,
        url: 'https://start.eigenbaukombinat.de',
        icon: '🔗',
        description: l10n.linkCollectionDescription,
      ),
      ImportantLink(
        title: l10n.address,
        url:
            'https://www.openstreetmap.org/?mlat=51.479930&mlon=11.992317&zoom=18&layers=M#map=18/51.479930/11.992317',
        icon: '📍',
        description: l10n.showLocationInOpenStreetMap,
      ),
    ];
  }
}
