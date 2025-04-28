import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/custom_scaffold.dart';
import '../theme/theme.dart';
import '../models/subscription.dart';
import '../providers/company_provider.dart';
import 'package:provider/provider.dart';

class SubscriptionSpoofScreen extends StatefulWidget {
  const SubscriptionSpoofScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionSpoofScreen> createState() =>
      _SubscriptionSpoofScreenState();
}

class _SubscriptionSpoofScreenState extends State<SubscriptionSpoofScreen> {
  bool _isLoading = false;
  String _selectedPlan = 'premium';
  final _durationController = TextEditingController(text: '30');

  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _activateSubscription() async {
    if (_selectedPlan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a subscription plan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final duration = int.tryParse(_durationController.text);
    if (duration == null || duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid duration'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final companyProvider =
          Provider.of<CompanyProvider>(context, listen: false);
      final company = companyProvider.currentCompany;

      if (company == null) {
        throw Exception('No company selected');
      }

      // Calculate start and end dates
      final now = DateTime.now();
      final endDate = now.add(Duration(days: duration));
      // Create subscription object
      final subscription = Subscription(
        id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
        plan: _selectedPlan,
        status: 'active',
        startDate: now,
        endDate: endDate,
        companyId: company.id,
        createdAt: now,
        updatedAt: now,
      );

      // Update company document with subscription
      await FirebaseFirestore.instance
          .collection('companies')
          .doc(company.id)
          .update({
        'subscription': subscription.toMap(),
        'features': _getFeatures(_selectedPlan),
      });

      // Update local company data
      final updatedCompany = company.copyWith(subscription: subscription);
      await companyProvider.updateCompany(updatedCompany);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subscription activated successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back to settings
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error activating subscription: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<String> _getFeatures(String plan) {
    switch (plan) {
      case 'basic':
        return [
          'Up to 5 clients',
          'Up to 20 invoices per month',
          'Basic invoice templates',
        ];
      case 'professional':
        return [
          'Unlimited clients',
          'Up to 100 invoices per month',
          'Professional invoice templates',
          'Company logo on invoices',
          'Email support',
        ];
      case 'premium':
        return [
          'Unlimited clients',
          'Unlimited invoices',
          'Premium invoice templates',
          'Company logo on invoices',
          'Priority email support',
          'Phone support',
          'Custom invoice fields',
          'Advanced reporting',
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: 'Subscription Spoof',
      selectedIndex: 5, // Settings is selected
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Warning card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.red[100]!,
                            Colors.red[50]!,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.6),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.red[700]!,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.code,
                                  color: Colors.red[700],
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Developer Mode',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red[700],
                                        fontSize: 22,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Testing environment only',
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.red[200]!,
                              ),
                            ),
                            child: const Text(
                              'This screen allows you to activate subscription features for testing purposes without actual payment processing. Use this to test premium features like company logo upload.',
                              style: TextStyle(
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Subscription plan selection
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.star_outline,
                                  color: AppTheme.accentColor,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Text(
                                'Select Subscription Plan',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),

                          // Plan cards
                          _buildPlanCard(
                            'Basic',
                            'basic',
                            Colors.blue,
                            [
                              'Up to 5 clients',
                              'Up to 20 invoices per month',
                              'Basic invoice templates',
                            ],
                          ),

                          const SizedBox(height: 16),

                          _buildPlanCard(
                            'Professional',
                            'professional',
                            Colors.green,
                            [
                              'Unlimited clients',
                              'Up to 100 invoices per month',
                              'Professional invoice templates',
                              'Company logo on invoices',
                              'Email support',
                            ],
                          ),

                          const SizedBox(height: 16),

                          _buildPlanCard(
                            'Premium',
                            'premium',
                            Colors.purple,
                            [
                              'Unlimited clients',
                              'Unlimited invoices',
                              'Premium invoice templates',
                              'Company logo on invoices',
                              'Priority email support',
                              'Phone support',
                              'Custom invoice fields',
                              'Advanced reporting',
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Duration selection
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.calendar_today,
                                  color: AppTheme.accentColor,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Text(
                                'Subscription Duration',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _durationController,
                            decoration: InputDecoration(
                              labelText: 'Duration (days)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.timer),
                              suffixText: 'days',
                              floatingLabelStyle: TextStyle(
                                color: AppTheme.accentColor,
                                fontWeight: FontWeight.bold,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppTheme.accentColor,
                                  width: 2,
                                ),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                          ),

                          const SizedBox(height: 16),

                          // Duration quick select buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildDurationButton('7 days', '7'),
                              _buildDurationButton('30 days', '30'),
                              _buildDurationButton('90 days', '90'),
                              _buildDurationButton('365 days', '365'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Activate button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _activateSubscription,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentColor,
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 3,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.verified),
                                SizedBox(width: 12),
                                Text(
                                  'Activate Subscription',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDurationButton(String label, String days) {
    return InkWell(
      onTap: () {
        setState(() {
          _durationController.text = days;
        });
      },
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _durationController.text == days
              ? AppTheme.accentColor.withOpacity(0.2)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: _durationController.text == days
                ? AppTheme.accentColor
                : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: _durationController.text == days
                ? AppTheme.accentColor
                : Colors.grey[700],
            fontWeight: _durationController.text == days
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    String title,
    String planId,
    Color color,
    List<String> features,
  ) {
    final isSelected = _selectedPlan == planId;

    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? color : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPlan = planId;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withOpacity(0.1),
                      Colors.white,
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Icon(
                      isSelected ? Icons.check_circle : Icons.star,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              ...features.map((feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check,
                            size: 14,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            feature,
                            style: TextStyle(
                              fontSize: 15,
                              color:
                                  isSelected ? Colors.black87 : Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
