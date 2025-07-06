import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sosmobil_rescue_flutter/helpers/theme_notifier.dart';
import 'package:sosmobil_rescue_flutter/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Garanta que esta importação esteja aqui
import 'l10n/app_localizations.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

// Substitua toda a sua função main por esta
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carrega as variáveis do arquivo .env
  await dotenv.load(fileName: ".env");

  // Inicializa o Supabase com as variáveis carregadas do .env
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // O resto da função continua igual, carregando o tema
  final prefs = await SharedPreferences.getInstance();
  final themeIndex = prefs.getInt('themeMode') ?? ThemeMode.system.index;
  final initialTheme = ThemeMode.values[themeIndex];

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(initialTheme),
      child: const MyApp(),
    ),
  );
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        // Substitua todo o seu MaterialApp por este
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'RescueNow',

          // Configuração dos temas que já fizemos
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeNotifier.themeMode,

          // --- CONFIGURAÇÃO DE LOCALIZAÇÃO CORRETA ---
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('pt', ''), // Português
            Locale('en', ''), // Inglês
            Locale('es', ''), // Espanhol
          ],
          // --- FIM DA CONFIGURAÇÃO ---

          initialRoute: supabase.auth.currentSession == null ? '/login' : '/',
          routes: {
            '/login': (context) => const LoginScreen(),
            '/': (context) => const HomeScreen(),
          },
        );
      },
    );
  }
}
