// lib/screens/details_screen.dart
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../helpers/pdf_generator.dart';
import 'vehicle_checklist_screen.dart';

class DetailsScreen extends StatefulWidget {
  final String chamadoId;
  const DetailsScreen({super.key, required this.chamadoId});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  Map<String, dynamic>? _chamadoData;
  bool _isUploading = false;
  bool _isGeneratingPdf = false;
  bool _isSaving = false;
  bool _isEndingService = false;
  bool _temAvarias = false;

  final _placaController = TextEditingController();
  final _obsSocorristaController = TextEditingController();
  final _avariasController = TextEditingController();

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshIndicatorKey.currentState?.show();
    });
  }

  @override
  void dispose() {
    _placaController.dispose();
    _obsSocorristaController.dispose();
    _avariasController.dispose();
    super.dispose();
  }

  // Nenhuma alteração nas funções de backend (_fetchChamado, _saveChanges, etc.)
  Future<void> _fetchChamado() async {
    try {
      final response = await Supabase.instance.client
          .from('chamados')
          .select()
          .eq('id', widget.chamadoId)
          .single();
      if (mounted) {
        setState(() {
          _chamadoData = response;
          _placaController.text = _chamadoData?['placa_veiculo'] ?? '';
          _obsSocorristaController.text =
              _chamadoData?['observacoes_socorrista'] ?? '';
          _temAvarias = _chamadoData?['avarias_registradas'] ?? false;
          _avariasController.text =
              _chamadoData?['especificacao_avarias'] ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar dados: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveChanges() async {
    if (_chamadoData == null || !mounted) return;
    setState(() => _isSaving = true);

    try {
      await Supabase.instance.client.from('chamados').update({
        'placa_veiculo': _placaController.text.trim(),
        'observacoes_socorrista': _obsSocorristaController.text.trim(),
        'avarias_registradas': _temAvarias,
        'especificacao_avarias':
            _temAvarias ? _avariasController.text.trim() : null,
      }).eq('id', widget.chamadoId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alterações salvas com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    if (_chamadoData == null || !mounted) return;
    setState(() => _isUploading = true);

    final picker = ImagePicker();
    final imageFile = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      imageQuality: 85,
    );

    if (imageFile == null) {
      if (mounted) setState(() => _isUploading = false);
      return;
    }

    final assistanceNumber =
        _chamadoData?['numero_assistencia']?.toString().trim();
    final folderNameSource =
        (assistanceNumber != null && assistanceNumber.isNotEmpty)
            ? assistanceNumber
            : widget.chamadoId;
    final folderName = folderNameSource.replaceAll(
      RegExp(r'[^a-zA-Z0-9]'),
      '-',
    );

    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final filePath = '$folderName/$fileName';

    try {
      final fileBytes = await imageFile.readAsBytes();
      await Supabase.instance.client.storage
          .from('fotos-chamados')
          .uploadBinary(filePath, fileBytes);
      final imageUrl = Supabase.instance.client.storage
          .from('fotos-chamados')
          .getPublicUrl(filePath);

      final List<dynamic> currentPhotos = List.from(
        _chamadoData?['fotos'] ?? [],
      );
      currentPhotos.add({
        'url': imageUrl,
        'uploaded_at': DateTime.now().toIso8601String(),
      });

      await Supabase.instance.client
          .from('chamados')
          .update({'fotos': currentPhotos}).eq('id', widget.chamadoId);

      _refreshIndicatorKey.currentState?.show();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao enviar foto: $error')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _createAndShowPdf() async {
    if (_chamadoData == null || !mounted) return;
    setState(() => _isGeneratingPdf = true);

    _chamadoData?['placa_veiculo'] = _placaController.text.trim();
    _chamadoData?['observacoes_socorrista'] =
        _obsSocorristaController.text.trim();
    _chamadoData?['avarias_registradas'] = _temAvarias;
    _chamadoData?['especificacao_avarias'] =
        _temAvarias ? _avariasController.text.trim() : null;

    try {
      final pdfBytes = await PdfGenerator.generatePdf(_chamadoData!);
      await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao gerar PDF: $e')));
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  Future<void> _endService() async {
    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Encerramento'),
        content: const Text(
          'Você tem certeza que deseja encerrar este atendimento? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Encerrar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isEndingService = true);

    try {
      await _saveChanges();
      await Supabase.instance.client
          .from('chamados')
          .update({'status': 'Concluído'}).eq('id', widget.chamadoId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Atendimento encerrado com sucesso!'),
            backgroundColor: Colors.blue,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao encerrar atendimento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isEndingService = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // ... (código do AppBar sem alterações)
        title: Text(_chamadoData?['tipo_servico'] ?? 'Carregando...'),
        actions: [
          if (_chamadoData != null)
            _isGeneratingPdf
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.picture_as_pdf),
                    onPressed: _createAndShowPdf,
                    tooltip: 'Gerar Relatório PDF',
                  ),
        ],
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _fetchChamado,
        child: _chamadoData == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ... (Todas as seções de detalhes do chamado sem alterações)
                    _buildSectionTitle('Resumo do Chamado'),
                    _buildDetailRow('Status:', _chamadoData!['status']),
                    _buildDetailRow(
                      'Nº Assistência:',
                      _chamadoData!['numero_assistencia'],
                    ),
                    _buildDetailRow(
                      'Motivo:',
                      _chamadoData!['motivo_acionamento'],
                    ),
                    _buildSectionTitle('Cliente e Veículo'),
                    _buildDetailRow('Cliente:', _chamadoData!['nome_segurado']),
                    _buildDetailRow(
                      'Telefone:',
                      _chamadoData!['telefone_segurado'],
                    ),
                    _buildDetailRow(
                      'Veículo:',
                      '${_chamadoData!['marca_modelo_veiculo'] ?? ''} (${_chamadoData!['cor_veiculo'] ?? ''} - ${_chamadoData!['ano_veiculo'] ?? ''})',
                    ),
                    _buildSectionTitle('Localização'),
                    _buildDetailRow(
                      'Origem:',
                      _chamadoData!['endereco_origem'],
                    ),
                    _buildDetailRow(
                      'Destino:',
                      _chamadoData!['endereco_destino'],
                    ),
                    _buildSectionTitle('Condições do Local'),
                    _buildDetailChips(_chamadoData!),
                    _buildSectionTitle('Observações da Base'),
                    Text(
                      _chamadoData!['observacoes_importantes_base'] ??
                          'Nenhuma observação.',
                    ),
                    _buildSectionTitle('Dados do Socorrista (Editável)'),
                    TextFormField(
                      controller: _placaController,
                      decoration: const InputDecoration(
                        labelText: 'Placa do Veículo',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _obsSocorristaController,
                      decoration: const InputDecoration(
                        labelText: 'Suas Observações',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    _buildSectionTitle('Registro de Avarias'),
                    SwitchListTile(
                      title: const Text('Veículo possui avarias?'),
                      value: _temAvarias,
                      onChanged: (bool value) =>
                          setState(() => _temAvarias = value),
                      secondary: Icon(
                        _temAvarias
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle_outline,
                        color: _temAvarias ? Colors.amber : Colors.green,
                      ),
                    ),
                    if (_temAvarias)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: TextFormField(
                          controller: _avariasController,
                          decoration: const InputDecoration(
                            labelText: 'Descreva as avarias',
                            hintText:
                                'Ex: Risco na porta direita, para-choque amassado...',
                          ),
                          maxLines: 4,
                        ),
                      ),
                    const SizedBox(height: 16),
                    Center(
                      child: _isSaving
                          ? const CircularProgressIndicator()
                          : ElevatedButton.icon(
                              onPressed: _saveChanges,
                              icon: const Icon(Icons.save),
                              label: const Text('Salvar Alterações'),
                            ),
                    ),

                    _buildSectionTitle('Checklist de Vistoria'),
                    const SizedBox(height: 8),
                    Center(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.checklist_rtl_rounded),
                        label: const Text('Abrir Checklist do Veículo'),
                        // [ATUALIZADO] Usando a cor do tema para consistência
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        // [ATUALIZADO] Lógica de clique do botão com as melhorias
                        onPressed: () {
                          // Previne o clique se os dados ainda não carregaram
                          if (_chamadoData == null) return;
                          Navigator.of(context)
                              .push(
                                MaterialPageRoute(
                                  builder: (context) => VehicleChecklistScreen(
                                    chamadoId: widget.chamadoId,
                                    initialData: _chamadoData!,
                                  ),
                                ),
                              )
                              .then(
                                // Atualiza os dados da tela de detalhes ao voltar do checklist
                                (_) =>
                                    _refreshIndicatorKey.currentState?.show(),
                              );
                        },
                      ),
                    ),
                    _buildSectionTitle('Fotos do Atendimento'),
                    _buildPhotoGallery(_chamadoData!['fotos'] ?? []),
                    const SizedBox(height: 16),
                    Center(
                      child: _isUploading
                          ? const CircularProgressIndicator()
                          : ElevatedButton.icon(
                              onPressed: _pickAndUploadImage,
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Adicionar Foto'),
                            ),
                    ),
                  ],
                ),
              ),
      ),
      // ... (FloatingActionButton sem alterações)
      floatingActionButton: (_chamadoData?['status'] == 'Concluído')
          ? null
          : _isEndingService
              ? const FloatingActionButton(
                  onPressed: null,
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : FloatingActionButton.extended(
                  onPressed: _endService,
                  label: const Text('Encerrar Atendimento'),
                  icon: const Icon(Icons.check_circle),
                  backgroundColor: Colors.red.shade700,
                ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // ... (Todos os widgets _build... sem alterações)
  Widget _buildPhotoGallery(List<dynamic> fotos) {
    if (fotos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20.0),
        child: Center(child: Text('Nenhuma foto adicionada.')),
      );
    }
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: fotos.length,
        itemBuilder: (context, index) {
          final foto = fotos[index];
          return Container(
            width: 120,
            margin: const EdgeInsets.only(right: 8.0),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Image.network(
                foto['url'],
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.error, color: Colors.red, size: 40),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value?.toString() ?? 'Não informado')),
        ],
      ),
    );
  }

  Widget _buildDetailChips(Map<String, dynamic> chamado) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: [
        Chip(
          label: Text(
            'Rodas Travadas: ${chamado['rodas_travadas'] ? "Sim" : "Não"}',
          ),
          backgroundColor: chamado['rodas_travadas']
              ? Colors.orange.shade700
              : Colors.grey.shade700,
        ),
        Chip(
          label: Text('Em Garagem: ${chamado['em_garagem'] ? "Sim" : "Não"}'),
          backgroundColor: chamado['em_garagem']
              ? Colors.orange.shade700
              : Colors.grey.shade700,
        ),
        Chip(
          label: Text(
            'Difícil Acesso: ${chamado['local_dificil_acesso'] ? "Sim" : "Não"}',
          ),
          backgroundColor: chamado['local_dificil_acesso']
              ? Colors.orange.shade700
              : Colors.grey.shade700,
        ),
      ],
    );
  }
}
