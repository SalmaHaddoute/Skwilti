import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import '../services/n8n_service.dart';
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
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez d\'abord sélectionner un fichier'),
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
      
      // APRÈS — vrai appel n8n
      final n8nUrl = context.read<AppState>().n8nUrl;
      final service = N8nService();
      final data = await service.generateQcm(
        file: _selectedFile!,
        nbQuestions: _nbQuestions,
        difficulty: _difficulty,
        language: 'Français',
        webhookUrl: n8nUrl,
        onProgress: (progress) {
          setState(() {
            _progress = progress;
            _progressStep = 'Envoi du fichier... ${(_progress * 100).toInt()}%';
          });
        },
      );

      final questions = (data['questions'] as List)
          .map((q) => Question.fromJson(q as Map<String, dynamic>))
          .toList();

      if (mounted) {
        context.read<AppState>().setQuestions(
          questions,
          title: _fileName?.replaceAll(RegExp(r'\.[^.]+$'), '') ?? 'Mon cours',
          summary: data['resume']?.toString() ?? '',
          keywords: List<String>.from(data['mots_cles'] ?? []),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReviewScreen()),
        );
      }
    } catch (e) {
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          if (_isGenerating)
            _buildLoadingCard()
          else ...[
            _buildUploadHero(),
            const SizedBox(height: 14),
            if (_selectedFile != null) ...[
              _buildFilePreview(),
              const SizedBox(height: 14),
            ],
            _buildConfigCard(),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: SkwBtn(
                label: 'Générer le QCM',
                icon: LucideIcons.sparkles,
                onTap: _generate,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUploadHero() {
    return GestureDetector(
      onTap: _pickFile,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.orange, AppColors.orange2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.22),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(LucideIcons.upload,
                  size: 26, color: Colors.white),
            ),
            const SizedBox(height: 10),
            const Text('Importer votre cours',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
            const SizedBox(height: 4),
            const Text(
              'Appuyez pour sélectionner depuis votre appareil',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: ['PDF', 'WORD', 'IMAGE', 'TXT'].map((type) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(type,
                      style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.orangeDark)),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePreview() {
    return SkwCard(
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(LucideIcons.fileText,
                size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fileName ?? '',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text),
                  overflow: TextOverflow.ellipsis,
                ),
                const Text('Prêt à analyser',
                    style:
                        TextStyle(fontSize: 10, color: AppColors.success)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() {
              _selectedFile = null;
              _fileName = null;
            }),
            child: const Icon(LucideIcons.x,
                size: 16, color: AppColors.textSub),
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
            child: const Icon(LucideIcons.sparkles,
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
}
