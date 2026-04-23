import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import '../widgets/common_widgets.dart';
import 'results_screen.dart';

class QcmScreen extends StatefulWidget {
  const QcmScreen({super.key});

  @override
  State<QcmScreen> createState() => _QcmScreenState();
}

class _QcmScreenState extends State<QcmScreen> {
  int _currentIndex = 0;
  int? _selectedAnswer;
  bool _answered = false;
  Timer? _timer;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _timerLabel {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _selectAnswer(int index) {
    if (_answered) return;
    setState(() {
      _selectedAnswer = index;
      _answered = true;
    });
    context.read<AppState>().answerQuestion(_currentIndex, index);
  }

  void _next() {
    final session = context.read<AppState>().currentSession!;
    if (_currentIndex < session.totalQuestions - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = session.userAnswers[_currentIndex];
        _answered = session.userAnswers[_currentIndex] != null;
      });
    } else {
      _finish();
    }
  }

  void _prev() {
    if (_currentIndex > 0) {
      final session = context.read<AppState>().currentSession!;
      setState(() {
        _currentIndex--;
        _selectedAnswer = session.userAnswers[_currentIndex];
        _answered = session.userAnswers[_currentIndex] != null;
      });
    }
  }

  void _finish() {
    _timer?.cancel();
    context.read<AppState>().completeSession();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ResultsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppState>().currentSession;
    if (session == null) return const SizedBox.shrink();

    final question = session.questions[_currentIndex];
    final progress = (_currentIndex + 1) / session.totalQuestions;
    final isLast = _currentIndex == session.totalQuestions - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          _buildHeader(progress, session.totalQuestions),
          // Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question.question,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                        height: 1.6),
                  ),
                  const SizedBox(height: 20),
                  ...question.options.asMap().entries.map(
                        (e) => _buildOption(
                          e.key,
                          e.value,
                          question.correctIndex,
                        ),
                      ),
                  if (_answered && question.explication.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildExplanation(question.explication),
                  ],
                ],
              ),
            ),
          ),
          // Navigation
          _buildNavBar(isLast),
        ],
      ),
    );
  }

  Widget _buildHeader(double progress, int total) {
    return Container(
      color: AppColors.dark,
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 10, 16, 14),
      child: Column(
        children: [
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: Colors.white.withOpacity(0.15),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.orange),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${_currentIndex + 1} / $total',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.75)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.timer,
                        size: 12, color: Colors.white),
                    const SizedBox(width: 5),
                    Text(_timerLabel,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOption(int index, String text, int correctIndex) {
    Color borderColor = AppColors.border;
    Color bgColor = AppColors.card;
    Color textColor = AppColors.text;
    Color letterBg = AppColors.border;
    Color letterFg = AppColors.textSub;

    if (_answered) {
      if (index == correctIndex) {
        borderColor = AppColors.success;
        bgColor = AppColors.successLight;
        textColor = AppColors.success;
        letterBg = AppColors.success;
        letterFg = Colors.white;
      } else if (index == _selectedAnswer && index != correctIndex) {
        borderColor = AppColors.error;
        bgColor = AppColors.errorLight;
        textColor = AppColors.error;
        letterBg = AppColors.error;
        letterFg = Colors.white;
      }
    } else if (_selectedAnswer == index) {
      borderColor = AppColors.orange;
      bgColor = AppColors.orangeLight;
      textColor = AppColors.orangeDark;
      letterBg = AppColors.orange;
      letterFg = Colors.white;
    }

    return GestureDetector(
      onTap: () => _selectAnswer(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                  color: letterBg, borderRadius: BorderRadius.circular(7)),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + index),
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: letterFg),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: textColor)),
            ),
            if (_answered && index == correctIndex)
              const Icon(LucideIcons.checkCircle2,
                  size: 16, color: AppColors.success),
            if (_answered &&
                index == _selectedAnswer &&
                index != correctIndex)
              const Icon(LucideIcons.x, size: 16, color: AppColors.error),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanation(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: AppColors.primary, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.lightbulb, size: 15, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.primary, height: 1.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildNavBar(bool isLast) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          if (_currentIndex > 0)
            SizedBox(
              width: 52,
              child: OutlinedButton(
                onPressed: _prev,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Icon(LucideIcons.arrowLeft, size: 16),
              ),
            ),
          if (_currentIndex > 0) const SizedBox(width: 10),
          Expanded(
            child: SkwBtn(
              label: isLast ? 'Terminer' : 'Valider',
              icon: isLast ? LucideIcons.trophy : LucideIcons.arrowRight,
              onTap: _answered ? _next : null,
            ),
          ),
        ],
      ),
    );
  }
}
