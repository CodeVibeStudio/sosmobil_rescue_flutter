// lib/screens/signature_capture_screen.dart (VERSÃO TELA CHEIA)

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:signature/signature.dart';

class SignatureCaptureScreen extends StatefulWidget {
  const SignatureCaptureScreen({super.key});

  @override
  State<SignatureCaptureScreen> createState() => _SignatureCaptureScreenState();
}

class _SignatureCaptureScreenState extends State<SignatureCaptureScreen> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  @override
  void initState() {
    super.initState();
    // Força a orientação para paisagem para dar mais espaço para a assinatura
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    // Oculta as barras de status do sistema para uma imersão completa
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  @override
  void dispose() {
    // Restaura as orientações e a UI do sistema ao sair
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveSignature() async {
    if (_controller.isNotEmpty) {
      final Uint8List? data = await _controller.toPngBytes();
      if (data != null && mounted) {
        Navigator.of(context).pop(data);
      }
    }
  }

  void _clearSignature() {
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // O corpo da tela agora é apenas o campo de assinatura
      body: Signature(
        controller: _controller,
        backgroundColor: Colors.white,
      ),
      // Usamos FloatingActionButtons para os botões de ação
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Botão para Limpar
            FloatingActionButton.extended(
              heroTag: 'clear_button', // Tag para evitar conflito
              onPressed: _clearSignature,
              label: const Text('Limpar'),
              icon: const Icon(Icons.clear),
              backgroundColor: Colors.grey.shade700,
            ),
            // Botão para Salvar
            FloatingActionButton.extended(
              heroTag: 'save_button', // Tag para evitar conflito
              onPressed: _saveSignature,
              label: const Text('Salvar'),
              icon: const Icon(Icons.check),
              backgroundColor: Colors.green,
            ),
          ],
        ),
      ),
    );
  }
}
