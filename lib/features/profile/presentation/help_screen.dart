import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Ajuda',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 20,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            context,
            title: 'Central de Ajuda',
            children: [
              _buildHelpTile(
                context,
                icon: Icons.question_answer_outlined,
                title: 'Perguntas frequentes',
                subtitle: 'Respostas para dúvidas comuns',
                onTap: () => _showFAQ(context),
              ),
              _buildHelpTile(
                context,
                icon: Icons.chat_outlined,
                title: 'Chat com suporte',
                subtitle: 'Fale conosco em tempo real',
                onTap: () => _showComingSoon(context, 'Chat com suporte'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            title: 'Contato',
            children: [
              _buildHelpTile(
                context,
                icon: Icons.phone_outlined,
                title: 'Telefone',
                subtitle: '(11) 99999-9999',
                onTap: () => _launchPhone('11999999999'),
              ),
              _buildHelpTile(
                context,
                icon: Icons.email_outlined,
                title: 'E-mail',
                subtitle: 'contato@suevit.com.br',
                onTap: () => _launchEmail('contato@suevit.com.br'),
              ),
              _buildHelpTile(
                context,
                icon: Icons.language_outlined,
                title: 'Site',
                subtitle: 'www.suevit.com.br',
                onTap: () => _launchWebsite('https://www.suevit.com.br'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A1A),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildHelpTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 24),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF1A1A1A),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 13,
          color: const Color(0xFF757575),
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF9E9E9E)),
      onTap: onTap,
    );
  }

  void _showFAQ(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Perguntas Frequentes',
              style: GoogleFonts.dmSerifDisplay(fontSize: 24),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildFAQItem(
              'Como faço um pedido?',
              'Navegue pelos produtos, adicione ao carrinho e finalize a compra na tela de checkout.',
            ),
            _buildFAQItem(
              'Quais formas de pagamento aceitam?',
              'Aceitamos cartão de crédito, boleto e transferência bancária.',
            ),
            _buildFAQItem(
              'Como acompanho meu pedido?',
              'Vá em Meus Pedidos no menu e acompanhe o status em tempo real.',
            ),
            _buildFAQItem(
              'Posso cancelar um pedido?',
              'Sim, você pode cancelar até o pedido ser despachado. Entre em contato conosco.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            answer,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF757575),
            ),
          ),
        ),
      ],
    );
  }

  void _launchPhone(String phone) async {
    final Uri url = Uri.parse('tel:+55$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _launchEmail(String email) async {
    final Uri url = Uri.parse('mailto:$email');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _launchWebsite(String website) async {
    final Uri url = Uri.parse(website);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature em desenvolvimento'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
