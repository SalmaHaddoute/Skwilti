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
  File? _selectedFile;
  String? _fileName;
  int _nbQuestions = 10;
  String _difficulty = 'moyen';
  bool _isGenerating = false;
  double _progress = 0.0;
  String _progressStep = '';
  
  // Variables pour la génération par prompt
  final TextEditingController _promptController = TextEditingController();
  bool _usePromptMode = false;

  final List<String> _difficulties = ['facile', 'moyen', 'difficile'];

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.isNotEmpty) {
      final path = result.files.first.path;
      if (path != null) {
        setState(() {
          _selectedFile = File(path);
          _fileName = result.files.first.name;
        });
      }
    }
  }

  Future<void> _generate() async {
    if (_usePromptMode) {
      if (_promptController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez entrer un prompt pour générer le QCM'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    } else {
      if (_selectedFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez d\'abord sélectionner un fichier'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
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
        title: _fileName?.replaceAll(RegExp(r'\.[^.]+$'), '') ?? 'Mon cours',
        teacherId: context.read<AppState>().currentUser?.id ?? '',
        nombreQuestions: _nbQuestions,
        difficulte: _difficulty,
        langue: 'Français',
        existingFile: _selectedFile,
      );
      
      if (result != null && result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ QCM généré avec succès!'),
            backgroundColor: AppColors.success,
          ),
        );
        
        // Naviguer vers le cours créé
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ReviewScreen(),
          ),
        );
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
          final responseData = result['response'];
          print('Questions: ${responseData['questions']}');
          print('Resume: ${responseData['resume']}');
          print('Mots clés: ${responseData['mots_cles']}');
          print('=============================');

          final questions = (responseData['questions'] as List?)
              ?.map((q) => Question.fromJson(q as Map<String, dynamic>))
              .toList() ?? [];

          print('=== QUESTIONS CONVERTIES ===');
          print('Nombre de questions: ${questions.length}');
          for (int i = 0; i < questions.length; i++) {
            print('Q${i+1}: ${questions[i].question}');
            print('Options: ${questions[i].options}');
            print('Correct: ${questions[i].correctIndex}');
          }
          print('=============================');

          if (mounted) {
            context.read<AppState>().setQuestions(
              questions,
              title: _fileName?.replaceAll(RegExp(r'\.[^.]+$'), '') ?? 'Mon cours',
              summary: responseData['resume']?.toString() ?? '',
              keywords: List<String>.from(responseData['mots_cles'] ?? []),
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
    } catch (e) {
      print('=== ERREUR CAPTURÉE ===');
      print('Type: ${e.runtimeType}');
      print('Message: $e');
      print('Stack trace: ${StackTrace.current}');
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
              _buildModeSelector(),
              const SizedBox(height: 20),
              if (_usePromptMode) ...[
                _buildPromptSection(),
                const SizedBox(height: 20),
              ] else ...[
                _buildUploadHero(),
                const SizedBox(height: 20),
                if (_selectedFile != null) ...[
                  _buildFilePreview(),
                  const SizedBox(height: 20),
                ],
              ],
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

  Widget _buildUploadHero() {
    return GestureDetector(
      onTap: _pickFile,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary),
        ),
        child: Column(
          children: [
            Icon(
              LucideIcons.upload,
              size: 48,
              color: Colors.white,
            ),
            const SizedBox(height: 12),
            Text(
              'Importer votre cours',
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'PDF, Word, Image, TXT',
              style: GoogleFonts.nunito(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              LucideIcons.fileText,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fileName ?? '',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Prêt à analyser',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() {
              _selectedFile = null;
              _fileName = null;
            }),
            child: Icon(
              LucideIcons.x,
              size: 20,
              color: AppColors.textSub,
            ),
          ),
        ],
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
          Text(_fileName ?? 'Document',
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

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mode de génération',
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _usePromptMode = false),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: !_usePromptMode ? AppColors.primary : AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: !_usePromptMode ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.fileText,
                          size: 20,
                          color: !_usePromptMode ? Colors.white : AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Fichier',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: !_usePromptMode ? Colors.white : AppColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _usePromptMode = true),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _usePromptMode ? AppColors.primary : AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _usePromptMode ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.edit3,
                          size: 20,
                          color: _usePromptMode ? Colors.white : AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Prompt',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _usePromptMode ? Colors.white : AppColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPromptSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Décrire le contenu',
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Soyez précis pour de meilleurs résultats',
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: AppColors.textSub,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: _promptController,
              maxLines: 4,
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: AppColors.text,
              ),
              decoration: InputDecoration(
                hintText: 'Ex: 10 questions sur la révolution française...',
                hintStyle: GoogleFonts.nunito(
                  fontSize: 12,
                  color: AppColors.textSub,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              'Histoire', 'Sciences', 'Maths', 'Littérature'
            ].map((subject) {
              return GestureDetector(
                onTap: () {
                  _promptController.text = 'Créez des questions sur $subject';
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    subject,
                    style: GoogleFonts.nunito(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          ],
        ),
    );
  }
}
