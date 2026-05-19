import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import '../models/classroom.dart';
import '../widgets/common_widgets.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _timerController = TextEditingController(text: '20');
  final _maxParticipantsController = TextEditingController(text: '50');
  
  Classroom? _selectedClassroom;
  bool _isLoading = false;
  bool _allowAnonymous = false;
  int? _timerMinutes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadAllClassrooms();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _timerController.dispose();
    _maxParticipantsController.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    print('🟣 [UI] _createRoom button pressed');
    if (!_formKey.currentState!.validate() || _selectedClassroom == null) {
      if (_selectedClassroom == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez sélectionner une classe'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get current QCM session from AppState
      final currentSession = context.read<AppState>().currentSession;
      if (currentSession == null) {
        throw Exception('Aucun QCM disponible. Veuillez d\'abord créer un QCM.');
      }

      await context.read<AppState>().createRoom(
        name: _nameController.text.trim(),
        classroomId: _selectedClassroom!.id,
        schoolClassId: _selectedClassroom!.classeScolaireId,
        qcmSessionId: currentSession.id,
        timerMinutes: _timerMinutes,
        maxParticipants: int.tryParse(_maxParticipantsController.text) ?? 50,
        allowAnonymous: _allowAnonymous,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Room créée avec succès!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final currentSession = state.currentSession;
    print('DEBUG: [CreateRoomScreen] build - currentSession: ${currentSession?.id}');
    final classrooms = state.allClassrooms;
    final quizzes = state.teacherCourses.where((c) => (c['question_count'] ?? 0) > 0).toList();

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
          'Créer une room',
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Current QCM info
              if (currentSession != null)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.fileText, color: AppColors.primary, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            'QCM sélectionné',
                            style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                currentSession.courseTitle,
                                style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
                              child: Text(
                                '${currentSession.questions.length} questions',
                                style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              if (currentSession == null) ...[
                if (quizzes.isNotEmpty) ...[
                  Text(
                    'Sélectionnez un QSM existant',
                    style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text),
                  ),
                  const SizedBox(height: 14),
                  ...quizzes.map((quiz) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(LucideIcons.fileText, color: AppColors.primary, size: 20),
                      ),
                      title: Text(
                        quiz['title'] ?? 'QSM sans titre',
                        style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text),
                      ),
                      subtitle: Text(
                        '${quiz['subject'] ?? 'Général'} · ${quiz['question_count']} questions',
                        style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textSub, fontWeight: FontWeight.w600),
                      ),
                      trailing: const Icon(LucideIcons.chevronRight, color: AppColors.textSub, size: 18),
                      onTap: () async {
                        await context.read<AppState>().loadQcmForCourse(
                          quiz['id'] as String,
                          quiz['title'] as String? ?? 'Sans titre',
                        );
                      },
                    ),
                  )),
                ] else
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 56, height: 56,
                          decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1), shape: BoxShape.circle),
                          child: const Icon(LucideIcons.alertTriangle, color: AppColors.warning, size: 28),
                        ),
                        const SizedBox(height: 16),
                        Text('Aucun QCM disponible', style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text)),
                        const SizedBox(height: 8),
                        Text('Créez d\'abord un QCM depuis l\'écran de création avant de lancer une Room.', textAlign: TextAlign.center, style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSub)),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: Text('Retour', style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 24),

              // Room info
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.tag, color: AppColors.primary, size: 20),
                        const SizedBox(width: 10),
                        Text('Informations de la room', style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text),
                      decoration: InputDecoration(
                        labelText: 'Nom de la room *',
                        labelStyle: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSub, fontWeight: FontWeight.w600),
                        hintText: 'Ex: QCM Mathématiques - Test 1',
                        hintStyle: GoogleFonts.nunito(fontSize: 14, color: AppColors.textSub.withOpacity(0.6)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                        filled: true,
                        fillColor: AppColors.background.withOpacity(0.5),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Veuillez entrer le nom de la room' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Classroom selection
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.users, color: AppColors.success, size: 20),
                        const SizedBox(width: 10),
                        Text('Classe concernée', style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (!state.allClassroomsLoaded)
                      const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                    else if (classrooms.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        alignment: Alignment.center,
                        child: Text('Aucune classe disponible', style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textSub)),
                      )
                    else
                      ...classrooms.map((classroom) {
                        final isSelected = _selectedClassroom?.id == classroom.id;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.success.withOpacity(0.08) : AppColors.background.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSelected ? AppColors.success : AppColors.border, width: isSelected ? 1.5 : 1),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: isSelected ? AppColors.success : AppColors.textSub.withOpacity(0.1), shape: BoxShape.circle),
                              child: Icon(LucideIcons.bookOpen, color: isSelected ? Colors.white : AppColors.textSub, size: 18),
                            ),
                            title: Text(classroom.name, style: GoogleFonts.nunito(fontSize: 15, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700, color: isSelected ? AppColors.success : AppColors.text)),
                            subtitle: classroom.description != null ? Text(classroom.description!, style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textSub)) : null,
                            trailing: isSelected ? const Icon(LucideIcons.checkCircle, color: AppColors.success, size: 22) : null,
                            onTap: () => setState(() => _selectedClassroom = classroom),
                          ),
                        );
                      }),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Settings
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.settings, color: AppColors.primary, size: 20),
                        const SizedBox(width: 10),
                        Text('Paramètres', style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Timer
                    TextFormField(
                      controller: _timerController,
                      style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text),
                      decoration: InputDecoration(
                        labelText: 'Timer (minutes, 0 = illimité)',
                        labelStyle: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSub, fontWeight: FontWeight.w600),
                        prefixIcon: const Icon(LucideIcons.timer, color: AppColors.primary, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                        filled: true,
                        fillColor: AppColors.background.withOpacity(0.5),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final timer = int.tryParse(value);
                        setState(() => _timerMinutes = timer != null && timer > 0 ? timer : null);
                      },
                    ),
                    const SizedBox(height: 14),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          {'label': '15 min', 'value': 15},
                          {'label': '30 min', 'value': 30},
                          {'label': '45 min', 'value': 45},
                          {'label': '1 heure', 'value': 60},
                          {'label': 'Illimité', 'value': 0},
                        ].map((d) {
                          final isSelected = _timerMinutes == d['value'];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(
                                d['label'] as String,
                                style: GoogleFonts.nunito(fontSize: 12, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, color: isSelected ? Colors.white : AppColors.textSub),
                              ),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() {
                                  _timerMinutes = d['value'] as int > 0 ? d['value'] as int : null;
                                  _timerController.text = d['value'].toString();
                                });
                              },
                              selectedColor: AppColors.primary,
                              backgroundColor: AppColors.background,
                              showCheckmark: false,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border)),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Max participants
                    TextFormField(
                      controller: _maxParticipantsController,
                      style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text),
                      decoration: InputDecoration(
                        labelText: 'Nombre maximum d\'élèves',
                        labelStyle: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSub, fontWeight: FontWeight.w600),
                        prefixIcon: const Icon(LucideIcons.users, color: AppColors.primary, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                        filled: true,
                        fillColor: AppColors.background.withOpacity(0.5),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    
                    // Allow anonymous
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(color: AppColors.background.withOpacity(0.5), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.userCheck, color: AppColors.primary, size: 20),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Accès anonyme autorisé', style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
                                const SizedBox(height: 2),
                                Text('Permet aux participants sans compte Skwilti de rejoindre', style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textSub)),
                              ],
                            ),
                          ),
                          Switch(
                            value: _allowAnonymous,
                            onChanged: (value) => setState(() => _allowAnonymous = value),
                            activeColor: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Submit button
              ElevatedButton.icon(
                onPressed: (_isLoading || currentSession == null) ? null : _createRoom,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: AppColors.primary.withOpacity(0.4),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(LucideIcons.play, size: 20),
                label: Text(
                  currentSession == null ? 'Créez d\'abord un QCM' : 'Lancer la Room maintenant',
                  style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
