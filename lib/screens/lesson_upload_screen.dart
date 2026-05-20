import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/common_widgets.dart';

class LessonUploadScreen extends StatefulWidget {
  final String filiere;
  final String subject;
  final String semester;
  final Map<String, dynamic>? courseToEdit;
  
  const LessonUploadScreen({
    super.key,
    required this.filiere,
    required this.subject,
    required this.semester,
    this.courseToEdit,
  });

  @override
  State<LessonUploadScreen> createState() => _LessonUploadScreenState();
}

class _LessonUploadScreenState extends State<LessonUploadScreen> {
  File? _selectedFile;
  String? _fileName;
  String _lessonTitle = '';
  String _lessonDescription = '';
  bool _isUploading = false;
  double _progress = 0.0;
  String _progressStep = '';
  late String _selectedSemester;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (['Semestre 1', 'Semestre 2'].contains(widget.semester)) {
      _selectedSemester = widget.semester;
    } else {
      _selectedSemester = 'Semestre 1';
    }

    if (widget.courseToEdit != null) {
      _lessonTitle = widget.courseToEdit!['title'] as String? ?? '';
      _titleController.text = _lessonTitle;

      _lessonDescription = widget.courseToEdit!['description'] as String? ?? '';
      _descController.text = _lessonDescription;

      _fileName = widget.courseToEdit!['file_name'] as String? ?? widget.courseToEdit!['fileName'] as String? ?? 'Fichier_existant.pdf';
    }
  }

  final List<String> _supportedFormats = [
    'PDF', 'DOC', 'DOCX', 'PPT', 'PPTX', 'TXT', 'JPG', 'JPEG', 'PNG'
  ];

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'txt', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.isNotEmpty) {
      final path = result.files.first.path;
      if (path != null) {
        setState(() {
          _selectedFile = File(path);
          _fileName = result.files.first.name;
          // Auto-generate title from filename if empty
          if (_lessonTitle.isEmpty) {
            _lessonTitle = _fileName!.replaceAll(RegExp(r'\.[^.]+$'), '');
          }
        });
      }
    }
  }

  Future<void> _uploadFileAndCreateDocument(String courseId, File file, String fileName) async {
    final supabase = Supabase.instance.client;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath = 'uploads/${timestamp}_$fileName';
    
    // 1. Upload to storage
    await supabase.storage
        .from('courses')
        .upload(storagePath, file);
        
    // 2. Get public URL
    final fileUrl = supabase.storage
        .from('courses')
        .getPublicUrl(storagePath);
        
    // 3. Create document entry
    final teacherId = supabase.auth.currentUser?.id;
    await supabase.from('documents').insert({
      'user_id': teacherId,
      'file_url': fileUrl,
      'course_id': courseId,
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _uploadLesson() async {
    final isEdit = widget.courseToEdit != null;
    if (!isEdit && _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez d\'abord sélectionner un fichier'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_lessonTitle.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer un titre pour la leçon'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _progress = 0.0;
      _progressStep = isEdit ? 'Enregistrement des modifications...' : 'Préparation de l\'upload...';
    });

    try {
      await _simulateUploadSteps();
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        String courseId;
        if (isEdit) {
          courseId = widget.courseToEdit!['id'].toString();
          final descPrefix = 'Semestre: $_selectedSemester';
          final fullDesc = _lessonDescription.startsWith('Semestre:') 
              ? _lessonDescription 
              : '$descPrefix${_lessonDescription.isNotEmpty ? '\n$_lessonDescription' : ''}';
              
          await context.read<AppState>().updateCourse(courseId, {
            'title': _lessonTitle,
            'description': fullDesc,
            'subject': widget.subject,
            if (_fileName != null) 'file_name': _fileName,
          });
        } else {
          courseId = await context.read<AppState>().uploadCourse({
            'title': _lessonTitle,
            'description': 'Filière: ${widget.filiere} | Semestre: $_selectedSemester${_lessonDescription.isNotEmpty ? '\n$_lessonDescription' : ''}',
            'subject': widget.subject,
            'file_name': _fileName,
          });
        }

        // Si un fichier physique a été sélectionné, on l'téléverse réellement
        if (_selectedFile != null && _fileName != null) {
          setState(() {
            _progressStep = 'Téléversement du fichier PDF réel...';
          });
          await _uploadFileAndCreateDocument(courseId, _selectedFile!, _fileName!);
        }

        if (mounted) {
          await context.read<AppState>().loadTeacherCourses();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEdit ? 'Leçon modifiée avec succès!' : 'Leçon uploadée avec succès!'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'upload: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _simulateUploadSteps() async {
    final steps = [
      ('Validation du fichier...', 0.2),
      ('Compression...', 0.4),
      ('Upload vers le serveur...', 0.6),
      ('Traitement...', 0.8),
      ('Finalisation...', 1.0),
    ];
    
    for (final step in steps) {
      if (!mounted) return;
      setState(() {
        _progressStep = step.$1;
        _progress = step.$2;
      });
      await Future.delayed(const Duration(milliseconds: 800));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.courseToEdit != null ? 'Modifier la leçon' : 'Uploader une leçon',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isUploading ? null : _uploadLesson,
            child: Text(
              widget.courseToEdit != null ? 'Enregistrer' : 'Uploader',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _isUploading ? AppColors.textSub : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Context Info ───────────────────────────────────────
            _buildContextCard(),
            const SizedBox(height: 20),

            // ─── File Upload Area ───────────────────────────────────
            if (!_isUploading) ...[
              _buildFileUploadArea(),
              const SizedBox(height: 20),
            ],

            // ─── Lesson Details ─────────────────────────────────────
            if (!_isUploading) ...[
              _buildLessonDetails(),
              const SizedBox(height: 20),
            ],

            // ─── Loading State ───────────────────────────────────────
            if (_isUploading) ...[
              _buildLoadingCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContextCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.bookOpen, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Destination',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSub,
                      ),
                    ),
                    Text(
                      '${widget.filiere} → ${widget.subject}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.semester,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileUploadArea() {
    return GestureDetector(
      onTap: _pickFile,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: _selectedFile != null 
              ? AppColors.success.withOpacity(0.05)
              : AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedFile != null 
                ? AppColors.success 
                : AppColors.primary,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Icon(
              _selectedFile != null ? LucideIcons.checkCircle : LucideIcons.uploadCloud,
              size: 48,
              color: _selectedFile != null ? AppColors.success : AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              _selectedFile != null ? 'Fichier sélectionné' : 'Glissez-déposez ou cliquez pour uploader',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _selectedFile != null ? AppColors.success : AppColors.primary,
              ),
            ),
            if (_selectedFile != null) ...[
              const SizedBox(height: 8),
              Text(
                _fileName!,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.text,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ] else ...[
              const SizedBox(height: 8),
              Text(
                'Formats supportés: ${_supportedFormats.join(', ')}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSub,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLessonDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Détails de la leçon',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 12),
        SkwCard(
          child: Column(
            children: [
              // Title field
              TextField(
                controller: _titleController,
                onChanged: (value) => setState(() => _lessonTitle = value),
                decoration: InputDecoration(
                  labelText: 'Titre de la leçon',
                  hintText: 'Ex: Introduction à l\'algèbre',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  labelStyle: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSub,
                  ),
                  hintStyle: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSub,
                  ),
                ),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 16),
              
              // Description field
              TextField(
                controller: _descController,
                onChanged: (value) => setState(() => _lessonDescription = value),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description (optionnel)',
                  hintText: 'Décrivez brièvement le contenu de cette leçon...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  labelStyle: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSub,
                  ),
                  hintStyle: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSub,
                  ),
                ),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 16),
              
              // Semester field
              DropdownButtonFormField<String>(
                value: _selectedSemester,
                items: ['Semestre 1', 'Semestre 2'].map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(s),
                )).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedSemester = value);
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Semestre',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  labelStyle: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSub,
                  ),
                ),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingCard() {
    final steps = [
      'Préparation...',
      'Upload...',
      'Traitement...',
      'Finalisation...',
    ];
    
    return SkwCard(
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              LucideIcons.uploadCloud,
              size: 32,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Upload en cours...',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _progressStep,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSub,
            ),
          ),
          const SizedBox(height: 20),
          
          // Progress steps
          ...steps.asMap().entries.map((e) {
            final stepPct = (e.key + 1) / steps.length;
            final isDone = _progress >= stepPct;
            final isActive = !isDone && _progress >= stepPct - 0.25;
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isDone 
                          ? AppColors.success.withOpacity(0.1)
                          : isActive 
                              ? AppColors.primary.withOpacity(0.1)
                              : AppColors.border,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isDone ? LucideIcons.check : LucideIcons.clock,
                      size: 12,
                      color: isDone 
                          ? AppColors.success
                          : isActive 
                              ? AppColors.primary
                              : AppColors.textSub,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      steps[e.key],
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDone 
                            ? AppColors.text
                            : isActive 
                                ? AppColors.primary
                                : AppColors.textSub,
                        fontWeight: isDone || isActive ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          
          const SizedBox(height: 20),
          
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 8,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(_progress * 100).toInt()}%',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
