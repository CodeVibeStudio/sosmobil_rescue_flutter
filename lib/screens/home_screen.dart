// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import 'details_screen.dart';
import 'contact_screen.dart';
import 'package:sosmobil_rescue_flutter/l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _chamadosStream = Supabase.instance.client
      .from('chamados')
      .stream(primaryKey: ['id'])
      .neq('status', 'Concluído')
      .order('created_at', ascending: false);

  @override
  Widget build(BuildContext context) {
    // Acessa as traduções para o idioma atual
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.activeCalls), // Usa a tradução
        actions: [
          IconButton(
            icon: const Icon(Icons.support_agent),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ContactScreen()),
              );
            },
            tooltip: l10n.contactBase, // Usa a tradução
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            tooltip: l10n.logout, // Usa a tradução
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _chamadosStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          final chamados = snapshot.data;
          if (chamados == null || chamados.isEmpty) {
            return Center(child: Text(l10n.noActiveCalls)); // Usa a tradução
          }

          return ListView.builder(
            itemCount: chamados.length,
            itemBuilder: (context, index) {
              final chamado = chamados[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text(
                    chamado['tipo_servico'] ?? 'Serviço não informado',
                  ),
                  subtitle: Text(
                    chamado['endereco_origem'] ?? 'Endereço não informado',
                  ),
                  trailing: Chip(
                    label: Text(chamado['status'] ?? 'Pendente'),
                    backgroundColor: Colors.blueGrey,
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            DetailsScreen(chamadoId: chamado['id']),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
