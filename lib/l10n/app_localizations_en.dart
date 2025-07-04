// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get activeCalls => 'Active Calls';

  @override
  String get noActiveCalls => 'No active calls found.';

  @override
  String get contactBase => 'Contact Base';

  @override
  String get logout => 'Logout';

  @override
  String get callBase => 'Call Base';

  @override
  String get sendWhatsApp => 'Send WhatsApp';

  @override
  String get sendEmail => 'Send Email';
}
