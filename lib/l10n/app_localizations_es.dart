// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get activeCalls => 'Llamadas Activas';

  @override
  String get noActiveCalls => 'No se encontraron llamadas activas.';

  @override
  String get contactBase => 'Contactar con la Base';

  @override
  String get logout => 'Cerrar Sesión';

  @override
  String get callBase => 'Llamar a la Base';

  @override
  String get sendWhatsApp => 'Enviar WhatsApp';

  @override
  String get sendEmail => 'Enviar Correo Electrónico';
}
