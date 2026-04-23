import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import '../widgets/common_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _n8nUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pré-remplir avec l'URL actuelle
    _n8nUrlController.text = context.read<AppState>().n8nUrl;
  }

  @override
  void dispose() {
    _n8nUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(state),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildStatsGrid(state),
                const SizedBox(height: 20),
                _buildMenuSection('Compte', [
                  (LucideIcons.user, 'Mon profil', AppColors.primaryLight, AppColors.primary),
                  (LucideIcons.bell, 'Notifications', AppColors.orangeLight, AppColors.orange),
                  (LucideIcons.settings, 'Paramètres', AppColors.primaryLight, AppColors.primary),
                ]),
                const SizedBox(height: 16),
                _buildMenuSection('Application', [
                  (LucideIcons.wifi, 'URL n8n Webhook', AppColors.successLight, AppColors.success),
                  (LucideIcons.helpCircle, 'Aide & Support', AppColors.orangeLight, AppColors.orange),
                  (LucideIcons.info, 'À propos', AppColors.primaryLight, AppColors.primary),
                ]),
                const SizedBox(height: 16),
                // n8n config card
                SkwCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(LucideIcons.zap, size: 15, color: AppColors.orange),
                        const SizedBox(width: 7),
                        const Text('Configuration n8n',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      ]),
                      const SizedBox(height: 10),
                      const Text(
                        'Entrez l\'URL de votre webhook n8n pour activer la génération de QCM par l\'IA.',
                        style: TextStyle(fontSize: 11, color: AppColors.textSub, height: 1.5),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _n8nUrlController,
                        decoration: InputDecoration(
                          hintText: 'https://votre-n8n.com/webhook/skwilti-qcm',
                          hintStyle: const TextStyle(fontSize: 11, color: AppColors.textSub),
                          prefixIcon: const Icon(LucideIcons.link, size: 14, color: AppColors.textSub),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.border, width: 0.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.border, width: 0.5),
                          ),
                        ),
                        style: const TextStyle(fontSize: 11),
                      ),
                      const SizedBox(height: 8),
                      // Raccourcis URL
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                _n8nUrlController.text = 'http://10.0.2.2:5678/webhook-test/skwilti_app';
                              },
                              icon: const Icon(LucideIcons.testTube, size: 12),
                              label: const Text('Test', style: TextStyle(fontSize: 10)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                side: const BorderSide(color: AppColors.primary, width: 0.5),
                                foregroundColor: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                _n8nUrlController.text = 'https://votre-n8n.com/webhook/skwilti-app';
                              },
                              icon: const Icon(LucideIcons.globe, size: 12),
                              label: const Text('Production', style: TextStyle(fontSize: 10)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                side: const BorderSide(color: AppColors.orange, width: 0.5),
                                foregroundColor: AppColors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: SkwBtn(
                          label: 'Sauvegarder', 
                          icon: LucideIcons.save, 
                          onTap: () {
                            // Sauvegarder l'URL n8n
                            final controller = _n8nUrlController;
                            if (controller.text.isNotEmpty) {
                              context.read<AppState>().setN8nUrl(controller.text);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Configuration n8n sauvegardée!'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          }
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
      decoration: const BoxDecoration(
        color: AppColors.dark,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.orange, width: 2),
            ),
            child: const Icon(LucideIcons.user, size: 26, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Yassine Skwilti',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
                const SizedBox(height: 3),
                const Text('yassine@skwilti.ma',
                    style: TextStyle(
                        fontSize: 11, color: Colors.white60)),
                const SizedBox(height: 8),
                Row(children: [
                  SkwBadge(
                    label: '🔥 ${state.streak} jours',
                    bgColor: AppColors.orange,
                    textColor: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  SkwBadge(
                    label: '⚡ ${state.xp} XP',
                    bgColor: Colors.white.withOpacity(0.15),
                    textColor: Colors.white,
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(AppState state) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.2,
      children: [
        _statBox('${(state.avgScore * 100).toInt()}%', 'Score moyen', AppColors.orange),
        _statBox('${state.recentCourses.length}', 'Cours', AppColors.primary),
        _statBox('48', 'Flashcards', AppColors.success),
      ],
    );
  }

  Widget _statBox(String value, String label, Color color) {
    return SkwCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 9, color: AppColors.textSub, height: 1.3)),
        ],
      ),
    );
  }

  Widget _buildMenuSection(String title, List<(IconData, String, Color, Color)> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title: title),
        const SizedBox(height: 10),
        SkwCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: items.asMap().entries.map((e) {
              final item = e.value;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: item.$3,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(item.$1, size: 15, color: item.$4),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(item.$2,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                        const Icon(LucideIcons.chevronRight,
                            size: 14, color: AppColors.textSub),
                      ],
                    ),
                  ),
                  if (e.key < items.length - 1)
                    const Divider(
                        height: 1,
                        thickness: 0.5,
                        color: AppColors.border,
                        indent: 58),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
