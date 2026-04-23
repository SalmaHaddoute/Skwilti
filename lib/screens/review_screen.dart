import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import '../models/question.dart';
import '../widgets/common_widgets.dart';
import 'qcm_screen.dart';

class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final questions = state.questions;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Réviser les questions'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.orangeLight,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                  color: AppColors.orange.withOpacity(0.2), width: 0.5),
            ),
            child: Text(
              '${questions.length} question${questions.length > 1 ? 's' : ''}',
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.orangeDark),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(14),
              children: [
                // Summary card
                if (state.courseSummary.isNotEmpty) ...[
                  _buildSummaryCard(state),
                  const SizedBox(height: 12),
                ],
                // Hint
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppColors.orangeLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border(
                        left: BorderSide(
                            color: AppColors.orange, width: 3)),
                  ),
                  child: Row(
                    children: const [
                      Icon(LucideIcons.trash2,
                          size: 14, color: AppColors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Supprimez les questions indésirables avant de lancer le QCM',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.orangeDark),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Questions
                if (questions.isEmpty)
                  _buildEmptyState()
                else
                  ...questions.asMap().entries.map(
                        (e) => _QuestionCard(
                          question: e.value,
                          index: e.key,
                          onDelete: () =>
                              context.read<AppState>().deleteQuestion(e.value.id),
                        ),
                      ),
              ],
            ),
          ),
          // Bottom actions
          if (questions.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
              decoration: const BoxDecoration(
                color: AppColors.card,
                border: Border(
                    top: BorderSide(color: AppColors.border, width: 0.5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SkwBtn(
                      label: 'Exporter',
                      icon: LucideIcons.download,
                      outlined: true,
                      onTap: () => _showExportSheet(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SkwBtn(
                      label: 'Lancer le QCM',
                      icon: LucideIcons.arrowRight,
                      onTap: () {
                        context.read<AppState>().startSession();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const QcmScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(AppState state) {
    return SkwCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(LucideIcons.fileText,
                size: 15, color: AppColors.primary),
            const SizedBox(width: 7),
            const Text('Résumé du cours',
                style:
                    TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 8),
          Text(state.courseSummary,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSub,
                  height: 1.6)),
          if (state.keywords.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: state.keywords
                  .map((k) => SkwBadge(
                        label: k,
                        bgColor: AppColors.primaryLight,
                        textColor: AppColors.primary,
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(LucideIcons.inbox, size: 40, color: AppColors.textSub),
            SizedBox(height: 12),
            Text('Toutes les questions ont été supprimées',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSub)),
          ],
        ),
      ),
    );
  }

  void _showExportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _ExportSheet(),
    );
  }
}

// ─── Question Card with Dismissible ──────────────────────
class _QuestionCard extends StatefulWidget {
  final Question question;
  final int index;
  final VoidCallback onDelete;

  const _QuestionCard({
    required this.question,
    required this.index,
    required this.onDelete,
  });

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(widget.question.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => widget.onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.errorLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(LucideIcons.trash2,
            color: AppColors.error, size: 22),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 11, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.orangeLight,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        'Q${widget.index + 1}',
                        style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.orangeDark),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(children: const [
                        Icon(LucideIcons.sparkles,
                            size: 9, color: AppColors.primary),
                        SizedBox(width: 3),
                        Text('IA',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary)),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 7),
                  Text(widget.question.question,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                          height: 1.5)),
                  const SizedBox(height: 8),
                  // Options
                  ...widget.question.options.asMap().entries.map((opt) {
                    final isCorrect =
                        opt.key == widget.question.correctIndex;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: isCorrect
                              ? AppColors.successLight
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isCorrect
                                ? AppColors.success
                                : AppColors.border,
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          '${String.fromCharCode(65 + opt.key)}. ${opt.value}${isCorrect ? ' ✓' : ''}',
                          style: TextStyle(
                              fontSize: 10,
                              color: isCorrect
                                  ? AppColors.success
                                  : AppColors.textSub,
                              fontWeight: isCorrect
                                  ? FontWeight.w700
                                  : FontWeight.w400),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              decoration: const BoxDecoration(
                color: Color(0xFFFAFAF9),
                border:
                    Border(top: BorderSide(color: AppColors.border, width: 0.5)),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(14)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _expanded = !_expanded),
                      child: Row(children: [
                        const Icon(LucideIcons.info,
                            size: 12, color: AppColors.textSub),
                        const SizedBox(width: 4),
                        Text(
                          _expanded ? 'Masquer' : 'Explication',
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.textSub),
                        ),
                      ]),
                    ),
                  ),
                  _footBtn(
                    LucideIcons.pencil,
                    'Modifier',
                    AppColors.orangeLight,
                    AppColors.orangeDark,
                    () {},
                  ),
                  const SizedBox(width: 6),
                  _footBtn(
                    LucideIcons.trash2,
                    'Supprimer',
                    AppColors.errorLight,
                    AppColors.error,
                    widget.onDelete,
                  ),
                ],
              ),
            ),
            if (_expanded)
              Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  widget.question.explication,
                  style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.primary,
                      height: 1.5),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _footBtn(IconData icon, String label, Color bg, Color fg,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(99)),
        child: Row(children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
        ]),
      ),
    );
  }
}

// ─── Export Bottom Sheet ──────────────────────────────────
class _ExportSheet extends StatelessWidget {
  const _ExportSheet();

  @override
  Widget build(BuildContext context) {
    final options = [
      (LucideIcons.fileText, 'Fichier PDF', 'QCM imprimable avec corrections',
          const Color(0xFFE8F0FE)),
      (LucideIcons.table, 'Excel / CSV', 'Questions + réponses en tableau',
          const Color(0xFFE6F4EA)),
      (LucideIcons.layers, 'Flashcards', 'Format Anki partageable',
          AppColors.primaryLight),
      (LucideIcons.share2, 'Partager le lien',
          'QCM interactif en ligne via Skwilti', const Color(0xFFFEF3E2)),
      (LucideIcons.upload, 'Sauvegarder dans ma bibliothèque',
          'Accès depuis tous vos appareils', AppColors.primaryLight),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Exporter',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          ...options.map((o) => _ExportTile(
              icon: o.$1, title: o.$2, subtitle: o.$3, iconBg: o.$4)),
        ],
      ),
    );
  }
}

class _ExportTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconBg;

  const _ExportTile(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.iconBg});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border, width: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration:
                BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700)),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textSub)),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight,
              size: 14, color: AppColors.textSub),
        ],
      ),
    );
  }
}
