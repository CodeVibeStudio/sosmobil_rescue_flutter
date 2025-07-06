// lib/screens/accessories_signature_screen.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:signature/signature.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sosmobil_rescue_flutter/screens/damage_marking_screen.dart';
import 'package:sosmobil_rescue_flutter/screens/signature_capture_screen.dart';

// Enum para o estado dos acessórios
enum AccessoryState { S, N, I }

class AccessoriesAndSignatureScreen extends StatefulWidget {
  final String chamadoId;
  final Map<String, dynamic> initialData;
  final Map<String, DamageType> damagePoints;

  const AccessoriesAndSignatureScreen({
    super.key,
    required this.chamadoId,
    required this.initialData,
    required this.damagePoints,
  });

  @override
  State<AccessoriesAndSignatureScreen> createState() =>
      _AccessoriesAndSignatureScreenState();
}

class _AccessoriesAndSignatureScreenState
    extends State<AccessoriesAndSignatureScreen> {
  // Variáveis de estado para esta tela
  Map<String, AccessoryState> accessories = {};
  String? fuelLevel;
  String? tiresState;
  final _requesterNameController = TextEditingController();
  final _recipientNameController = TextEditingController();

  Uint8List? _requesterSignatureBytes;
  Uint8List? _recipientSignatureBytes;

  bool _isLoading = false;

  final List<String> _accessoryList = [
    'Retrovisor Elétrico',
    'Faróis Auxiliares',
    'Calotas',
    'Rodas de Liga Leve',
    'Chaves',
    'Rádio / CD',
    'Alto-Falantes',
    'Bancos Dianteiros',
    'Bancos Traseiros',
    'Documentos',
    'Tapetes',
    'Estepe',
    'Macaco',
    'Triângulo',
    'Chave de Roda',
  ];

  @override
  void initState() {
    super.initState();
    // Força a orientação para retrato ao entrar na tela
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _loadInitialData();
  }

  @override
  void dispose() {
    _requesterNameController.dispose();
    _recipientNameController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    final accessoriesData = widget.initialData['accessories_checklist'];
    if (accessoriesData is Map) {
      accessories = accessoriesData.map(
        (key, value) => MapEntry(
          key,
          AccessoryState.values.firstWhere(
            (e) => e.name == value,
            orElse: () => AccessoryState.N,
          ),
        ),
      );
    } else {
      for (var item in _accessoryList) {
        accessories[item] = AccessoryState.N;
      }
    }
    fuelLevel = widget.initialData['fuel_level'];
    tiresState = widget.initialData['tires_state'];
    final signatureData = widget.initialData['signatures'];
    if (signatureData is Map) {
      _requesterNameController.text = signatureData['requester_name'] ?? '';
      _recipientNameController.text = signatureData['recipient_name'] ?? '';
      if (signatureData['requester_signature_base64'] != null) {
        _requesterSignatureBytes = base64Decode(
          signatureData['requester_signature_base64'],
        );
      }
      if (signatureData['recipient_signature_base64'] != null) {
        _recipientSignatureBytes = base64Decode(
          signatureData['recipient_signature_base64'],
        );
      }
    }
  }

  Future<void> _saveChecklist() async {
    setState(() => _isLoading = true);

    final damagePointsToSave = widget.damagePoints.map(
      (key, value) => MapEntry(key, value.name),
    );
    final accessoriesToSave = accessories.map(
      (key, value) => MapEntry(key, value.name),
    );

    final signaturesToSave = {
      'requester_name': _requesterNameController.text.trim(),
      'requester_signature_base64': _requesterSignatureBytes != null
          ? base64Encode(_requesterSignatureBytes!)
          : null,
      'recipient_name': _recipientNameController.text.trim(),
      'recipient_signature_base64': _recipientSignatureBytes != null
          ? base64Encode(_recipientSignatureBytes!)
          : null,
    };

    try {
      await Supabase.instance.client.from('chamados').update({
        'vehicle_damage_points': damagePointsToSave,
        'accessories_checklist': accessoriesToSave,
        'signatures': signaturesToSave,
        'fuel_level': fuelLevel,
        'tires_state': tiresState,
      }).eq('id', widget.chamadoId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Checklist salvo com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        int popCount = 0;
        Navigator.of(context).popUntil((_) => popCount++ >= 2);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar checklist: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Passo 2: Acessórios e Assinaturas'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: Colors.white),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveChecklist,
              tooltip: 'Salvar Checklist',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Acessórios e Equipamentos'),
            ..._accessoryList.map((item) => _buildAccessoryRow(item)),
            const SizedBox(height: 24),
            _buildSectionTitle('Nomes e Assinaturas'),
            const SizedBox(height: 16),
            TextField(
              controller: _requesterNameController,
              decoration: InputDecoration(
                labelText: 'Nome Completo do Solicitante',
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildSignatureCollector(
              title: 'Assinatura do Solicitante',
              signatureBytes: _requesterSignatureBytes,
              onTap: () async {
                final result = await Navigator.of(context).push<Uint8List>(
                  MaterialPageRoute(
                    builder: (context) => const SignatureCaptureScreen(),
                  ),
                );
                if (result != null) {
                  setState(() {
                    _requesterSignatureBytes = result;
                  });
                }
              },
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _recipientNameController,
              decoration: InputDecoration(
                labelText: 'Nome Completo do Destinatário',
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildSignatureCollector(
              title: 'Assinatura do Destinatário',
              signatureBytes: _recipientSignatureBytes,
              onTap: () async {
                final result = await Navigator.of(context).push<Uint8List>(
                  MaterialPageRoute(
                    builder: (context) => const SignatureCaptureScreen(),
                  ),
                );
                if (result != null) {
                  setState(() {
                    _recipientSignatureBytes = result;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            _buildDisclaimer(),
          ],
        ),
      ),
    );
  }

  Widget _buildSignatureCollector({
    required String title,
    required Uint8List? signatureBytes,
    required VoidCallback onTap,
  }) {
    final bool hasSignature = signatureBytes != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (hasSignature)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.green),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                const Text('Assinatura Coletada'),
                const Spacer(),
                Container(
                  width: 100,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Image.memory(signatureBytes!),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onTap,
            icon: Icon(hasSignature ? Icons.edit : Icons.draw),
            label: Text(
              hasSignature ? 'Alterar Assinatura' : 'Coletar Assinatura',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: hasSignature
                  ? Colors.grey.shade700
                  : Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccessoryRow(String itemName) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(itemName)),
          SegmentedButton<AccessoryState>(
            segments: const [
              ButtonSegment(
                value: AccessoryState.S,
                label: Text('S'),
                tooltip: 'Sim, existente',
              ),
              ButtonSegment(
                value: AccessoryState.N,
                label: Text('N'),
                tooltip: 'Não, não existente',
              ),
              ButtonSegment(
                value: AccessoryState.I,
                label: Text('I'),
                tooltip: 'Incompleto ou avariado',
              ),
            ],
            selected: {accessories[itemName] ?? AccessoryState.N},
            onSelectionChanged: (Set<AccessoryState> newSelection) {
              setState(() {
                accessories[itemName] = newSelection.first;
              });
            },
            style: SegmentedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0x1AF44336),
        border: Border.all(color: Colors.red.shade700),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Declaro estar de acordo com as informações contidas nesse formulário.",
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
          SizedBox(height: 8),
          Divider(color: Colors.red),
          SizedBox(height: 8),
          Text(
            "OBSERVAÇÃO: A AUTO SOCORRO LARANJAL, NÃO SE RESPONSABILIZA POR OBJETOS DEIXADOS DENTRO DO VEÍCULO.",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
