// lib/helpers/pdf_generator.dart
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

class PdfGenerator {
  static Future<Uint8List> generatePdf(Map<String, dynamic> chamadoData) async {
    final pdf = pw.Document();
    final logoImage = pw.MemoryImage(
      (await rootBundle.load('assets/logo.png')).buffer.asUint8List(),
    );

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
                border: pw.Border.all(color: PdfColors.grey, width: 1),
              ),
              child: pw.Image(
                pw.MemoryImage(response.bodyBytes),
                fit: pw.BoxFit.cover,
                width: 150,
                height: 150,
              ),
            ),
          );
        }
      } catch (e) {
        print('Erro ao carregar imagem para PDF: $e');
        photoWidgets.add(pw.Text('Erro ao carregar imagem: ${foto['url']}'));
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => _buildHeader(logoImage, chamadoData),
        footer: (context) => _buildFooter(),
        build: (pw.Context context) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(flex: 1, child: _buildLeftColumn(chamadoData)),
              pw.SizedBox(width: 20),
              pw.Expanded(flex: 1, child: _buildRightColumn(chamadoData)),
            ],
          ),

          // Seção de Avarias no PDF
          if (chamadoData['avarias_registradas'] == true) ...[
            pw.Divider(height: 20, thickness: 1, color: PdfColors.grey),
            _buildSectionTitle('Registro de Avarias'),
            _buildInfoRow('Possui Avarias:', 'Sim'),
            _buildInfoRow('Descrição:', chamadoData['especificacao_avarias']),
          ],

          pw.Divider(height: 20, thickness: 1, color: PdfColors.grey),
          if (photoWidgets.isNotEmpty) ...[
            pw.Header(level: 1, text: 'Fotos do Atendimento'),
            pw.Wrap(children: photoWidgets),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(
    pw.MemoryImage logo,
    Map<String, dynamic> data,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 20),
      margin: const pw.EdgeInsets.only(bottom: 20),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey, width: 2),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Relatório de Atendimento',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'RescueNow System',
                style: pw.TextStyle(fontSize: 16, color: PdfColors.grey700),
              ),
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
        _buildInfoRow(
          'Ano/Cor:',
          '${data['ano_veiculo'] ?? ''} / ${data['cor_veiculo'] ?? ''}',
        ),
        _buildInfoRow('Placa:', data['placa_veiculo']),
        _buildInfoRow('Origem:', data['endereco_origem']),
        _buildInfoRow('Destino:', data['endereco_destino']),
        _buildSectionTitle('Condições'),
        _buildInfoRow(
          'Rodas Travadas:',
          data['rodas_travadas'] ? 'Sim' : 'Não',
        ),
        _buildInfoRow('Em Garagem:', data['em_garagem'] ? 'Sim' : 'Não'),
        _buildInfoRow(
          'Difícil Acesso:',
          data['local_dificil_acesso'] ? 'Sim' : 'Não',
        ),
      ],
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 12, bottom: 4),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 14,
          color: PdfColors.blueGrey800,
        ),
      ),
    );
  }

  static pw.Widget _buildInfoRow(String label, String? value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value ?? 'Não informado',
              style: const pw.TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey, width: 1)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text('Assinatura do Cliente:', style: pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 40),
          pw.Container(width: 300, child: pw.Divider()),
          pw.SizedBox(height: 20),
          pw.Text(
            'Documento gerado em: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
          ),
        ],
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
