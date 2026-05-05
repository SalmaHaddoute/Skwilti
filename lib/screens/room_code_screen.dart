import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import '../models/question.dart';
import '../models/qsm_session.dart';
import 'qcm_screen.dart';

class RoomCodeScreen extends StatefulWidget {
  const RoomCodeScreen({super.key});

  @override
  State<RoomCodeScreen> createState() => _RoomCodeScreenState();
}

class _RoomCodeScreenState extends State<RoomCodeScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _joinRoom() async {
    final code = _codeController.text.trim().toUpperCase();
    
    if (code.isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez entrer un code';
      });
      return;
    }

    if (code.length != 6) {
      setState(() {
        _errorMessage = 'Le code doit contenir 6 caractères';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final appState = context.read<AppState>();
      
      // Simuler la vérification du code room
      await Future.delayed(const Duration(seconds: 1));
      
      // Créer une session QSM statique pour le test
      createStaticQsmSession(context);
      
      // Naviguer vers le QSM
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const QcmScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Code invalide ou room expirée';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // Header avec icône
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primary2],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    LucideIcons.doorOpen,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Titre
              Text(
                'Rejoindre une Room',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              // Sous-titre
              Text(
                'Entrez le code à 6 caractères fourni par votre enseignant',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: AppColors.textSub,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              // Champ de saisie du code
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _errorMessage != null 
                        ? AppColors.error 
                        : AppColors.border,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _codeController,
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 6,
                  style: GoogleFonts.nunito(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                    letterSpacing: 8,
                  ),
                  decoration: InputDecoration(
                    hintText: 'ABC123',
                    hintStyle: GoogleFonts.nunito(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSub.withOpacity(0.4),
                      letterSpacing: 8,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    counterText: '',
                    prefixIcon: const Icon(
                      LucideIcons.key,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  onSubmitted: (_) => _joinRoom(),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      LucideIcons.alertCircle,
                      color: AppColors.error,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _errorMessage!,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 32),
              // Bouton rejoindre
              Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primary2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _isLoading ? null : _joinRoom,
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  LucideIcons.arrowRight,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Rejoindre le QSM',
                                  style: GoogleFonts.nunito(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // Info en bas
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.info,
                    size: 14,
                    color: AppColors.textSub.withOpacity(0.6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Le code est fourni par votre enseignant',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: AppColors.textSub.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// Fonction utilitaire pour créer une session QSM statique
void createStaticQsmSession(BuildContext context) {
  final appState = context.read<AppState>();
  
  // Créer des questions statiques pour le QSM
  final questions = [
    Question(
      id: '1',
      question: 'Quelle est la capitale de la France ?',
      options: ['Londres', 'Berlin', 'Paris', 'Madrid'],
      correctIndex: 2,
      explication: 'Paris est la capitale de la France depuis 987.',
    ),
    Question(
      id: '2',
      question: 'Combien font 5 + 3 ?',
      options: ['6', '7', '8', '9'],
      correctIndex: 2,
      explication: '5 + 3 = 8.',
    ),
    Question(
      id: '3',
      question: 'Quel est le plus grand océan du monde ?',
      options: ['Atlantique', 'Indien', 'Arctique', 'Pacifique'],
      correctIndex: 3,
      explication: 'L\'océan Pacifique est le plus grand océan du monde.',
    ),
    Question(
      id: '4',
      question: 'Qui a écrit "Les Misérables" ?',
      options: ['Victor Hugo', 'Émile Zola', 'Marcel Proust', 'Albert Camus'],
      correctIndex: 0,
      explication: 'Victor Hugo a écrit "Les Misérables" en 1862.',
    ),
    Question(
      id: '5',
      question: 'Quelle est la formule chimique de l\'eau ?',
      options: ['CO2', 'H2O', 'O2', 'N2'],
      correctIndex: 1,
      explication: 'La formule chimique de l\'eau est H2O (2 atomes d\'hydrogène, 1 atome d\'oxygène).',
    ),
  ];

  // Créer la session QSM
  final session = QsmSession(
    id: 'static-qsm-${DateTime.now().millisecondsSinceEpoch}',
    courseTitle: 'QSM Général - Test de connaissances',
    questions: questions,
    createdAt: DateTime.now(),
    userAnswers: List.filled(questions.length, null),
    timerMinutes: 30,
    allowBackNavigation: true,
    showResultsImmediately: false,
  );

  // Définir la session dans l'état de l'application
  appState.setCurrentSession(session);
}
