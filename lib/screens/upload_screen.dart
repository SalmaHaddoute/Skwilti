import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import '../services/webhook_service.dart';
import '../models/question.dart';
import '../widgets/common_widgets.dart';
import 'review_screen.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  String? _selectedCourseId;
  String? _selectedCourseTitle;
  int _nbQuestions = 10;
  String _difficulty = 'moyen';
  bool _isGenerating = false;
  double _progress = 0.0;
  String _progressStep = '';
  

  final List<String> _difficulties = ['facile', 'moyen', 'difficile'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<AppState>();
      if (!state.teacherCoursesLoaded) {
        state.loadTeacherCourses();
      }
    });
  }

  Future<void> _generate() async {
    if (_selectedCourseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un cours existant'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _progress = 0.0;
      _progressStep = 'Envoi du fichier...';
    });

    try {
      await _simulateSteps();
      
      // APRÈS — Appel du webhook avec WebhookService
      final result = await WebhookService().processPdfUpload(
        title: _selectedCourseTitle ?? 'Mon cours',
        teacherId: context.read<AppState>().currentUser?.id ?? '',
        nombreQuestions: _nbQuestions,
        difficulte: _difficulty,
        langue: 'Français',
        existingFile: null,
        existingCourseId: _selectedCourseId,
      );
      
      if (result != null && result['success'] == true) {
        if (mounted) {
          context.read<AppState>().loadTeacherCourses();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ QCM généré avec succès!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: ${result?['error']}'),
            backgroundColor: AppColors.error,
          ),
        );
      }

      // DEBUG: Afficher les données reçues
      if (result != null) {
        print('=== DONNÉES REÇUES DU WEBHOOK ===');
        print('Type: ${result.runtimeType}');
        print('Keys: ${result.keys}');
        print('Success: ${result['success']}');
        if (result['success'] == true) {
          final dynamic rawResponse = result['response'];
          final dynamic normalizedResponse = _normalizeWebhookResponse(rawResponse);

          List<Question> questions = _extractQuestionsFromResponse(normalizedResponse);
          final String summary = _extractSummaryFromResponse(normalizedResponse);
          final List<String> keywords = _extractKeywordsFromResponse(normalizedResponse);

          if (questions.isEmpty) {
            print('ℹ️ Aucune question valide trouvée dans la réponse webhook. Récupération depuis Supabase...');
            final String? returnedCourseId = result['course_id'];
            if (returnedCourseId != null) {
              // Polling: n8n is generating questions asynchronously. We wait until they appear in Supabase.
              for (int i = 0; i < 15; i++) {
                if (mounted) {
                  setState(() {
                    _progressStep = 'Génération par l\'IA en cours... (${(i + 1) * 4}s)';
                  });
                }
                await Future.delayed(const Duration(seconds: 4));
                questions = await WebhookService().fetchQuestionsForCourse(returnedCourseId);
                if (questions.isNotEmpty) {
                  print('🟢 ${questions.length} questions trouvées après polling !');
                  break;
                }
                print('⏳ Polling... aucune question trouvée (tentative ${i + 1}/15)');
              }
            }
          }

          print('=== QUESTIONS RÉCUPÉRÉES ===');
          print('Nombre: ${questions.length}');
          print('Normalized response: $normalizedResponse');
          print('=============================');

          if (mounted) {
            context.read<AppState>().setQuestions(
              questions,
              title: _selectedCourseTitle ?? 'Mon cours',
              summary: summary,
              keywords: keywords,
              courseId: _selectedCourseId,
            );

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ReviewScreen(),
              ),
            );
          }
        } else {
          print('❌ Erreur webhook: ${result['error']}');
        }
      }
    } catch (e, stack) {
      print('=== ERREUR CAPTURÉE ===');
      print('Type: ${e.runtimeType}');
      print('Message: $e');
      print('Stack trace: $stack');
      print('====================');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _simulateSteps() async {
    final steps = [
      ('Lecture du document...', 0.2),
      ('Extraction du texte...', 0.4),
      ('Analyse par l\'IA...', 0.65),
      ('Génération des questions...', 0.85),
      ('Vérification finale...', 1.0),
    ];
    for (final step in steps) {
      if (!mounted) return;
      setState(() {
        _progressStep = step.$1;
        _progress = step.$2;
      });
      await Future.delayed(const Duration(milliseconds: 600));
    }
  }

  Widget _buildExistingCoursesSection(AppState state) {
    final courses = state.teacherCourses;
    if (courses.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text('Choisir un cours existant', style: GoogleFonts.nunito(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.text)),
        const SizedBox(height: 10),
        if (_selectedCourseId != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.success.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.checkCircle, color: AppColors.success, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Cours sélectionné : ${_selectedCourseTitle ?? 'Cours existant'}',
                    style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.success),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _selectedCourseId = null;
                    _selectedCourseTitle = null;
                  }),
                  child: const Text('Annuler'),
                ),
              ],
            ),
          ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2))],
          ),
          child: Column(
            children: courses.map((course) {
              final id = course['id']?.toString();
              final isSelected = id != null && id == _selectedCourseId;
              return InkWell(
                onTap: () {
                  if (id == null) return;
                  setState(() {
                    _selectedCourseId = id;
                    _selectedCourseTitle = course['title']?.toString();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
                    color: isSelected ? AppColors.primary.withOpacity(0.08) : Colors.white,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(course['title']?.toString() ?? 'Sans titre', style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
                            const SizedBox(height: 4),
                            Text(
                              '${course['subject'] ?? 'Général'} · ${course['question_count'] ?? 0} questions',
                              style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textSub),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isSelected ? LucideIcons.checkCircle : LucideIcons.circle,
                        color: isSelected ? AppColors.primary : AppColors.textSub,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  dynamic _normalizeWebhookResponse(dynamic input) {
    if (input == null) return null;
    if (input is String) {
      final trimmed = input.trim();
      if (trimmed.isEmpty) return null;
      try {
        return _normalizeWebhookResponse(jsonDecode(trimmed));
      } catch (_) {
        return trimmed;
      }
    }
    if (input is List) {
      return input.map(_normalizeWebhookResponse).toList();
    }
    if (input is Map) {
      final normalized = <String, dynamic>{};
      for (final entry in input.entries) {
        normalized[entry.key] = _normalizeWebhookResponse(entry.value);
      }
      return normalized;
    }
    return input;
  }

  List<Question> _extractQuestionsFromResponse(dynamic response) {
    if (response == null) return [];

    if (response is List) {
      // If the list is already a list of question maps
      final directQuestions = response
          .whereType<Map>()
          .where((item) => item.containsKey('question') || item.containsKey('text') || item.containsKey('options'))
          .map((item) => Question.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      if (directQuestions.isNotEmpty) return directQuestions;

      // If the list contains a single container map with questions
      if (response.length == 1 && response.first is Map) {
        return _extractQuestionsFromResponse(response.first);
      }

      // Try flattening nested lists
      for (final element in response) {
        final nested = _extractQuestionsFromResponse(element);
        if (nested.isNotEmpty) return nested;
      }
      return [];
    }

    if (response is Map) {
      if (response.containsKey('questions')) {
        return _extractQuestionsFromResponse(response['questions']);
      }

      if (response.containsKey('data')) {
        return _extractQuestionsFromResponse(response['data']);
      }

      if (response.containsKey('output')) {
        return _extractQuestionsFromResponse(response['output']);
      }

      if (response.containsKey('result')) {
        return _extractQuestionsFromResponse(response['result']);
      }

      if (response.containsKey('body')) {
        return _extractQuestionsFromResponse(response['body']);
      }

      if (response.containsKey('question') || response.containsKey('text') || response.containsKey('options')) {
        return [Question.fromJson(Map<String, dynamic>.from(response))];
      }

      for (final value in response.values) {
        final nested = _extractQuestionsFromResponse(value);
        if (nested.isNotEmpty) return nested;
      }
      return [];
    }

    return [];
  }

  String _extractSummaryFromResponse(dynamic response) {
    if (response is Map) {
      final summaryKeys = ['resume', 'résumé', 'summary', 'description'];
      for (final key in summaryKeys) {
        if (response.containsKey(key) && response[key] != null) {
          return response[key].toString();
        }
      }
      for (final value in response.values) {
        final nested = _extractSummaryFromResponse(value);
        if (nested.isNotEmpty) return nested;
      }
    }
    if (response is List) {
      for (final item in response) {
        final nested = _extractSummaryFromResponse(item);
        if (nested.isNotEmpty) return nested;
      }
    }
    return '';
  }

  List<String> _extractKeywordsFromResponse(dynamic response) {
    if (response is Map) {
      final keywordKeys = ['keywords', 'mots_cles', 'mots_clés', 'tags'];
      for (final key in keywordKeys) {
        if (response.containsKey(key) && response[key] != null) {
          final value = response[key];
          if (value is List) return value.map((e) => e.toString()).toList();
          if (value is String) return value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        }
      }
      for (final value in response.values) {
        final nested = _extractKeywordsFromResponse(value);
        if (nested.isNotEmpty) return nested;
      }
    }
    if (response is List) {
      for (final item in response) {
        final nested = _extractKeywordsFromResponse(item);
        if (nested.isNotEmpty) return nested;
      }
    }
    return [];
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
          'Créer un QCM',
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isGenerating)
              _buildLoadingCard()
            else ...[
            _buildExistingCoursesSection(context.watch<AppState>()),
            const SizedBox(height: 20),
            _buildConfigCard(),
            const SizedBox(height: 30),
            _buildGenerateButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateButton() {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: _generate,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                LucideIcons.zap,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Générer le QCM',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildConfigCard() {
    return SkwCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [
            Icon(LucideIcons.settings, size: 15, color: AppColors.orange),
            SizedBox(width: 7),
            Text('Options de génération',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 12),
          _cfgRow(
            icon: LucideIcons.layers,
            iconBg: AppColors.orangeLight,
            iconColor: AppColors.orange,
            label: 'Nombre de questions',
            trailing: Row(
              children: [
                _ctrBtn('-', () {
                  if (_nbQuestions > 3)
                    setState(() => _nbQuestions--);
                }),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text('$_nbQuestions',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800)),
                ),
                _ctrBtn('+', () {
                  if (_nbQuestions < 30)
                    setState(() => _nbQuestions++);
                }),
              ],
            ),
          ),
          const Divider(
              height: 16, thickness: 0.5, color: AppColors.border),
          _cfgRow(
            icon: LucideIcons.barChart2,
            iconBg: AppColors.primaryLight,
            iconColor: AppColors.primary,
            label: 'Difficulté',
            trailing: Row(
              children: _difficulties.map((d) {
                final isOn = d == _difficulty;
                return GestureDetector(
                  onTap: () => setState(() => _difficulty = d),
                  child: Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: isOn ? AppColors.orange : AppColors.border,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      d[0].toUpperCase() + d.substring(1),
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: isOn ? Colors.white : AppColors.textSub),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(
              height: 16, thickness: 0.5, color: AppColors.border),
          _cfgRow(
            icon: LucideIcons.globe,
            iconBg: AppColors.orangeLight,
            iconColor: AppColors.orange,
            label: 'Langue du QCM',
            trailing: const Text('Français',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.orange)),
          ),
        ],
      ),
    );
  }

  Widget _cfgRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required Widget trailing,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(7)),
            child: Icon(icon, size: 13, color: iconColor),
          ),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSub)),
        ]),
        trailing,
      ],
    );
  }

  Widget _ctrBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: AppColors.orangeLight,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Center(
          child: Text(label,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.orange)),
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    final steps = [
      'Envoi du fichier...',
      'Lecture du document...',
      'Extraction du texte...',
      'Analyse par l\'IA...',
      'Génération des questions...',
    ];
    return SkwCard(
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(LucideIcons.zap,
                size: 26, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          Text(_selectedCourseTitle ?? 'Cours',
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(_progressStep,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSub)),
          const SizedBox(height: 16),
          ...steps.asMap().entries.map((e) {
            final stepPct = (e.key + 1) / steps.length;
            final isDone = _progress >= stepPct;
            final isActive =
                !isDone && _progress >= stepPct - 0.21;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppColors.successLight
                        : isActive
                            ? AppColors.primaryLight
                            : AppColors.border,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isDone ? LucideIcons.check : LucideIcons.clock,
                    size: 11,
                    color: isDone
                        ? AppColors.success
                        : isActive
                            ? AppColors.primary
                            : AppColors.textSub,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(steps[e.key],
                      style: TextStyle(
                          fontSize: 11,
                          color: isDone
                              ? AppColors.text
                              : isActive
                                  ? AppColors.primary
                                  : AppColors.textSub)),
                ),
              ]),
            );
          }),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 6,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Text('${(_progress * 100).toInt()}%',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary)),
        ],
      ),
    );
  }



}
