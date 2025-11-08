import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FAQsScreen extends StatefulWidget {
  const FAQsScreen({super.key});

  @override
  State<FAQsScreen> createState() => _FAQsScreenState();
}

class _FAQsScreenState extends State<FAQsScreen> {
  int? _expandedIndex;

  final List<FAQItem> _faqs = [
    FAQItem(
      question: 'How do I place an order?',
      answer:
          'Browse our products, add items to your cart, and proceed to checkout. Enter your delivery address, select a payment method, and confirm your order. You\'ll receive an OTP for verification.',
    ),
    FAQItem(
      question: 'What are your delivery areas?',
      answer:
          'We currently deliver to Kandivali(W) and Malad(W) areas. We\'re working on expanding to more areas soon. Free delivery is available on orders above ₹500.',
    ),
    FAQItem(
      question: 'What payment methods do you accept?',
      answer:
          'We accept all major credit/debit cards, UPI (Google Pay, PhonePe, Paytm), net banking, and digital wallets. All payments are processed securely through Razorpay.',
    ),
    FAQItem(
      question: 'How long does delivery take?',
      answer:
          'Standard delivery takes 1-2 business days. We deliver Monday to Saturday between 9 AM and 6 PM. You\'ll receive SMS updates about your order status.',
    ),
    FAQItem(
      question: 'Can I modify or cancel my order?',
      answer:
          'You can cancel your order within 30 minutes of placing it. After that, please contact our support team. Once the order is shipped, cancellation may not be possible.',
    ),
    FAQItem(
      question: 'What is your return/refund policy?',
      answer:
          'We offer a 7-day return policy for fresh produce if items are damaged or not as described. Refunds are processed within 5-7 business days to your original payment method.',
    ),
    FAQItem(
      question: 'How do I track my order?',
      answer:
          'Go to the "My Orders" section in your profile. Click on any order to see its current status and tracking information. You\'ll also receive SMS updates.',
    ),
    FAQItem(
      question: 'Are your products fresh?',
      answer:
          'Yes! We source fresh produce daily from local farmers and suppliers. All products are quality-checked before delivery to ensure freshness and quality.',
    ),
    FAQItem(
      question: 'Do you offer discounts or promotions?',
      answer:
          'Yes! We regularly offer discounts, especially on bulk purchases. Check our app for ongoing promotions. We also offer special prices on 1kg quantities for weight-based products.',
    ),
    FAQItem(
      question: 'How do I update my delivery address?',
      answer:
          'Go to Profile > My Addresses. You can add, edit, or delete addresses. Set a default address for faster checkout.',
    ),
    FAQItem(
      question: 'What if I receive damaged items?',
      answer:
          'If you receive damaged or spoiled items, please contact our support team immediately with photos. We\'ll arrange a replacement or full refund.',
    ),
    FAQItem(
      question: 'Can I schedule a delivery time?',
      answer:
          'Currently, we deliver during our standard hours (9 AM - 6 PM). We\'re working on adding scheduled delivery options. Contact support for special requests.',
    ),
    FAQItem(
      question: 'How do I change my phone number?',
      answer:
          'Go to Profile > Edit Profile to update your phone number. You\'ll need to verify the new number with an OTP.',
    ),
    FAQItem(
      question: 'Is my personal information secure?',
      answer:
          'Yes, we take data security seriously. All personal information is encrypted and stored securely. We never share your data with third parties. Read our Privacy Policy for more details.',
    ),
    FAQItem(
      question: 'Do you have a minimum order value?',
      answer:
          'There\'s no minimum order value, but delivery charges may apply for orders below ₹500. Orders above ₹500 qualify for free delivery.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Frequently Asked Questions'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
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
            ),
            child: Column(
              children: [
                Icon(
                  Icons.help_outline,
                  size: 50,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                const Text(
                  'How can we help you?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Find answers to common questions',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),

          // FAQs List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _faqs.length,
              itemBuilder: (context, index) {
                final faq = _faqs[index];
                final isExpanded = _expandedIndex == index;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: isExpanded ? 4 : 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.help_outline,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      faq.question,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: isExpanded
                            ? Theme.of(context).colorScheme.primary
                            : Colors.black87,
                      ),
                    ),
                    trailing: Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    initiallyExpanded: isExpanded,
                    onExpansionChanged: (expanded) {
                      setState(() {
                        _expandedIndex = expanded ? index : null;
                      });
                    },
                    children: [
                      Divider(color: Colors.grey[300]),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          faq.answer,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Contact Support Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Still have questions?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => context.push('/profile/help-support'),
                  icon: const Icon(Icons.support_agent),
                  label: const Text('Contact Support'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({
    required this.question,
    required this.answer,
  });
}