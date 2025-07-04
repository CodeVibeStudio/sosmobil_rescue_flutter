// lib/screens/vehicle_checklist_screen.dart
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Enum para os tipos de avaria
enum DamageType { none, batido, riscado }

// Enum para o estado dos acessórios
enum AccessoryState { S, N, I }

class VehicleChecklistScreen extends StatefulWidget {
  final String chamadoId;
  final Map<String, dynamic> initialData;

  const VehicleChecklistScreen({
    super.key,
    required this.chamadoId,
    required this.initialData,
  });

  @override
  State<VehicleChecklistScreen> createState() => _VehicleChecklistScreenState();
}

class _VehicleChecklistScreenState extends State<VehicleChecklistScreen> {
  // Mapa de hotspots final com todas as coordenadas.
  final Map<String, Offset> _damageHotspots = {
    // Vista de Cima
    'capo_superior': const Offset(192.80, 322.60),
    'para-brisa_superior': const Offset(28.00, 267.40),
    'teto_superior': const Offset(201.60, 177.80),
    'vidro_traseiro_superior': const Offset(25.60, 93.80),
    'porta-malas_superior': const Offset(184.8, 65),

    // Vista Frontal
    'para-choque_frontal_esq': const Offset(510.4, 380.2),
    'farol_frontal_esq': const Offset(513.6, 302.6),
    'para-choque_frontal_dir': const Offset(253.6, 374.6),
    'farol_frontal_dir': const Offset(250.4, 299.4),
    'farol_auxiliar_dir': const Offset(332.8, 383.4),
    'farol_auxiliar_esq': const Offset(422.4, 379.4),

    // Vista Traseira
    'para-choque_traseiro_esq': const Offset(260.8, 190.6),
    'lanterna_traseira_esq': const Offset(261.6, 117.8),
    'para-choque_traseiro_dir': const Offset(508.8, 197.8),
    'lanterna_traseira_dir': const Offset(508, 119.4),
    'tampa_porta_malas': const Offset(490.4, 56.2),

    // Vista Lateral Esquerda
    'para-lama_dianteiro_esq': const Offset(611.2, 249),
    'porta_dianteira_esq': const Offset(720.8, 365.8),
    'porta_traseira_esq': const Offset(795.2, 367.4),
    'para-lama_traseiro_esq': const Offset(978.4, 249),
    'vidro_dianteiro_esq': const Offset(768, 205.8),
    'vidro_traseiro_esq': const Offset(852.8, 206.6),
    'roda_dianteira_esq': const Offset(596.8, 375.4),
    'roda_traseira_esq': const Offset(948.8, 373),
    'retrovisor_esq': const Offset(521.6, 239.4),

    // Vista Lateral Direita
    'para-lama_dianteiro_dir': const Offset(948.8, 75.4),
    'porta_dianteira_dir': const Offset(799.2, 184.2),
    'porta_traseira_dir': const Offset(612, 207.4),
    'para-lama_traseiro_dir': const Offset(603.2, 58.6),
    'vidro_dianteiro_dir': const Offset(818.4, 33),
    'vidro_traseiro_dir': const Offset(744, 34.6),
    'roda_dianteira_dir': const Offset(965.6, 203.4),
    'roda_traseira_dir': const Offset(612, 207.4),
    'retrovisor_dir': const Offset(247.2, 241),
  };

