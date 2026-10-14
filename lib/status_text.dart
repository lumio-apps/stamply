import 'l10n/l10n.dart';
import 'models.dart';

/// Translated texts for entry statuses and rules.
extension EntryStatusText on EntryStatus {
  String label(AppLocalizations l) => switch (this) {
        EntryStatus.visaFree => l.statusVisaFree,
        EntryStatus.visaOnArrival => l.statusVoa,
        EntryStatus.eta => l.statusEta,
        EntryStatus.eVisa => l.statusEvisa,
        EntryStatus.visaRequired => l.statusVisaRequired,
        EntryStatus.noAdmission => l.statusNoAdmission,
      };

  /// Big headline on the result screen.
  String headline(AppLocalizations l) => switch (this) {
        EntryStatus.visaFree => l.headlineVisaFree,
        EntryStatus.visaOnArrival => l.headlineVoa,
        EntryStatus.eta => l.headlineEta,
        EntryStatus.eVisa => l.headlineEvisa,
        EntryStatus.visaRequired => l.headlineVisaRequired,
        EntryStatus.noAdmission => l.headlineNoAdmission,
      };

  /// Text inside the round stamp.
  String stampText(AppLocalizations l) => switch (this) {
        EntryStatus.visaFree => l.stampVisaFree,
        EntryStatus.visaOnArrival => l.stampVoa,
        EntryStatus.eta => l.stampEta,
        EntryStatus.eVisa => l.stampEvisa,
        EntryStatus.visaRequired => l.stampVisaRequired,
        EntryStatus.noAdmission => l.stampNoAdmission,
      };

  String explanation(AppLocalizations l) => switch (this) {
        EntryStatus.visaFree => l.explainVisaFree,
        EntryStatus.visaOnArrival => l.explainVoa,
        EntryStatus.eta => l.explainEta,
        EntryStatus.eVisa => l.explainEvisa,
        EntryStatus.visaRequired => l.explainVisaRequired,
        EntryStatus.noAdmission => l.explainNoAdmission,
      };
}

extension VisaRuleText on VisaRule {
  /// "Visa-free · 90 d" for pills.
  String shortLabel(AppLocalizations l) => status == EntryStatus.visaFree && days != null
      ? '${status.label(l)} · ${l.daysShort(days!)}'
      : status.label(l);

  /// "Stay up to 90 days", or null when there is nothing to say.
  String? stayText(AppLocalizations l) {
    final d = days;
    if (d == null) {
      return status == EntryStatus.visaFree ? l.stayNotListed : null;
    }
    return l.stayUpTo(d);
  }
}
