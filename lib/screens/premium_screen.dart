import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'payment_screen.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  int _selectedPlan = 1; // 0: Monthly, 1: Yearly, 2: Lifetime

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
          'Passer au Premium',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(24),
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
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Icon(
                          LucideIcons.crown,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Skwilti Premium',
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Débloquez toutes les fonctionnalités',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Benefits ─────────────────────────────────────────────
            _SectionHeader(title: 'Avantages Premium'),
            const SizedBox(height: 16),
            
            ..._benefits.map((benefit) => _BenefitTile(
              icon: benefit['icon'] as IconData,
              title: benefit['title'] as String,
              description: benefit['description'] as String,
            )),
            
            const SizedBox(height: 32),

            // ── Pricing Plans ───────────────────────────────────────
            _SectionHeader(title: 'Choisissez votre plan'),
            const SizedBox(height: 16),
            
            Column(
              children: [
                _PlanCard(
                  title: 'Mensuel',
                  price: '9,99€',
                  period: '/mois',
                  features: ['Accès complet', 'Support prioritaire', 'Mises à jour'],
                  isSelected: _selectedPlan == 0,
                  onTap: () => setState(() => _selectedPlan = 0),
                ),
                const SizedBox(height: 12),
                _PlanCard(
                  title: 'Annuel',
                  price: '79,99€',
                  period: '/an',
                  features: ['Accès complet', 'Support prioritaire', 'Mises à jour', 'Économisez 33%'],
                  isSelected: _selectedPlan == 1,
                  onTap: () => setState(() => _selectedPlan = 1),
                  isPopular: true,
                ),
                const SizedBox(height: 12),
                _PlanCard(
                  title: 'À vie',
                  price: '199,99€',
                  period: '/unique',
                  features: ['Accès complet', 'Support prioritaire', 'Mises à jour', 'Accès à vie'],
                  isSelected: _selectedPlan == 2,
                  onTap: () => setState(() => _selectedPlan = 2),
                ),
              ],
            ),
            
            const SizedBox(height: 32),

            // ── Testimonials ────────────────────────────────────────
            _SectionHeader(title: 'Ce que nos utilisateurs en disent'),
            const SizedBox(height: 16),
            
            SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _testimonials.length,
                itemBuilder: (context, index) {
                  final testimonial = _testimonials[index];
                  return Container(
                    width: 280,
                    margin: const EdgeInsets.only(right: 12),
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
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                LucideIcons.user,
                                size: 20,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    testimonial['name'] as String,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.text,
                                    ),
                                  ),
                                  Text(
                                    testimonial['role'] as String,
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: AppColors.textSub,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: List.generate(5, (index) => const Icon(
                            LucideIcons.star,
                            size: 12,
                            color: Colors.amber,
                          )),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          testimonial['comment'] as String,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.text,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 32),

            // ── CTA Button ───────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _subscribeToPremium,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'S\'abonner maintenant',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Center(
              child: TextButton(
                onPressed: () {
                  // Navigation vers aide et support pour réclamations
                },
                child: Text(
                  'Besoin d\'aide ? Contactez-nous',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _BenefitTile({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: AppColors.primary,
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
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSub,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _PlanCard({
    required String title,
    required String price,
    required String period,
    required List<String> features,
    required bool isSelected,
    required VoidCallback onTap,
    bool isPopular = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 0.5,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: Column(
          children: [
            if (isPopular) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'POPULAIRE',
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  period,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSub,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...features.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.check,
                    size: 12,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _subscribeToPremium() {
    // Déterminer le plan sélectionné et naviguer vers l'écran de paiement
    String planTitle = '';
    String planPrice = '';
    String planPeriod = '';
    
    switch (_selectedPlan) {
      case 0:
        planTitle = 'Mensuel';
        planPrice = '9,99€';
        planPeriod = '/mois';
        break;
      case 1:
        planTitle = 'Annuel';
        planPrice = '79,99€';
        planPeriod = '/an';
        break;
      case 2:
        planTitle = 'À vie';
        planPrice = '199,99€';
        planPeriod = '/unique';
        break;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          planTitle: planTitle,
          planPrice: planPrice,
          planPeriod: planPeriod,
          planId: _selectedPlan,
        ),
      ),
    );
  }

  static final _benefits = [
    {
      'icon': LucideIcons.infinity,
      'title': 'Accès illimité',
      'description': 'Accédez à tous les cours et QSM sans limites',
    },
    {
      'icon': LucideIcons.downloadCloud,
      'title': 'Téléchargements illimités',
      'description': 'Téléchargez tous les supports de cours',
    },
    {
      'icon': LucideIcons.headphones,
      'title': 'Support prioritaire',
      'description': 'Obtenez une assistance rapide et personnalisée',
    },
    {
      'icon': LucideIcons.zap,
      'title': 'Fonctionnalités exclusives',
      'description': 'Accédez aux nouvelles fonctionnalités en avant-première',
    },
    {
      'icon': LucideIcons.trendingUp,
      'title': 'Analyses avancées',
      'description': 'Suivez vos progrès avec des statistiques détaillées',
    },
  ];

  static final _testimonials = [
    {
      'name': 'Marie Dupont',
      'role': 'Enseignante',
      'comment': 'Skwilti Premium a transformé ma façon d\'enseigner. Les élèves sont plus engagés et les résultats sont excellents !',
    },
    {
      'name': 'Thomas Martin',
      'role': 'Étudiant',
      'comment': 'Les cours de qualité et les QSM interactifs m\'ont aidé à améliorer mes notes de manière significative.',
    },
    {
      'name': 'Sophie Bernard',
      'role': 'Parent',
      'comment': 'Excellent investissement pour l\'éducation de mes enfants. Interface intuitive et contenu pédagogique de qualité.',
    },
  ];
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
