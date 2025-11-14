import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _launchEmail() async {
    try {
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: 'support@veggiefresh.com',
        query: 'subject=Support Request',
      );
      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      // Handle error silently or show a message
    }
  }

  Future<void> _launchPhone() async {
    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: '+911234567890');
      await launchUrl(phoneUri);
    } catch (e) {
      // Handle error silently or show a message
    }
  }

  Future<void> _launchWhatsApp() async {
    try {
      final Uri whatsappUri = Uri.parse('https://wa.me/911234567890?text=Hello, I need help with VeggieFresh');
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      // Handle error silently or show a message
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.support_agent,
                    size: 60,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'We\'re Here to Help!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Get in touch with our support team',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Contact Options
            _buildSectionTitle('Contact Us'),
            const SizedBox(height: 12),
            _buildContactCard(
              context,
              icon: Icons.email,
              title: 'Email Support',
              subtitle: 'support@veggiefresh.com',
              description: 'Send us an email and we\'ll respond within 24 hours',
              onTap: _launchEmail,
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildContactCard(
              context,
              icon: Icons.phone,
              title: 'Phone Support',
              subtitle: '+91 1234567890',
              description: 'Call us Monday to Friday, 9 AM - 6 PM IST',
              onTap: _launchPhone,
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            _buildContactCard(
              context,
              icon: Icons.chat,
              title: 'WhatsApp Support',
              subtitle: 'Chat with us on WhatsApp',
              description: 'Get instant help via WhatsApp',
              onTap: _launchWhatsApp,
              color: Colors.green.shade700,
            ),
            const SizedBox(height: 32),

            // Quick Help Section
            _buildSectionTitle('Quick Help'),
            const SizedBox(height: 12),
            _buildHelpCard(
              context,
              icon: Icons.help_outline,
              title: 'Frequently Asked Questions',
              subtitle: 'Find answers to common questions',
              onTap: () => context.push('/profile/faqs'),
            ),
            const SizedBox(height: 12),
            _buildHelpCard(
              context,
              icon: Icons.shopping_bag_outlined,
              title: 'Order Help',
              subtitle: 'Track orders, returns, and refunds',
              onTap: () {
                final messenger = ScaffoldMessenger.maybeOf(context);
                messenger?.showSnackBar(
                  const SnackBar(
                    content: Text('Navigate to Orders page for order-related help'),
                  ),
                );
                context.push('/orders');
              },
            ),
            const SizedBox(height: 12),
            _buildHelpCard(
              context,
              icon: Icons.payment,
              title: 'Payment Help',
              subtitle: 'Payment methods and issues',
              onTap: () {
                final messenger = ScaffoldMessenger.maybeOf(context);
                messenger?.showSnackBar(
                  const SnackBar(
                    content: Text('We accept all major credit/debit cards, UPI, and digital wallets'),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildHelpCard(
              context,
              icon: Icons.local_shipping,
              title: 'Delivery Help',
              subtitle: 'Delivery areas, timings, and charges',
              onTap: () {
                final messenger = ScaffoldMessenger.maybeOf(context);
                messenger?.showSnackBar(
                  const SnackBar(
                    content: Text('We deliver to Kandivali(W) and Malad(W). Free delivery on orders above ₹500'),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            // Business Hours
            _buildSectionTitle('Business Hours'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  _buildBusinessHourRow('Monday - Friday', '9:00 AM - 6:00 PM'),
                  const Divider(),
                  _buildBusinessHourRow('Saturday', '10:00 AM - 4:00 PM'),
                  const Divider(),
                  _buildBusinessHourRow('Sunday', 'Closed'),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Legal Links
            _buildSectionTitle('Legal'),
            const SizedBox(height: 12),
            _buildLegalLink(
              context,
              title: 'Privacy Policy',
              onTap: () => context.push('/profile/privacy-policy'),
            ),
            const SizedBox(height: 8),
            _buildLegalLink(
              context,
              title: 'Terms & Conditions',
              onTap: () => context.push('/profile/terms-conditions'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String description,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelpCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildBusinessHourRow(String day, String time) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          day,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          time,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildLegalLink(
    BuildContext context, {
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      child: ListTile(
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}