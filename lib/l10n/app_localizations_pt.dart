// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get activeCalls => 'Chamados Ativos';

  @override
  String get noActiveCalls => 'Nenhum chamado ativo encontrado.';

  @override
  String get contactBase => 'Contato com a Base';

  @override
  String get logout => 'Sair';

  @override
  String get callBase => 'Ligar para a Base';

  @override
  String get sendWhatsApp => 'Enviar WhatsApp';

  @override
  String get sendEmail => 'Enviar E-mail';
}
