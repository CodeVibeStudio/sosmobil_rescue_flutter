// lib/helpers/coordinate_finder_screen.dart (VERSÃO CORRIGIDA)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CoordinateFinderScreen extends StatefulWidget {
  const CoordinateFinderScreen({super.key});

  @override
  State<CoordinateFinderScreen> createState() => _CoordinateFinderScreenState();
}

class _CoordinateFinderScreenState extends State<CoordinateFinderScreen> {
  Offset? _lastTapPosition;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Localizador de Coordenadas'),
        backgroundColor: Colors.blueGrey,
      ),
      body: Center(
        child: SingleChildScrollView(
          // Adicionado para evitar overflow em telas pequenas
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Toque em um ponto na imagem abaixo.'),
              const SizedBox(height: 20),
              InteractiveViewer(
                // Adicionado para dar zoom e facilitar o clique
                maxScale: 3.0,
                child: AspectRatio(
                  // Use a mesma proporção da sua imagem aqui
                  aspectRatio: 4267 / 1692,
                  child: GestureDetector(
                    onTapDown: (details) {
                      setState(() {
                        _lastTapPosition = details.localPosition;
                      });
                      final textToCopy =
                          'const Offset(${_lastTapPosition!.dx.toStringAsFixed(2)}, ${_lastTapPosition!.dy.toStringAsFixed(2)}),';
                      Clipboard.setData(ClipboardData(text: textToCopy));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Coordenadas copiadas: $textToCopy'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Stack(
                      children: [
                        // A MESMA ESTRUTURA DA TELA DE CHECKLIST
                        Positioned.fill(
                          child: Image.asset(
                            'assets/car_diagram.png',
                            fit: BoxFit.fill,
                          ),
                        ),
                        if (_lastTapPosition != null)
                          Positioned(
                            left: _lastTapPosition!.dx - 5,
                            top: _lastTapPosition!.dy - 5,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_lastTapPosition != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Último Ponto: (X: ${_lastTapPosition!.dx.toStringAsFixed(2)}, Y: ${_lastTapPosition!.dy.toStringAsFixed(2)})',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
