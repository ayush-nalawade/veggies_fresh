import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
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
            // Header
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
                    Icons.gavel,
                    size: 50,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Terms & Conditions',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Last Updated: ${DateTime.now().toString().split(' ')[0]}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Introduction
            _buildSection(
              context,
              title: '1. Acceptance of Terms',
              content:
                  'By accessing and using the VeggieFresh mobile application ("App"), you accept and agree to be bound by these Terms and Conditions ("Terms"). If you do not agree to these Terms, please do not use our App or services.',
            ),

            // Eligibility
            _buildSection(
              context,
              title: '2. Eligibility',
              content:
                  'You must be at least 18 years old to use our services. By using the App, you represent and warrant that you are of legal age to form a binding contract and meet all eligibility requirements.',
            ),

            // Account Registration
            _buildSection(
              context,
              title: '3. Account Registration',
              content:
                  'To use certain features of the App, you must register for an account. You agree to:',
              points: [
                'Provide accurate, current, and complete information during registration',
                'Maintain and update your account information to keep it accurate',
                'Maintain the security of your account credentials',
                'Accept responsibility for all activities that occur under your account',
                'Notify us immediately of any unauthorized use of your account',
              ],
            ),

            // Products and Pricing
            _buildSection(
              context,
              title: '4. Products and Pricing',
              content: 'We strive to provide accurate product information and pricing. However:',
              points: [
                'Product images are for illustrative purposes and may not reflect exact appearance',
                'Prices are subject to change without notice',
                'We reserve the right to correct pricing errors',
                'Product availability is subject to change',
                'We may offer tiered pricing for weight-based products (e.g., 250gm, 500gm, 1kg)',
              ],
            ),

            // Orders and Payment
            _buildSection(
              context,
              title: '5. Orders and Payment',
              content: 'When placing an order:',
              points: [
                'All orders are subject to acceptance and availability',
                'You agree to provide accurate delivery information',
                'Payment must be made through approved payment methods',
                'We use secure payment gateways (Razorpay) for processing',
                'Order confirmation will be sent via SMS/email',
                'We reserve the right to refuse or cancel orders at our discretion',
              ],
            ),

            // Delivery
            _buildSection(
              context,
              title: '6. Delivery',
              content: 'Delivery terms:',
              points: [
                'We currently deliver to Kandivali(W) and Malad(W) areas',
                'Delivery times are estimates and not guaranteed',
                'Free delivery is available on orders above ₹500',
                'You must be available to receive the delivery at the specified address',
                'We are not responsible for delays due to circumstances beyond our control',
                'Risk of loss passes to you upon delivery',
              ],
            ),

            // Cancellation and Refunds
            _buildSection(
              context,
              title: '7. Cancellation and Refunds',
              content: 'Cancellation and refund policies:',
              points: [
                'You may cancel orders within 30 minutes of placement',
                'Cancellations after 30 minutes may not be possible if order is being processed',
                'Refunds will be processed to the original payment method within 5-7 business days',
                'Damaged or incorrect items are eligible for replacement or refund',
                'Fresh produce items are subject to quality checks upon delivery',
                'We reserve the right to refuse refunds for items consumed or used',
              ],
            ),

            // User Conduct
            _buildSection(
              context,
              title: '8. User Conduct',
              content: 'You agree not to:',
              points: [
                'Use the App for any illegal or unauthorized purpose',
                'Violate any laws in your jurisdiction',
                'Interfere with or disrupt the App or servers',
                'Attempt to gain unauthorized access to any part of the App',
                'Use automated systems to access the App without permission',
                'Impersonate any person or entity',
                'Harass, abuse, or harm other users',
              ],
            ),

            // Intellectual Property
            _buildSection(
              context,
              title: '9. Intellectual Property',
              content:
                  'All content, features, and functionality of the App, including but not limited to text, graphics, logos, images, and software, are owned by VeggieFresh and are protected by copyright, trademark, and other intellectual property laws.',
            ),

            // Limitation of Liability
            _buildSection(
              context,
              title: '10. Limitation of Liability',
              content:
                  'To the maximum extent permitted by law, VeggieFresh shall not be liable for any indirect, incidental, special, consequential, or punitive damages, or any loss of profits or revenues, whether incurred directly or indirectly, or any loss of data, use, goodwill, or other intangible losses resulting from your use of the App.',
            ),

            // Indemnification
            _buildSection(
              context,
              title: '11. Indemnification',
              content:
                  'You agree to indemnify, defend, and hold harmless VeggieFresh and its officers, directors, employees, and agents from any claims, damages, losses, liabilities, and expenses (including legal fees) arising out of your use of the App or violation of these Terms.',
            ),

            // Modifications
            _buildSection(
              context,
              title: '12. Modifications to Terms',
              content:
                  'We reserve the right to modify these Terms at any time. We will notify users of any material changes by posting the updated Terms in the App. Your continued use of the App after such modifications constitutes acceptance of the updated Terms.',
            ),

            // Termination
            _buildSection(
              context,
              title: '13. Termination',
              content:
                  'We may terminate or suspend your account and access to the App immediately, without prior notice, for any reason, including breach of these Terms. Upon termination, your right to use the App will cease immediately.',
            ),

            // Governing Law
            _buildSection(
              context,
              title: '14. Governing Law',
              content:
                  'These Terms shall be governed by and construed in accordance with the laws of India, without regard to its conflict of law provisions. Any disputes arising from these Terms shall be subject to the exclusive jurisdiction of the courts in Mumbai, India.',
            ),

            // Contact Information
            _buildSection(
              context,
              title: '15. Contact Information',
              content:
                  'If you have any questions about these Terms & Conditions, please contact us at:',
              points: [
                'Email: legal@veggiefresh.com',
                'Phone: +91 1234567890',
                'Address: VeggieFresh, Mumbai, India',
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String content,
    List<String>? points,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            height: 1.6,
          ),
        ),
        if (points != null) ...[
          const SizedBox(height: 12),
          ...points.map((point) => Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        point,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}