  Map<String, DamageType> damagePoints = {};
  Map<String, AccessoryState> accessories = {};
  String? fuelLevel;
  String? tiresState;
  final _requesterNameController = TextEditingController();
  final _recipientNameController = TextEditingController();
  final SignatureController _requesterSignatureController =
      SignatureController(penStrokeWidth: 2, penColor: Colors.white);
  final SignatureController _recipientSignatureController =
      SignatureController(penStrokeWidth: 2, penColor: Colors.white);
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
    'Chave de Roda'
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _requesterNameController.dispose();
    _recipientNameController.dispose();
    _requesterSignatureController.dispose();
    _recipientSignatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checklist do Veículo'),
        actions: [
          if (_isLoading)
            const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(color: Colors.white))
          else
            IconButton(
                icon: const Icon(Icons.save),
                onPressed: _saveChecklist,
                tooltip: 'Salvar Checklist')
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Avarias do Veículo (Toque nos pontos)'),
            const SizedBox(height: 16),
            Center(
              child: InteractiveViewer(
                maxScale: 2.5,
                child: AspectRatio(
                  aspectRatio: 1500 / 595,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Camada 0: Imagem de fundo
                      Image.asset('assets/car_diagram.png', fit: BoxFit.fill),

                      // Camada 1: Hotspots que já foram configurados
                      ..._damageHotspots.entries.map((entry) {
                        final position = entry.value;
                        return Positioned(
                          left: position.dx - 15,
                          top: position.dy - 15,
                          child: GestureDetector(
                            onTap: () => _onDamagePointTapped(entry.key),
                            child: Container(
                              width: 30,
                              height: 30,
                              color: Colors.transparent,
                              child: _buildDamageIcon(
                                  damagePoints[entry.key] ?? DamageType.none),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Acessórios e Equipamentos'),
            ..._accessoryList.map((item) => _buildAccessoryRow(item)),
            const SizedBox(height: 24),
            _buildSectionTitle('Assinaturas e Responsabilidades'),
            _buildSignatureArea(
                title: 'Solicitante',
                nameController: _requesterNameController,
                signatureController: _requesterSignatureController),
            const SizedBox(height: 16),
            _buildSignatureArea(
                title: 'Destinatário',
                nameController: _recipientNameController,
                signatureController: _recipientSignatureController),
            const SizedBox(height: 16),
            _buildDisclaimer(),
          ],
        ),
      ),
    );
  }

  void _loadInitialData() {
    final damageData = widget.initialData['vehicle_damage_points'];
    if (damageData is Map) {
      damagePoints = damageData.map((key, value) => MapEntry(
          key,
          DamageType.values.firstWhere((e) => e.name == value,
              orElse: () => DamageType.none)));
    }
    final accessoriesData = widget.initialData['accessories_checklist'];
    if (accessoriesData is Map) {
      accessories = accessoriesData.map((key, value) => MapEntry(
          key,
          AccessoryState.values.firstWhere((e) => e.name == value,
              orElse: () => AccessoryState.N)));
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
    }
  }

  Future<void> _saveChecklist() async {
    setState(() => _isLoading = true);
    final damagePointsToSave =
        damagePoints.map((key, value) => MapEntry(key, value.name));
    final accessoriesToSave =
        accessories.map((key, value) => MapEntry(key, value.name));
    final requesterSignatureBytes =
        await _requesterSignatureController.toPngBytes();
    final recipientSignatureBytes =
        await _recipientSignatureController.toPngBytes();
    final signaturesToSave = {
      'requester_name': _requesterNameController.text.trim(),
      'requester_signature_base64': requesterSignatureBytes != null
          ? base64Encode(requesterSignatureBytes)
          : null,
      'recipient_name': _recipientNameController.text.trim(),
      'recipient_signature_base64': recipientSignatureBytes != null
          ? base64Encode(recipientSignatureBytes)
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Checklist salvo com sucesso!'),
            backgroundColor: Colors.green));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro ao salvar checklist: $e'),
            backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                  tooltip: 'Sim, existente'),
              ButtonSegment(
                  value: AccessoryState.N,
                  label: Text('N'),
                  tooltip: 'Não, não existente'),
              ButtonSegment(
                  value: AccessoryState.I,
                  label: Text('I'),
                  tooltip: 'Incompleto ou avariado'),
            ],
            selected: {accessories[itemName] ?? AccessoryState.N},
            onSelectionChanged: (Set<AccessoryState> newSelection) {
              setState(() {
                accessories[itemName] = newSelection.first;
              });
            },
            style: SegmentedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12)),
          )
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

  Widget _buildSignatureArea(
      {required String title,
      required TextEditingController nameController,
      required SignatureController signatureController}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      TextFormField(
          controller: nameController,
          decoration: InputDecoration(labelText: 'Nome Completo de $title')),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8)),
        height: 150,
        child: Signature(
            controller: signatureController,
            backgroundColor: Colors.grey.shade800),
      ),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        TextButton(
            onPressed: () => signatureController.clear(),
            child: const Text('Limpar Assinatura')),
      ])
    ]);
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
          color: const Color(0x1AF44336),
          border: Border.all(color: Colors.red.shade700),
          borderRadius: BorderRadius.circular(8)),
      child:
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
            "Declaro estar de acordo com as informações contidas nesse formulário.",
            style: TextStyle(fontStyle: FontStyle.italic)),
        SizedBox(height: 8),
        Divider(color: Colors.red),
        SizedBox(height: 8),
        Text(
            "OBSERVAÇÃO: A AUTO SOCORRO LARANJAL, NÃO SE RESPONSABILIZA POR OBJETOS DEIXADOS DENTRO DO VEÍCULO.",
            style: TextStyle(fontWeight: FontWeight.bold)),
      ]),
    );
  }
}
