// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Importa o pacote de localização
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'constants.dart';
import 'package:sosmobil_rescue_flutter/l10n/app_localizations.dart';
import 'helpers/coordinate_finder_screen.dart';

Future<void> main() async {
  // Garante que os Widgets do Flutter sejam inicializados
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Supabase
  await Supabase.initialize(
    url: SUPABASE_URL,
    anonKey: SUPABASE_ANON_KEY,
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
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF1F1F1F),
        cardColor: const Color(0xFF2C2C2C),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        colorScheme: ColorScheme.dark(
          primary: Colors.blue.shade300,
          secondary: Colors.teal.shade300,
          error: Colors.red.shade400,
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
