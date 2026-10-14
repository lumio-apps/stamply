import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

/// `context.l10n.save` instead of `AppLocalizations.of(context).save`.
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// A language the app is translated into.
class AppLanguage {
  const AppLanguage(this.code, this.nativeName, this.englishName);

  final String code;

  /// The name in the language itself, e.g. "हिन्दी".
  final String nativeName;
  final String englishName;
}

const List<AppLanguage> kLanguages = [
  AppLanguage('en', 'English', 'English'),
  AppLanguage('hi', 'हिन्दी', 'Hindi'),
  AppLanguage('hy', 'Հայերեն', 'Armenian'),
  AppLanguage('zh', '中文', 'Chinese'),
  AppLanguage('es', 'Español', 'Spanish'),
  AppLanguage('ar', 'العربية', 'Arabic'),
  AppLanguage('fr', 'Français', 'French'),
  AppLanguage('bn', 'বাংলা', 'Bengali'),
  AppLanguage('pt', 'Português', 'Portuguese'),
  AppLanguage('ru', 'Русский', 'Russian'),
  AppLanguage('ur', 'اردو', 'Urdu'),
  AppLanguage('id', 'Bahasa Indonesia', 'Indonesian'),
  AppLanguage('ja', '日本語', 'Japanese'),
  AppLanguage('gu', 'ગુજરાતી', 'Gujarati'),
  AppLanguage('ta', 'தமிழ்', 'Tamil'),
  AppLanguage('te', 'తెలుగు', 'Telugu'),
  AppLanguage('mr', 'मराठी', 'Marathi'),
  AppLanguage('kn', 'ಕನ್ನಡ', 'Kannada'),
  AppLanguage('ml', 'മലയാളം', 'Malayalam'),
  AppLanguage('pa', 'ਪੰਜਾਬੀ', 'Punjabi'),
];

AppLanguage languageByCode(String code) =>
    kLanguages.firstWhere((l) => l.code == code, orElse: () => kLanguages.first);
