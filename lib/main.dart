// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- ALTERAÇÃO 1: Importar o pacote dotenv ---
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'constants.dart';
import 'package:sosmobil_rescue_flutter/l10n/app_localizations.dart';
import 'helpers/coordinate_finder_screen.dart';

Future<void> main() async {
  // Garante que os Widgets do Flutter sejam inicializados
  WidgetsFlutterBinding.ensureInitialized();

  // --- ALTERAÇÃO 2: Carregar as variáveis de ambiente do arquivo .env ---
  // Esta linha DEVE vir antes da inicialização do Supabase.
  await dotenv.load(fileName: ".env");

  // Inicializa o Supabase usando as chaves carregadas pelo dotenv
  // (através do arquivo constants.dart)
  await Supabase.initialize(
    url: supabaseUrl, // Modificado de SUPABASE_URL para supabaseUrl
    anonKey:
        supabaseAnnonKey, // Modificado de SUPABASE_ANON_KEY para supabaseAnnonKey
  );
  runApp(const MyApp());
}

// Cliente Supabase global para fácil acesso
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RescueNow',
      // --- CONFIGURAÇÃO DE LOCALIZAÇÃO ---
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
      theme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF3B82F6), // Azul de destaque
        scaffoldBackgroundColor: const Color(0xFF18181B), // Cinza mais escuro
        cardColor: const Color(0xFF27272A), // Cinza para os cards
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6), // Azul de destaque
            foregroundColor: Colors.white, // Texto branco
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3B82F6), // Azul
          secondary: Colors.orange, // Laranja como cor secundária
          error: Colors.redAccent,
          surface: Color(0xFF27272A), // Superfície dos componentes
        ),
      ),
      // Define a rota inicial baseada no estado de login
      initialRoute: supabase.auth.currentSession == null ? '/login' : '/',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/': (context) => const HomeScreen(),
      },
      /* home: const CoordinateFinderScreen(), */
    );
  }
}
