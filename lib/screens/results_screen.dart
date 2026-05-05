import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import '../widgets/common_widgets.dart';
import '../models/question.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppState>().currentSession!;
    final score = session.scorePercent;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHero(context, session, score),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsRow(session),
                  const SizedBox(height: 20),
                  const SectionTitle(title: 'Corrections détaillées'),
                  const SizedBox(height: 12),
                  ...session.questions.asMap().entries.map((e) =>
                      _buildCorrectionCard(
                          e.value, session.userAnswers[e.key], e.key)),
                  const SizedBox(height: 20),
                  Row(children: [
                    Expanded(
                      child: SkwBtn(
                        label: 'Rejouer',
                        icon: LucideIcons.repeat,
                        outlined: true,
                        onTap: () {
                          context.read<AppState>().startSession();
                          Navigator.pushReplacementNamed(context, '/qcm');
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SkwBtn(
                        label: 'Exporter',
                        icon: LucideIcons.download,
                        onTap: () => _showExportSheet(context),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(LucideIcons.home, size: 16),
                      label: const Text('Retour à l\'accueil'),
                      onPressed: () {
                        context.read<AppState>().reset();
                        Navigator.popUntil(context, (r) => r.isFirst);
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context, QcmSession session, double score) {
    final icon = score >= 80
        ? LucideIcons.trophy
        : score >= 60
            ? LucideIcons.star
            : LucideIcons.target;
    final msg = score >= 80
        ? 'Excellent travail !'
        : score >= 60
            ? 'Bien joué !'
            : 'Continue tes efforts !';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.dark, AppColors.primary, AppColors.orange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
          18, MediaQuery.of(context).padding.top + 12, 18, 24),
      child: Column(
        children: [
          // Score ring
          SizedBox(
            width: 90,
            height: 90,
            child: Stack(
              children: [
                SizedBox(
                  width: 90,
                  height: 90,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 7,
                    backgroundColor: Colors.white.withOpacity(0.15),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.warning),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${score.toInt()}%',
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1)),
                      const Text('Score',
                          style: TextStyle(
                              fontSize: 9, color: Colors.white60)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(msg,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
            ],
          ),
          const SizedBox(height: 4),
          Text(session.courseTitle,
              style:
                  const TextStyle(fontSize: 11, color: Colors.white60)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _heroPill(
                  '${session.correctAnswers} / ${session.totalQuestions}',
                  AppColors.warning),
              const SizedBox(width: 8),
              _heroPill(
                  _formatDuration(session.completedAt!
                      .difference(session.createdAt)),
                  Colors.white.withOpacity(0.18)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroPill(String label, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white)),
    );
  }

  Widget _buildStatsRow(QcmSession session) {
    return Row(children: [
      _statBox('${session.correctAnswers}', 'Correctes', AppColors.primary),
      const SizedBox(width: 8),
      _statBox(
          '${session.totalQuestions - session.correctAnswers}',
          'Fausses',
          AppColors.warning),
      const SizedBox(width: 8),
      _statBox('+85', 'XP gagnés', AppColors.primary),
    ]);
  }

  Widget _statBox(String value, String label, Color color) {
    return Expanded(
      child: SkwCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 9, color: AppColors.textSub, height: 1.3)),
          ],
        ),
      ),
    );
  }

  Widget _buildCorrectionCard(
      Question question, int? userAnswer, int index) {
    final isCorrect = userAnswer == question.correctIndex;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCorrect ? AppColors.successLight : AppColors.errorLight,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: isCorrect ? AppColors.success : AppColors.error,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(
              isCorrect ? LucideIcons.checkCircle : LucideIcons.x,
              size: 13,
              color: isCorrect ? AppColors.success : AppColors.error,
            ),
            const SizedBox(width: 5),
            Text(
              'Q.${index + 1} — ${isCorrect ? 'Correct ✓' : 'Incorrect ✗'}',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isCorrect ? AppColors.success : AppColors.error),
            ),
          ]),
          const SizedBox(height: 5),
          Text(
            question.question,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.text),
          ),
          const SizedBox(height: 6),
          if (!isCorrect && userAnswer != null)
            _answerLine('Votre réponse',
                question.options[userAnswer], AppColors.error),
          _answerLine('Bonne réponse',
              question.options[question.correctIndex], AppColors.success),
          if (question.explication.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(question.explication,
                style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSub,
                    fontStyle: FontStyle.italic,
                    height: 1.4)),
          ],
        ],
      ),
    );
  }

  Widget _answerLine(String prefix, String answer, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 10),
          children: [
            TextSpan(
                text: '$prefix : ',
                style: const TextStyle(color: AppColors.textSub)),
            TextSpan(
                text: answer,
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m} min ${s.toString().padLeft(2, '0')} s';
  }

  void _showExportSheet(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export en cours de développement…'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}
