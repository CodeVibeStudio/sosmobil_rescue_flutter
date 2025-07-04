// lib/screens/contact_screen.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sosmobil_rescue_flutter/l10n/app_localizations.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  // --- ATENÇÃO: Configure estes dados com os da sua base ---
  final String numeroTelefone = '+5511999998888'; // Inclua o código do país
  final String numeroWhatsApp = '+5511999998888'; // Inclua o código do país
  final String emailBase = 'contato@suaempresa.com';
  // ---------------------------------------------------------

  // Função para tentar abrir uma URL
  Future<void> _launchUrl(Uri url, BuildContext context) async {
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível abrir o link: $url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.contactBase), // Usa a tradução
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            _buildContactButton(
              context: context,
              icon: Icons.phone,
              label: l10n.callBase, // Usa a tradução
              color: Colors.green,
              onPressed: () {
                final Uri phoneUri = Uri(scheme: 'tel', path: numeroTelefone);
                _launchUrl(phoneUri, context);
              },
            ),
            const SizedBox(height: 20),
            _buildContactButton(
              context: context,
              icon: Icons.chat,
              label: l10n.sendWhatsApp, // Usa a tradução
              color: Colors.teal,
              onPressed: () {
                final Uri whatsappUri = Uri.parse(
                  'https://wa.me/$numeroWhatsApp',
                );
                _launchUrl(whatsappUri, context);
              },
            ),
            const SizedBox(height: 20),
            _buildContactButton(
              context: context,
              icon: Icons.email,
              label: l10n.sendEmail, // Usa a tradução
              color: Colors.orange,
              onPressed: () {
                final Uri emailUri = Uri(
                  scheme: 'mailto',
                  path: emailBase,
                  query:
                      'subject=Contato do App RescueNow&body=Olá, preciso de ajuda.',
                );
                _launchUrl(emailUri, context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
