// lib/helpers/pdf_generator.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

class PdfGenerator {
  static Future<Uint8List> generatePdf(Map<String, dynamic> chamadoData) async {
    final pdf = pw.Document();

    // --- CORREÇÃO: Removido o "assets/" duplicado do caminho ---
    final logoData = await rootBundle.load('assets/logo.png');
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    // --- FIM DA CORREÇÃO ---

    // Carrega as fotos do atendimento
    final List<pw.Widget> photoWidgets = [];
    final List<dynamic> fotos = chamadoData['fotos'] ?? [];
    for (var foto in fotos) {
      try {
        final response = await http.get(Uri.parse(foto['url']));
        if (response.statusCode == 200) {
          photoWidgets.add(
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10, right: 10),
              decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey, width: 1)),
              child: pw.Image(pw.MemoryImage(response.bodyBytes),
                  fit: pw.BoxFit.cover, width: 150, height: 150),
            ),
          );
        }
      } catch (e) {
        print('Erro ao carregar imagem para PDF: $e');
      }
    }

    // Decodifica as imagens das assinaturas a partir do formato base64
    final signaturesData = chamadoData['signatures'] as Map<String, dynamic>?;
    final requesterSignatureBytes =
        signaturesData?['requester_signature_base64'] != null
            ? base64Decode(signaturesData!['requester_signature_base64'])
            : null;
    final recipientSignatureBytes =
        signaturesData?['recipient_signature_base64'] != null
            ? base64Decode(signaturesData!['recipient_signature_base64'])
            : null;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => _buildHeader(logoImage, chamadoData),
        footer: (context) => _buildPageFooter(context),
        build: (pw.Context context) => [
          // --- SEÇÃO 1: DADOS GERAIS ---
          pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Expanded(flex: 1, child: _buildLeftColumn(chamadoData)),
            pw.SizedBox(width: 20),
            pw.Expanded(flex: 1, child: _buildRightColumn(chamadoData)),
          ]),
          pw.Divider(height: 20, thickness: 1.5, color: PdfColors.blueGrey),

          // --- SEÇÃO 2: CHECKLIST DE VISTORIA ---
          _buildChecklistSection(chamadoData),
          pw.Divider(height: 20, thickness: 1.5, color: PdfColors.blueGrey),

          // --- SEÇÃO 3: FOTOS DO ATENDIMENTO ---
          if (photoWidgets.isNotEmpty) ...[
            pw.Header(level: 1, text: 'Fotos do Atendimento'),
            pw.Wrap(children: photoWidgets),
            pw.SizedBox(height: 20),
          ],

          // --- SEÇÃO 4: ASSINATURAS E TERMOS ---
          _buildSignaturesSection(
            signaturesData,
            requesterSignatureBytes,
            recipientSignatureBytes,
          ),
        ],
      ),
    );

    return pdf.save();
  }

  // --- Funções de Construção de Widgets do PDF ---

  static pw.Widget _buildHeader(
      pw.MemoryImage logo, Map<String, dynamic> data) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 20),
      margin: const pw.EdgeInsets.only(bottom: 20),
      decoration: const pw.BoxDecoration(
          border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.grey, width: 2))),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Relatório de Atendimento',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.Text('RescueNow System',
                  style: pw.TextStyle(fontSize: 16, color: PdfColors.grey700)),
            ],
          ),
          pw.SizedBox(height: 60, width: 60, child: pw.Image(logo)),
        ],
      ),
    );
  }

  static pw.Widget _buildLeftColumn(Map<String, dynamic> data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Detalhes do Serviço'),
        _buildInfoRow('Nº Assistência:', data['numero_assistencia']),
        _buildInfoRow('Tipo de Serviço:', data['tipo_servico']),
        _buildInfoRow('Motivo:', data['motivo_acionamento']),
        _buildInfoRow('Data/Hora:', _formatDate(data['data_hora_servico'])),
        _buildSectionTitle('Cliente'),
        _buildInfoRow('Nome:', data['nome_segurado']),
        _buildInfoRow('Telefone:', data['telefone_segurado']),
      ],
    );
  }

  static pw.Widget _buildRightColumn(Map<String, dynamic> data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Veículo e Local'),
        _buildInfoRow('Veículo:', '${data['marca_modelo_veiculo'] ?? ''}'),
        _buildInfoRow('Ano/Cor:',
            '${data['ano_veiculo'] ?? ''} / ${data['cor_veiculo'] ?? ''}'),
        _buildInfoRow('Placa:', data['placa_veiculo']),
        _buildInfoRow('Origem:', data['endereco_origem']),
        _buildInfoRow('Destino:', data['endereco_destino']),
      ],
    );
  }

  static pw.Widget _buildChecklistSection(Map<String, dynamic> data) {
    final damagePoints =
        data['vehicle_damage_points'] as Map<String, dynamic>? ?? {};
    final accessories =
        data['accessories_checklist'] as Map<String, dynamic>? ?? {};

    final damages = damagePoints.entries
        .where((entry) => entry.value != 'none')
        .map((entry) => '${entry.key.replaceAll('_', ' ')}: ${entry.value}')
        .toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Header(level: 1, text: 'Checklist de Vistoria'),
        _buildInfoRow('Nível de Combustível:',
            data['fuel_level']?.replaceAll('_', ' ') ?? 'Não informado'),
        _buildInfoRow(
            'Estado dos Pneus:', data['tires_state'] ?? 'Não informado'),
        pw.SizedBox(height: 10),
        _buildSectionTitle('Avarias Registadas'),
        damages.isNotEmpty
            ? pw.Wrap(
                spacing: 8,
                runSpacing: 4,
                children: damages
                    .map((d) => _buildChip(d, PdfColors.orange100))
                    .toList(),
              )
            : pw.Text('Nenhuma avaria registada.'),
        pw.SizedBox(height: 10),
        _buildSectionTitle('Acessórios'),
        pw.Wrap(
          spacing: 5,
          runSpacing: 5,
          children: accessories.entries.map((entry) {
            return _buildChip(
              '${entry.key}: ${entry.value}',
              entry.value == 'S'
                  ? PdfColors.green100
                  : (entry.value == 'N'
                      ? PdfColors.red100
                      : PdfColors.yellow100),
            );
          }).toList(),
        ),
      ],
    );
  }

  static pw.Widget _buildSignaturesSection(Map<String, dynamic>? signatures,
      Uint8List? requesterSignature, Uint8List? recipientSignature) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Header(level: 1, text: 'Assinaturas e Responsabilidades'),
        pw.Text(
          "Declaro estar de acordo com as informações contidas neste formulário.",
          style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          "OBSERVAÇÃO: A AUTO SOCORRO LARANJAL, NÃO SE RESPONSABILIZA POR OBJETOS DEIXADOS DENTRO DO VEÍCULO.",
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 30),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            _buildSignatureBlock('Solicitante', signatures?['requester_name'],
                requesterSignature),
            _buildSignatureBlock('Destinatário', signatures?['recipient_name'],
                recipientSignature),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildSignatureBlock(
      String title, String? name, Uint8List? signatureBytes) {
    return pw.Column(
      children: [
        if (signatureBytes != null)
          pw.Container(
            height: 80,
            width: 180,
            child: pw.Image(pw.MemoryImage(signatureBytes)),
          ),
        pw.Container(width: 200, child: pw.Divider(height: 10)),
        pw.Text(name ?? '_________________________'),
        pw.Text(title),
      ],
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 12, bottom: 4),
      child: pw.Text(title,
          style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 14,
              color: PdfColors.blueGrey800)),
    );
  }

  static pw.Widget _buildInfoRow(String label, String? value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
              width: 120,
              child: pw.Text(label,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
          pw.Expanded(
              child: pw.Text(value ?? 'Não informado',
                  style: const pw.TextStyle(fontSize: 11))),
        ],
      ),
    );
  }

  static pw.Widget _buildChip(String text, PdfColor color) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(right: 5, bottom: 5),
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 9)),
    );
  }

  static pw.Widget _buildPageFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        'Página ${context.pageNumber} de ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
      ),
    );
  }

  static String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Não informado';
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (e) {
      return dateStr;
    }
  }
}
