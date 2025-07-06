// lib/screens/damage_marking_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sosmobil_rescue_flutter/screens/accessories_signature_screen.dart';

// Enum para o tipo de avaria
enum DamageType { none, batido, riscado }

class DamageMarkingScreen extends StatefulWidget {
  final String chamadoId;
  final Map<String, dynamic> initialData;

  const DamageMarkingScreen({
    super.key,
    required this.chamadoId,
    required this.initialData,
  });

  @override
  State<DamageMarkingScreen> createState() => _DamageMarkingScreenState();
}

class _DamageMarkingScreenState extends State<DamageMarkingScreen> {
  // O estado desta tela só se preocupa com os pontos de dano
  Map<String, DamageType> damagePoints = {};

  // O mapa de coordenadas relativas ATUALIZADO COM OS SEUS VALORES
  final Map<String, Offset> _damageHotspots = {
    // Vista de Cima
    'capo_superior': const Offset(0.1897, 0.8099),
    'para-brisa_superior': const Offset(0.0278, 0.6777),
    'teto_superior': const Offset(0.1974, 0.4541),
    'vidro_traseiro_superior': const Offset(0.0239, 0.2499),
    'porta-malas_superior': const Offset(0.1850, 0.1663),

    // Vista Frontal
    'para-choque_frontal_esq': const Offset(0.5085, 0.9573),
    'farol_frontal_esq': const Offset(0.5108, 0.7611),
    'para-choque_frontal_dir': const Offset(0.2527, 0.9495),
    'farol_frontal_dir': const Offset(0.2496, 0.7552),
    'farol_auxiliar_dir': const Offset(0.3320, 0.9612),
    'farol_auxiliar_esq': const Offset(0.4199, 0.9534),

    // Vista Traseira
    'para-choque_traseiro_esq': const Offset(0.2596, 0.4755),
    'lanterna_traseira_esq': const Offset(0.2619, 0.2987),
    'para-choque_traseiro_dir': const Offset(0.5069, 0.4949),
    'lanterna_traseira_dir': const Offset(0.5062, 0.2987),
    'tampa_porta_malas': const Offset(0.4884, 0.1413),

    // Vista Lateral Esquerda
    'para-lama_dianteiro_esq': const Offset(0.6094, 0.6290),
    'porta_dianteira_esq': const Offset(0.7173, 0.9165),
    'porta_traseira_esq': const Offset(0.7928, 0.9223),
    'para-lama_traseiro_esq': const Offset(0.9746, 0.6251),
    'vidro_dianteiro_esq': const Offset(0.7658, 0.5163),
    'vidro_traseiro_esq': const Offset(0.8498, 0.5163),
    'roda_dianteira_esq': const Offset(0.5940, 0.9437),
    'roda_traseira_esq': const Offset(0.9461, 0.9379),
    'retrovisor_esq': const Offset(0.5193, 0.6018),

    // Vista Lateral Direita
    'para-lama_dianteiro_dir': const Offset(0.9453, 0.1918),
    'porta_dianteira_dir': const Offset(0.7958, 0.4638),
    'porta_traseira_dir': const Offset(0.7227, 0.4599),
    'para-lama_traseiro_dir': const Offset(0.6009, 0.1471),
    'vidro_dianteiro_dir': const Offset(0.8159, 0.0869),
    'vidro_traseiro_dir': const Offset(0.7411, 0.0869),
    'roda_dianteira_dir': const Offset(0.9622, 0.5124),
    'roda_traseira_dir': const Offset(0.6094, 0.5221),
    'retrovisor_dir': const Offset(0.2458, 0.6037),
  };

  @override
  void initState() {
    super.initState();
    final damageData = widget.initialData['vehicle_damage_points'];
    if (damageData is Map) {
      damagePoints = damageData.map((key, value) => MapEntry(
          key,
          DamageType.values.firstWhere((e) => e.name == value,
              orElse: () => DamageType.none)));
    }
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  void _onDamagePointTapped(String pointKey) {
    showDialog<DamageType>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Avaria em: ${pointKey.replaceAll('_', ' ')}'),
        children: [
          SimpleDialogOption(
              child: const Text('Sem avaria'),
              onPressed: () => Navigator.of(context).pop(DamageType.none)),
          SimpleDialogOption(
              child: const Text('Batido (X)'),
              onPressed: () => Navigator.of(context).pop(DamageType.batido)),
          SimpleDialogOption(
              child: const Text('Riscado (-)'),
              onPressed: () => Navigator.of(context).pop(DamageType.riscado)),
        ],
      ),
    ).then((selectedType) {
      if (selectedType != null) {
        setState(() {
          damagePoints[pointKey] = selectedType;
        });
      }
    });
  }

  Widget _buildDamageIcon(DamageType type) {
    switch (type) {
      case DamageType.batido:
        return const Icon(Icons.close,
            color: Colors.red, size: 30, weight: 1200);
      case DamageType.riscado:
        return const Icon(Icons.remove,
            color: Colors.red, size: 30, weight: 1200);
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Passo 1: Marcar Avarias do Veículo'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 1,
      ),
      body: SafeArea(
        child: InteractiveViewer(
          maxScale: 3.0,
          // O LayoutBuilder agora é o filho direto do InteractiveViewer
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Proporção original da imagem
              const imageAspectRatio = 1500 / 595;

              // Dimensões do espaço disponível dado pelo LayoutBuilder
              final availableWidth = constraints.maxWidth;
              final availableHeight = constraints.maxHeight;

              // --- LÓGICA DE CÁLCULO ROBUSTA ---
              // Calcula as dimensões que a imagem realmente terá para caber no espaço
              // disponível, mantendo sua proporção (lógica similar a BoxFit.contain)
              double finalWidth;
              double finalHeight;

              if (availableWidth / imageAspectRatio < availableHeight) {
                // A largura é o fator limitante
                finalWidth = availableWidth;
                finalHeight = finalWidth / imageAspectRatio;
              } else {
                // A altura é o fator limitante
                finalHeight = availableHeight;
                finalWidth = finalHeight * imageAspectRatio;
              }
              // --- FIM DA LÓGICA DE CÁLCULO ---

              // Usamos um Center para centralizar a imagem caso haja espaço sobrando
              return Center(
                child: SizedBox(
                  width: finalWidth,
                  height: finalHeight,
                  child: Stack(
                    children: [
                      Image.asset(
                        'assets/car_diagram.png',
                        fit: BoxFit
                            .fill, // Fill agora é seguro, pois o SizedBox já tem a proporção correta
                      ),
                      ..._damageHotspots.entries.map((entry) {
                        final relativeOffset = entry.value;
                        // O cálculo agora usa as dimensões FINAIS e corretas da imagem
                        final absolutePosition = Offset(
                          relativeOffset.dx * finalWidth,
                          relativeOffset.dy * finalHeight,
                        );

                        return Positioned(
                          left: absolutePosition.dx - 20,
                          top: absolutePosition.dy - 20,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _onDamagePointTapped(entry.key),
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child: _buildDamageIcon(
                                  damagePoints[entry.key] ?? DamageType.none),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => AccessoriesAndSignatureScreen(
              chamadoId: widget.chamadoId,
              initialData: widget.initialData,
              damagePoints: damagePoints,
            ),
          ));
        },
        label: const Text('Próximo'),
        icon: const Icon(Icons.arrow_forward),
      ),
    );
  }
}
