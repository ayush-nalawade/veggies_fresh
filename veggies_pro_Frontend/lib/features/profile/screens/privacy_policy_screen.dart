import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
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
                    Icons.privacy_tip,
                    size: 50,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Privacy Policy',
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
              title: '1. Introduction',
              content:
                  'VeggieFresh ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application and services. Please read this policy carefully to understand our practices regarding your personal data.',
            ),

            // Information We Collect
            _buildSection(
              context,
              title: '2. Information We Collect',
              content: 'We collect information that you provide directly to us, including:',
              points: [
                'Personal Information: Name, email address, phone number, and delivery address',
                'Account Information: Profile details, preferences, and authentication credentials',
                'Order Information: Purchase history, payment details, and delivery preferences',
                'Communication Data: Messages, feedback, and support requests',
                'Device Information: Device type, operating system, unique device identifiers, and mobile network information',
                'Usage Data: App usage patterns, features accessed, and interaction data',
                'Location Data: Delivery address and approximate location (with your consent)',
              ],
            ),

            // How We Use Your Information
            _buildSection(
              context,
              title: '3. How We Use Your Information',
              content: 'We use the collected information for the following purposes:',
              points: [
                'To process and fulfill your orders and deliver products to you',
                'To communicate with you about your orders, account, and our services',
                'To send you promotional offers, newsletters, and marketing communications (with your consent)',
                'To improve our services, app functionality, and user experience',
                'To prevent fraud, abuse, and ensure security',
                'To comply with legal obligations and enforce our terms',
                'To provide customer support and respond to your inquiries',
                'To analyze usage patterns and conduct research',
              ],
            ),

            // Information Sharing
            _buildSection(
              context,
              title: '4. Information Sharing and Disclosure',
              content:
                  'We do not sell your personal information. We may share your information in the following circumstances:',
              points: [
                'Service Providers: With third-party vendors who perform services on our behalf (payment processing, delivery, analytics)',
                'Business Transfers: In connection with any merger, sale, or acquisition of our business',
                'Legal Requirements: When required by law, court order, or government regulation',
                'Protection of Rights: To protect our rights, property, or safety, or that of our users',
                'With Your Consent: When you explicitly consent to sharing',
              ],
            ),

            // Data Security
            _buildSection(
              context,
              title: '5. Data Security',
              content:
                  'We implement appropriate technical and organizational security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction. However, no method of transmission over the internet or electronic storage is 100% secure.',
            ),

            // Your Rights
            _buildSection(
              context,
              title: '6. Your Rights and Choices',
              content: 'You have the following rights regarding your personal information:',
              points: [
                'Access: Request access to your personal data',
                'Correction: Request correction of inaccurate or incomplete data',
                'Deletion: Request deletion of your personal data (subject to legal requirements)',
                'Objection: Object to processing of your personal data',
                'Portability: Request transfer of your data to another service',
                'Withdraw Consent: Withdraw consent for data processing where applicable',
                'Opt-out: Unsubscribe from marketing communications',
              ],
            ),

            // Cookies and Tracking
            _buildSection(
              context,
              title: '7. Cookies and Tracking Technologies',
              content:
                  'We use cookies and similar tracking technologies to track activity on our app and store certain information. You can instruct your device to refuse all cookies or to indicate when a cookie is being sent.',
            ),

            // Third-Party Links
            _buildSection(
              context,
              title: '8. Third-Party Links',
              content:
                  'Our app may contain links to third-party websites or services. We are not responsible for the privacy practices of these third parties. We encourage you to read their privacy policies.',
            ),

            // Children's Privacy
            _buildSection(
              context,
              title: '9. Children\'s Privacy',
              content:
                  'Our services are not intended for children under 18 years of age. We do not knowingly collect personal information from children. If you believe we have collected information from a child, please contact us immediately.',
            ),

            // Data Retention
            _buildSection(
              context,
              title: '10. Data Retention',
              content:
                  'We retain your personal information for as long as necessary to fulfill the purposes outlined in this policy, unless a longer retention period is required or permitted by law.',
            ),

            // Changes to Policy
            _buildSection(
              context,
              title: '11. Changes to This Privacy Policy',
              content:
                  'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new policy on this page and updating the "Last Updated" date. You are advised to review this policy periodically.',
            ),

            // Contact Information
            _buildSection(
              context,
              title: '12. Contact Us',
              content:
                  'If you have any questions about this Privacy Policy or wish to exercise your rights, please contact us at:',
              points: [
                'Email: privacy@veggiefresh.com',
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