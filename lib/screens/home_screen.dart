import 'dart:collection'; // 1. Importado para usar o HashSet
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sosmobil_rescue_flutter/helpers/theme_notifier.dart';
import 'package:sosmobil_rescue_flutter/l10n/app_localizations.dart';
import 'package:sosmobil_rescue_flutter/screens/contact_screen.dart';
import 'package:sosmobil_rescue_flutter/screens/details_screen.dart';
import 'package:sosmobil_rescue_flutter/screens/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Stream<List<Map<String, dynamic>>> _chamadosStream;
  final AudioPlayer _audioPlayer = AudioPlayer();

  // 2. Novas variáveis para a lógica de notificação robusta
  final HashSet<String> _seenCallIds = HashSet<String>();
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    _initializeStream();
  }

  void _initializeStream() {
    _chamadosStream = Supabase.instance.client
        .from('chamados')
        .stream(primaryKey: ['id'])
        .neq('status', 'Concluído')
        .order('created_at', ascending: false);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playNotificationSound() async {
    try {
      await _audioPlayer.play(AssetSource('audio/notification.mp3'));
    } catch (e) {
      debugPrint("Erro ao tocar o som: $e");
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _initializeStream();
    });
  }

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
    final l10n = AppLocalizations.of(context)!;
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.activeCalls),
        actions: [
          IconButton(
            icon: Icon(
              Provider.of<ThemeNotifier>(context).themeMode == ThemeMode.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            onPressed: () => themeNotifier.toggleTheme(),
            tooltip: 'Alterar Tema',
          ),
          IconButton(
            icon: const Icon(Icons.support_agent),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ContactScreen()),
              );
            },
            tooltip: l10n.contactBase,
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
            tooltip: l10n.logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _chamadosStream,
          builder: (context, snapshot) {
            // 3. Lógica do Shimmer e de notificação ATUALIZADA
            if (!snapshot.hasData && _isInitialLoad) {
              return Shimmer.fromColors(
                baseColor: Colors.grey[850]!,
                highlightColor: Colors.grey[800]!,
                child: ListView.builder(
                  itemCount: 5,
                  itemBuilder: (_, __) => Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Container(
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              );
            }
            if (snapshot.hasError) {
              return Center(child: Text('Erro: ${snapshot.error}'));
            }

            final chamados = snapshot.data ?? [];

            // --- NOVA LÓGICA DE NOTIFICAÇÃO POR ID ---
            if (snapshot.hasData) {
              if (_isInitialLoad) {
                // No primeiro carregamento, apenas preenche a lista de IDs vistos
                for (var chamado in chamados) {
                  _seenCallIds.add(chamado['id'].toString());
                }
                _isInitialLoad = false;
              } else {
                // Para atualizações futuras, verifica se há novos IDs
                for (var chamado in chamados) {
                  final callId = chamado['id'].toString();
                  if (!_seenCallIds.contains(callId)) {
                    _playNotificationSound();
                    _seenCallIds
                        .add(callId); // Adiciona para não notificar de novo
                  }
                }
              }
            }
            // --- FIM DA NOVA LÓGICA ---

            if (chamados.isEmpty) {
              return Center(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(child: Text(l10n.noActiveCalls)),
                  ),
                ),
              );
            }

            return ListView.builder(
              itemCount: chamados.length,
              itemBuilder: (context, index) {
                final chamado = chamados[index];
                final serviceType = chamado['tipo_servico'] as String?;
                final address = chamado['endereco_origem'] as String?;
                final client = chamado['nome_segurado'] as String?;

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
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
                          Icon(_getServiceIcon(serviceType),
                              size: 40,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 16),
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
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                    overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
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
      ),
    );
  }
}
