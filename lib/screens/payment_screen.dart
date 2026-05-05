import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class PaymentScreen extends StatefulWidget {
  final String planTitle;
  final String planPrice;
  final String planPeriod;
  final int planId; // 0: Monthly, 1: Yearly, 2: Lifetime

  const PaymentScreen({
    super.key,
    required this.planTitle,
    required this.planPrice,
    required this.planPeriod,
    required this.planId,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryMonthController = TextEditingController();
  final _expiryYearController = TextEditingController();
  final _cvvController = TextEditingController();
  final _emailController = TextEditingController();
  
  int _selectedPaymentMethod = 0; // 0: Card, 1: PayPal, 2: Bank Transfer
  bool _saveCardInfo = false;
  bool _isLoading = false;
  bool _acceptTerms = false;

  @override
  void initState() {
    super.initState();
    // Pré-remplir l'email si disponible
    // _emailController.text = currentUser?.email ?? '';
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryMonthController.dispose();
    _expiryYearController.dispose();
    _cvvController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Paiement sécurisé',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Order Summary ─────────────────────────────────────
              _OrderSummaryCard(
                planTitle: widget.planTitle,
                planPrice: widget.planPrice,
                planPeriod: widget.planPeriod,
              ),
              const SizedBox(height: 24),

              // ── Payment Methods ───────────────────────────────────
              _SectionHeader(title: 'Méthode de paiement'),
              const SizedBox(height: 16),
              
              _PaymentMethodTile(
                title: 'Carte bancaire',
                subtitle: 'Visa, Mastercard, etc.',
                icon: LucideIcons.creditCard,
                isSelected: _selectedPaymentMethod == 0,
                onTap: () => setState(() => _selectedPaymentMethod = 0),
              ),
              
              _PaymentMethodTile(
                title: 'PayPal',
                subtitle: 'Payer avec votre compte PayPal',
                icon: LucideIcons.wallet,
                isSelected: _selectedPaymentMethod == 1,
                onTap: () => setState(() => _selectedPaymentMethod = 1),
              ),
              
              _PaymentMethodTile(
                title: 'Virement bancaire',
                subtitle: 'Payer par virement bancaire',
                icon: LucideIcons.building,
                isSelected: _selectedPaymentMethod == 2,
                onTap: () => setState(() => _selectedPaymentMethod = 2),
              ),
              
              const SizedBox(height: 24),

              // ── Card Information (si carte sélectionnée) ───────────
              if (_selectedPaymentMethod == 0) ...[
                _SectionHeader(title: 'Informations de la carte'),
                const SizedBox(height: 16),
                
                _CreditCardForm(
                  cardNumberController: _cardNumberController,
                  cardHolderController: _cardHolderController,
                  expiryMonthController: _expiryMonthController,
                  expiryYearController: _expiryYearController,
                  cvvController: _cvvController,
                  saveCardInfo: _saveCardInfo,
                  onSaveCardChanged: (value) => setState(() => _saveCardInfo = value),
                ),
                
                const SizedBox(height: 24),
              ],

              // ── Billing Information ───────────────────────────────
              _SectionHeader(title: 'Informations de facturation'),
              const SizedBox(height: 16),
              
              _BillingForm(emailController: _emailController),
              
              const SizedBox(height: 24),

              // ── Terms and Conditions ───────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _acceptTerms,
                          onChanged: (value) {
                            setState(() {
                              _acceptTerms = value ?? false;
                            });
                          },
                          activeColor: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'J\'accepte les conditions générales de vente et la politique de confidentialité',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'En confirmant votre paiement, vous acceptez que votre abonnement soit renouvelé automatiquement selon la période sélectionnée.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSub,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),

              // ── Payment Button ─────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_acceptTerms && !_isLoading) ? _processPayment : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(LucideIcons.lock, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Payer ${widget.planPrice}',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // ── Security Info ─────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.shieldCheck,
                      size: 20,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Paiement 100% sécurisé via Stripe',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Simuler le traitement du paiement
      await Future.delayed(const Duration(seconds: 3));
      
      if (mounted) {
        // Afficher le succès
        _showPaymentSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du traitement du paiement'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showPaymentSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                LucideIcons.check,
                size: 40,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Paiement réussi !',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Votre abonnement ${widget.planTitle} est maintenant actif.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSub,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Fermer le dialogue
                  Navigator.pop(context); // Retour à l'écran précédent
                  Navigator.pop(context); // Retour au dashboard
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'Commencer à utiliser Skwilti Premium',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  final String planTitle;
  final String planPrice;
  final String planPeriod;

  const _OrderSummaryCard({
    required this.planTitle,
    required this.planPrice,
    required this.planPeriod,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(
                  LucideIcons.crown,
                  size: 25,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Récapitulatif de la commande',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Abonnement Skwilti Premium',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      planTitle,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      planPeriod,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                Text(
                  planPrice,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
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

class _PaymentMethodTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSub,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      LucideIcons.check,
                      size: 12,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _CreditCardForm extends StatelessWidget {
  final TextEditingController cardNumberController;
  final TextEditingController cardHolderController;
  final TextEditingController expiryMonthController;
  final TextEditingController expiryYearController;
  final TextEditingController cvvController;
  final bool saveCardInfo;
  final ValueChanged<bool> onSaveCardChanged;

  const _CreditCardForm({
    required this.cardNumberController,
    required this.cardHolderController,
    required this.expiryMonthController,
    required this.expiryYearController,
    required this.cvvController,
    required this.saveCardInfo,
    required this.onSaveCardChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          // Numéro de carte
          TextFormField(
            controller: cardNumberController,
            keyboardType: TextInputType.number,
            maxLength: 19,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer le numéro de votre carte';
              }
              if (value.length < 13) {
                return 'Numéro de carte invalide';
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: 'Numéro de carte',
              hintText: '1234 5678 9012 3456',
              prefixIcon: const Icon(LucideIcons.creditCard),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.border),
              ),
            ),
            inputFormatters: [
              // Formatter pour ajouter des espaces tous les 4 chiffres
            ],
          ),
          const SizedBox(height: 16),
          
          // Nom du titulaire
          TextFormField(
            controller: cardHolderController,
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer le nom du titulaire';
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: 'Nom du titulaire',
              hintText: 'JEAN DUPONT',
              prefixIcon: const Icon(LucideIcons.user),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.border),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Date d'expiration et CVV
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: expiryMonthController,
                  keyboardType: TextInputType.number,
                  maxLength: 2,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'MM';
                    }
                    int? month = int.tryParse(value);
                    if (month == null || month < 1 || month > 12) {
                      return 'Mois invalide';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Mois',
                    hintText: 'MM',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: expiryYearController,
                  keyboardType: TextInputType.number,
                  maxLength: 2,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'AA';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Année',
                    hintText: 'AA',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: cvvController,
                  keyboardType: TextInputType.number,
                  maxLength: 3,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'CVV';
                    }
                    if (value.length != 3) {
                      return 'CVV invalide';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'CVV',
                    hintText: '123',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Sauvegarder les informations
          Row(
            children: [
              Checkbox(
                value: saveCardInfo,
                onChanged: (value) => onSaveCardChanged(value ?? false),
                activeColor: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sauvegarder les informations de ma carte pour les prochains paiements',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.text,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BillingForm extends StatelessWidget {
  final TextEditingController emailController;

  const _BillingForm({required this.emailController});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer votre email';
              }
              if (!value.contains('@')) {
                return 'Veuillez entrer un email valide';
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: 'Email de facturation',
              hintText: 'votre@email.com',
              prefixIcon: const Icon(LucideIcons.mail),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.border),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
      ),
    );
  }
}
