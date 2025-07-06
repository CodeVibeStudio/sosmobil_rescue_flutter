import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:signature/signature.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Enums para os tipos de avaria e estado dos acessórios
enum DamageType { none, batido, riscado }

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
  // Mapa com as coordenadas RELATIVAS (percentuais) - VOCÊ PRECISA ATUALIZAR ESTES VALORES
  final Map<String, Offset> _damageHotspots = {
    // Exemplo de como devem ser os novos valores (entre 0.0 e 1.0)
    // Use a tela de depuração para coletar os valores corretos para a sua imagem.
// Vista de Cima
    'capo_superior': const Offset(0.1892, 0.8074),
    'para-brisa_superior': const Offset(0.0270, 0.6770),
    'teto_superior': const Offset(0.1977, 0.4530),
    'vidro_traseiro_superior': const Offset(0.0239, 0.2446),
    'porta-malas_superior': const Offset(0.1846, 0.1687),

    // Vista Frontal
    'retrovisor_dir': const Offset(0.2463, 0.6030),
    'farol_frontal_dir': const Offset(0.2494, 0.7549),
    'para-choque_frontal_dir': const Offset(0.2525, 0.9457),
    'farol_auxiliar_dir': const Offset(0.3313, 0.9632),
    'farol_auxiliar_esq': const Offset(0.4201, 0.9574),
    'para-choque_frontal_esq': const Offset(0.5089, 0.9574),
    'farol_frontal_esq': const Offset(0.5120, 0.7627),
    'retrovisor_esq': const Offset(0.5189, 0.5991),

    // Vista Traseira
    'lanterna_traseira_esq': const Offset(0.2602, 0.2972),
    'para-choque_traseiro_esq': const Offset(0.2595, 0.4764),
    'para-choque_traseiro_dir': const Offset(0.5066, 0.4920),
    'lanterna_traseira_dir': const Offset(0.5050, 0.2972),
    'tampa_porta_malas': const Offset(0.4880, 0.1434),

    // Vista Lateral Esquerda
    'roda_dianteira_esq': const Offset(0.5938, 0.9418),
    'porta_dianteira_esq': const Offset(0.7174, 0.9204),
    'porta_traseira_esq': const Offset(0.7923, 0.9243),
    'roda_traseira_esq': const Offset(0.9459, 0.9399),
    'para-lama_traseiro_esq': const Offset(0.9745, 0.6283),
    'para-lama_dianteiro_esq': const Offset(0.6085, 0.6302),
    'vidro_dianteiro_esq': const Offset(0.7645, 0.5192),
    'vidro_traseiro_esq': const Offset(0.8494, 0.5212),

    // Vista Lateral Direita
    'roda_traseira_dir': const Offset(0.6093, 0.5153),
    'porta_traseira_dir': const Offset(0.7220, 0.4550),
    'porta_dianteira_dir': const Offset(0.7961, 0.4589),
    'roda_dianteira_dir': const Offset(0.9606, 0.5075),
    'para-lama_traseiro_dir': const Offset(0.6023, 0.1434),
    'vidro_traseiro_dir': const Offset(0.7413, 0.0850),
    'vidro_dianteiro_dir': const Offset(0.8147, 0.0869),
    'para-lama_dianteiro_dir': const Offset(0.9452, 0.1921),
  };

  // Variáveis de estado
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
    _requesterNameController.dispose();
    _recipientNameController.dispose();
    _requesterSignatureController.dispose();
    _recipientSignatureController.dispose();
    super.dispose();
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
                child: LayoutBuilder(builder: (context, constraints) {
                  final containerWidth = constraints.maxWidth;
                  // Calcula a altura mantendo a proporção da imagem original (1500x595)
                  final containerHeight = containerWidth * (595 / 1500);

                  return SizedBox(
                    width: containerWidth,
                    height: containerHeight,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset('assets/car_diagram.png', fit: BoxFit.fill),
                        ..._damageHotspots.entries.map((entry) {
                          final relativeOffset = entry.value;
                          // Converte a coordenada relativa para uma posição absoluta (em pixels)
                          final absolutePosition = Offset(
                            relativeOffset.dx * containerWidth,
                            relativeOffset.dy * containerHeight,
                          );

                          return Positioned(
                            left: absolutePosition.dx -
                                20, // Centraliza a área de toque (40x40)
                            top: absolutePosition.dy - 20,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _onDamagePointTapped(entry.key),
                              child: Container(
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
                  );
                }),
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
