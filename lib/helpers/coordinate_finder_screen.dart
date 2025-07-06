// lib/helpers/coordinate_finder_screen.dart (VERSÃO FINAL AJUSTADA)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CoordinateFinderScreen extends StatefulWidget {
  const CoordinateFinderScreen({super.key});

  @override
  State<CoordinateFinderScreen> createState() => _CoordinateFinderScreenState();
}

class _CoordinateFinderScreenState extends State<CoordinateFinderScreen> {
  String _message =
      'Toque em um ponto na imagem para obter as coordenadas relativas.';
  Offset? _lastAbsoluteTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Localizador de Coordenadas Relativas'),
        backgroundColor: Colors.blueGrey,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SelectableText(
                  // Permite copiar o texto da tela
                  _message,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              InteractiveViewer(
                maxScale: 4.0, // Aumentei o zoom máximo
                child: AspectRatio(
                  // IMPORTANTE: Mantenha a proporção correta da sua imagem
                  aspectRatio: 4267 / 1692,
                  // O LayoutBuilder nos dá as dimensões do widget filho
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final containerWidth = constraints.maxWidth;
                      final containerHeight = constraints.maxHeight;

                      return GestureDetector(
                        onTapDown: (details) {
                          final absolutePosition = details.localPosition;

                          // --- LÓGICA PRINCIPAL ---
                          // Calcula as coordenadas relativas (percentuais)
                          final relativeX =
                              absolutePosition.dx / containerWidth;
                          final relativeY =
                              absolutePosition.dy / containerHeight;

                          final textToCopy =
                              'const Offset(${relativeX.toStringAsFixed(4)}, ${relativeY.toStringAsFixed(4)}),';

                          // Copia para a área de transferência
                          Clipboard.setData(ClipboardData(text: textToCopy));

                          setState(() {
                            _lastAbsoluteTap = absolutePosition;
                            _message = 'COPIADO: $textToCopy';
                          });

                          // Mensagem de feedback
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Coordenadas relativas copiadas!'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Image.asset(
                                'assets/car_diagram.png',
                                fit: BoxFit.fill,
                              ),
                            ),
                            // Ponto vermelho para feedback visual do toque
                            if (_lastAbsoluteTap != null)
                              Positioned(
                                left: _lastAbsoluteTap!.dx - 5,
                                top: _lastAbsoluteTap!.dy - 5,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 1.5)),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
