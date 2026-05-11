import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import 'admin_add_student.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AdminStudentsListScreen extends StatefulWidget {
  final String classeId;
  final String classeNom;

  const AdminStudentsListScreen({
    super.key,
    required this.classeId,
    required this.classeNom,
  });

  @override
  State<AdminStudentsListScreen> createState() => _AdminStudentsListScreenState();
}

class _AdminStudentsListScreenState extends State<AdminStudentsListScreen> {
  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    await context.read<AppState>().loadAdminUsers();
  }

  Future<void> _addStudent() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminAddStudentScreen(
          classeId: widget.classeId,
          classeNom: widget.classeNom,
        ),
      ),
    );
    if (mounted) {
      _loadStudents();
    }
  }

  Future<void> _exportToPDF() async {
    final users = context.read<AppState>().adminUsers;
    final students = users.where((u) => u['role'] == 'student' && u['classe_id']?.toString() == widget.classeId).toList();

    if (students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun étudiant à exporter'), backgroundColor: AppColors.error),
      );
      return;
    }

    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    'Skwilti - Liste des Étudiants',
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text(
                    widget.classeNom,
                    style: pw.TextStyle(fontSize: 18, color: PdfColors.grey700),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.TableHelper.fromTextArray(
                  context: context,
                  data: <List<String>>[
                    <String>['N°', 'Code Massar', 'Prénom', 'Nom', 'Email', 'Téléphone', 'CIN', 'Date naiss.'],
                    ...students.asMap().entries.map((entry) {
                      final i = entry.key;
                      final student = entry.value;
                      return <String>[
                        '${i + 1}',
                        student['code_massar']?.toString() ?? '',
                        student['first_name']?.toString() ?? '',
                        student['last_name']?.toString() ?? '',
                        student['email']?.toString() ?? '',
                        student['telephone']?.toString() ?? '',
                        student['cin']?.toString() ?? '',
                        student['date_naissance']?.toString() ?? '',
                      ];
                    }),
                  ],
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.purple),
                  cellHeight: 30,
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.centerLeft,
                    2: pw.Alignment.centerLeft,
                    3: pw.Alignment.centerLeft,
                    4: pw.Alignment.centerLeft,
                    5: pw.Alignment.centerLeft,
                    6: pw.Alignment.centerLeft,
                    7: pw.Alignment.centerLeft,
                  },
                ),
                pw.SizedBox(height: 20),
                pw.Align(
                  alignment: pw.Alignment.bottomRight,
                  child: pw.Text(
                    'Généré le ${DateTime.now().toString().split('.')[0]}',
                    style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 10),
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Sauvegarder et partager le PDF
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'etudiants_${widget.classeId}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF généré et partagé avec succès'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'export: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final users = context.watch<AppState>().adminUsers;
    final students = users.where((u) => u['role'] == 'student' && u['classe_id']?.toString() == widget.classeId).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Étudiants',
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
          IconButton(
            icon: const Icon(LucideIcons.download, color: AppColors.primary),
            onPressed: _exportToPDF,
          ),
          IconButton(
            icon: const Icon(LucideIcons.plus, color: AppColors.primary),
            onPressed: _addStudent,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.classeNom,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${students.length} étudiant(s)',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSub,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: students.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.users, size: 64, color: AppColors.textSub.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun étudiant',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: AppColors.textSub,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Appuyez sur + pour ajouter un étudiant',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textSub.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final student = students[index];
                      return _StudentCard(student: student);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addStudent,
        backgroundColor: AppColors.primary,
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final Map<String, dynamic> student;

  const _StudentCard({required this.student});

  @override
  Widget build(BuildContext context) {
    final prenom = student['first_name']?.toString() ?? '';
    final nom = student['last_name']?.toString() ?? '';
    final codeMassar = student['code_massar']?.toString() ?? '';
    final email = student['email']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(LucideIcons.user, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$prenom $nom',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                if (codeMassar.isNotEmpty)
                  Text(
                    'Code Massar: $codeMassar',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSub,
                    ),
                  ),
                if (email.isNotEmpty)
                  Text(
                    email,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSub,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
