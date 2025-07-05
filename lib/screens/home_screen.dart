// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import 'details_screen.dart';
import 'contact_screen.dart';
import 'package:sosmobil_rescue_flutter/l10n/app_localizations.dart';
import 'package:shimmer/shimmer.dart'; // Importa o shimmer

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // A definição da stream para buscar os dados do Supabase continua a mesma.
  final _chamadosStream = Supabase.instance.client
      .from('chamados')
      .stream(primaryKey: ['id'])
      .neq('status', 'Concluído')
      .order('created_at', ascending: false);

  // Função auxiliar para obter o ícone do serviço
  IconData _getServiceIcon(String? serviceType) {
    switch (serviceType) {
      case 'Reboque Leve':
      case 'Reboque Utilitário':
      case 'Reboque Pesado':
        return Icons.car_crash_outlined;
      case 'Carga de Bateria':
        return Icons.battery_charging_full;
      case 'Troca de Pneu':
        return Icons.build_circle_outlined;
      case 'Chaveiro':
        return Icons.vpn_key_outlined;
      default:
        return Icons.miscellaneous_services;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Acessa as traduções para o idioma atual
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.activeCalls), // Usa a tradução
        // A seção 'actions' com os botões de contato e logout continua a mesma.
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
          // 1. MUDANÇA NO ESTADO DE CARREGAMENTO
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Efeito Shimmer enquanto carrega
            // Nota: Para isso funcionar, você precisa adicionar o pacote `shimmer`
            // no seu arquivo pubspec.yaml: `flutter pub add shimmer`
            return Shimmer.fromColors(
              baseColor: Colors.grey[850]!,
              highlightColor: Colors.grey[800]!,
              child: ListView.builder(
                itemCount: 5, // Mostra 5 caixas de "esqueleto"
                itemBuilder: (_, __) => Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Container(
                    height: 100.0,
                    decoration: BoxDecoration(
                      color: Colors.black
                          .withOpacity(0.4), // Cor de fundo do esqueleto
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            );
          }
          // O tratamento de erro e lista vazia continua o mesmo.
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          final chamados = snapshot.data;
          if (chamados == null || chamados.isEmpty) {
            return Center(child: Text(l10n.noActiveCalls)); // Usa a tradução
          }

          // 2. MUDANÇA NO LAYOUT DA LISTA
          return ListView.builder(
            itemCount: chamados.length,
            itemBuilder: (context, index) {
              final chamado = chamados[index];
              final serviceType = chamado['tipo_servico'] as String?;
              final address = chamado['endereco_origem'] as String?;
              final client = chamado['nome_segurado'] as String?;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                clipBehavior: Clip
                    .antiAlias, // Garante que o efeito de toque respeite as bordas
                child: InkWell(
                  // Adiciona o efeito de "ripple" (onda) ao tocar
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) =>
                          DetailsScreen(chamadoId: chamado['id']),
                    ));
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        // Ícone dinâmico baseado no tipo de serviço
                        Icon(_getServiceIcon(serviceType),
                            size: 40,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 16),
                        // Coluna com as informações de texto
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(serviceType ?? 'Serviço',
                                  style:
                                      Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 4),
                              Text(client ?? 'Cliente não informado',
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                              const SizedBox(height: 2),
                              Text(address ?? 'Endereço não informado',
                                  style: Theme.of(context).textTheme.bodySmall,
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Chip com o status
                        Chip(
                          label: Text(chamado['status'] ?? 'Pendente'),
                          backgroundColor:
                              Theme.of(context).colorScheme.surface,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
