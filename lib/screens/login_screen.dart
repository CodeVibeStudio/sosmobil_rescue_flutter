import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sosmobil_rescue_flutter/screens/home_screen.dart';
import 'package:url_launcher/url_launcher.dart'; // Para abrir links
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Pacote de ícones

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.message),
              backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: const Text('Ocorreu um erro inesperado.'),
              backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Função para abrir URLs
  Future<void> _launchURL(Uri url) async {
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Não foi possível abrir $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo (se houver)
              const SizedBox(height: 40),

              // --- ÍCONE ADICIONADO AQUI ---
              Image.asset(
                'assets/icon/icon.png', // O caminho relativo dentro do projeto
                height: 150, // Você pode ajustar a altura conforme necessário
              ),
              const SizedBox(height: 16), // Espaço entre o logo e o texto
              // --- FIM DA ADIÇÃO ---

              Text(
                'Bem-vindo ao RescueNow',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'E-mail'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Senha'),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _signIn,
                      child: const Text('Entrar'),
                    ),
              const SizedBox(height: 80), // Espaço para o rodapé

              // --- RODAPÉ COM AS NOVAS INFORMAÇÕES ---
              Column(
                children: [
                  const Text(
                    'Versão 1.0.0',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '© 2025 CodeVibe Studio. Todos os direitos reservados.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const FaIcon(FontAwesomeIcons.whatsapp,
                            color: Colors.green),
                        onPressed: () => _launchURL(Uri.parse(
                            'https://api.whatsapp.com/send/?phone=5532998111973')),
                        tooltip: 'Contato via WhatsApp',
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        icon: const FaIcon(FontAwesomeIcons.instagram,
                            color: Colors.purple),
                        onPressed: () => _launchURL(Uri.parse(
                            'https://www.instagram.com/codevibestudio/')),
                        tooltip: 'Siga-nos no Instagram',
                      ),
                    ],
                  )
                ],
              ),
              // --- FIM DO RODAPÉ ---
            ],
          ),
        ),
      ),
    );
  }
}
