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

  Map<String, dynamic>? _roomData;
 
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
 
     setState(() {
       _isLoading = true;
       _errorMessage = null;
     });
 
     try {
       final appState = context.read<AppState>();
       final room = await appState.joinRoomByCode(code);
       
       if (room == null) {
         setState(() {
           _errorMessage = 'Code invalide ou room expirée';
           _isLoading = false;
         });
         return;
       }
 
       setState(() {
         _roomData = room;
         _isLoading = false;
       });
     } catch (e) {
       if (mounted) {
         setState(() {
           final errStr = e.toString();
           if (errStr.contains('déjà complété')) {
             _errorMessage = errStr.replaceAll('Exception: ', '');
           } else {
             _errorMessage = 'Erreur lors de la connexion à la room';
           }
           _isLoading = false;
         });
       }
     }
   }
 
   void _startQsm() {
     Navigator.pushReplacement(
       context,
       MaterialPageRoute(builder: (_) => const QcmScreen()),
     );
   }
 
   @override
   Widget build(BuildContext context) {
     return Scaffold(
       backgroundColor: AppColors.background,
       body: SafeArea(
         child: SingleChildScrollView(
           padding: const EdgeInsets.all(24),
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.stretch,
             children: [
               const SizedBox(height: 20),
               // Back Button if previewing
               if (_roomData != null)
                 Align(
                   alignment: Alignment.centerLeft,
                   child: IconButton(
                     icon: const Icon(LucideIcons.arrowLeft),
                     onPressed: () => setState(() => _roomData = null),
                   ),
                 ),
               
               if (_roomData == null) ...[
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
                       contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                       counterText: '',
                     ),
                     onSubmitted: (_) => _joinRoom(),
                   ),
                 ),
                 if (_errorMessage != null) ...[
                   const SizedBox(height: 12),
                   Text(
                     _errorMessage!,
                     textAlign: TextAlign.center,
                     style: GoogleFonts.nunito(color: AppColors.error, fontWeight: FontWeight.w600),
                   ),
                 ],
                 const SizedBox(height: 32),
                 _buildButton(
                   label: 'Rejoindre le QSM',
                   icon: LucideIcons.arrowRight,
                   onTap: _isLoading ? null : _joinRoom,
                   isLoading: _isLoading,
                 ),
               ] else ...[
                 // PREVIEW ROOM DATA
                 const SizedBox(height: 10),
                 Center(
                   child: Container(
                     padding: const EdgeInsets.all(16),
                     decoration: BoxDecoration(
                       color: AppColors.success.withOpacity(0.1),
                       shape: BoxShape.circle,
                     ),
                     child: const Icon(LucideIcons.checkCircle, color: AppColors.success, size: 48),
                   ),
                 ),
                 const SizedBox(height: 16),
                 Center(
                   child: Text(
                     'Room Trouvée !',
                     style: GoogleFonts.nunito(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.text),
                   ),
                 ),
                 const SizedBox(height: 8),
                 Center(
                   child: Text(
                     'Préparez-vous à relever le défi',
                     style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textSub),
                   ),
                 ),
                 const SizedBox(height: 32),
                 Container(
                   decoration: BoxDecoration(
                     color: Colors.white,
                     borderRadius: BorderRadius.circular(28),
                     boxShadow: [
                       BoxShadow(
                         color: AppColors.primary.withOpacity(0.08),
                         blurRadius: 24,
                         offset: const Offset(0, 12),
                       ),
                     ],
                     border: Border.all(color: AppColors.primary.withOpacity(0.1), width: 1),
                   ),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.stretch,
                     children: [
                       Container(
                         padding: const EdgeInsets.all(24),
                         decoration: BoxDecoration(
                           gradient: LinearGradient(
                             colors: [AppColors.primary.withOpacity(0.05), Colors.transparent],
                             begin: Alignment.topCenter,
                             end: Alignment.bottomCenter,
                           ),
                           borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                         ),
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.center,
                           children: [
                             Text(
                               _roomData!['name'] ?? 'Nom de la Room',
                               textAlign: TextAlign.center,
                               style: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.primary),
                             ),
                             const SizedBox(height: 8),
                             Container(
                               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                               decoration: BoxDecoration(
                                 color: AppColors.primary.withOpacity(0.1),
                                 borderRadius: BorderRadius.circular(20),
                               ),
                               child: Text(
                                 _roomData!['quiz_sessions']?['title'] ?? 'QSM Sans Titre',
                                 style: GoogleFonts.nunito(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w800),
                               ),
                             ),
                           ],
                         ),
                       ),
                       Padding(
                         padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                         child: Column(
                           children: [
                             _DetailRow(
                               icon: LucideIcons.clock,
                               label: 'Durée',
                               value: '${_roomData!['timer_minutes'] ?? 0} minutes',
                             ),
                             const SizedBox(height: 20),
                             _DetailRow(
                               icon: LucideIcons.helpCircle,
                               label: 'Questions',
                               value: '${(_roomData!['questions'] as List?)?.length ?? 0} questions',
                             ),
                             const SizedBox(height: 20),
                             _DetailRow(
                               icon: LucideIcons.users,
                               label: 'Mode',
                               value: _roomData!['allow_anonymous'] == true ? 'Ouvert à tous' : 'Réservé à la classe',
                             ),
                           ],
                         ),
                       ),
                     ],
                   ),
                 ),
                 const SizedBox(height: 40),
                 _buildButton(
                   label: 'Commencer le QSM',
                   icon: LucideIcons.play,
                   onTap: _startQsm,
                   color: AppColors.success,
                 ),
               ],
             ],
           ),
         ),
       ),
     );
   }
 
   Widget _buildButton({
     required String label,
     required IconData icon,
     required VoidCallback? onTap,
     bool isLoading = false,
     Color? color,
   }) {
     return Container(
       height: 56,
       decoration: BoxDecoration(
         color: color ?? AppColors.primary,
         gradient: color == null ? LinearGradient(
           colors: [AppColors.primary, AppColors.primary2],
           begin: Alignment.topLeft,
           end: Alignment.bottomRight,
         ) : null,
         borderRadius: BorderRadius.circular(16),
         boxShadow: [
           BoxShadow(
             color: (color ?? AppColors.primary).withOpacity(0.3),
             blurRadius: 12,
             offset: const Offset(0, 4),
           ),
         ],
       ),
       child: Material(
         color: Colors.transparent,
         child: InkWell(
           borderRadius: BorderRadius.circular(16),
           onTap: onTap,
           child: Center(
             child: isLoading
                 ? const CircularProgressIndicator(color: Colors.white)
                 : Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       Icon(icon, color: Colors.white, size: 20),
                       const SizedBox(width: 10),
                       Text(
                         label,
                         style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                       ),
                     ],
                   ),
           ),
         ),
       ),
     );
   }
 }
 
 class _DetailRow extends StatelessWidget {
   final IconData icon;
   final String label;
   final String value;
 
   const _DetailRow({required this.icon, required this.label, required this.value});
 
   @override
   Widget build(BuildContext context) {
     return Row(
       children: [
         Container(
           padding: const EdgeInsets.all(8),
           decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
           child: Icon(icon, size: 18, color: AppColors.textSub),
         ),
         const SizedBox(width: 16),
         Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Text(label, style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textSub)),
             Text(value, style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
           ],
         ),
       ],
     );
   }
 }
