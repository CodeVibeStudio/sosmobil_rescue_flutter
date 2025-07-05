// lib/constants.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Busca a URL do Supabase do arquivo .env
final String supabaseUrl = dotenv.env['SUPABASE_URL']!;

// Busca a chave Anon do Supabase do arquivo .env
final String supabaseAnnonKey = dotenv.env['SUPABASE_ANON_KEY']!;
