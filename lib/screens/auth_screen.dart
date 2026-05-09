import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import '../models/user.dart';
import '../widgets/skwilti_logo.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _firstCtrl = TextEditingController();
  final _lastCtrl  = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePass = true;
  UserRole _role = UserRole.student;
  String _accountType = 'Freemium';

  late AnimationController _animCtrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose(); _passCtrl.dispose();
    _firstCtrl.dispose(); _lastCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await context.read<AppState>().login(_emailCtrl.text.trim(), _passCtrl.text);
      } else {
        await context.read<AppState>().register(
          email: _emailCtrl.text.trim(), password: _passCtrl.text,
          firstName: _firstCtrl.text.trim(), lastName: _lastCtrl.text.trim(), 
          role: _role, subscription: _accountType == 'Premium' ? SubscriptionType.premium : SubscriptionType.free,
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: FadeTransition(
        opacity: _fade,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(children: [
              const SizedBox(height: 32),
              // ── Logo card (matches screenshot) ──
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4))],
                ),
                child: const SkwiltiLogo(height: 36),
              ),
              const SizedBox(height: 20),
              // Title
              Text('Skwilti', style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary)),
              const SizedBox(height: 4),
              Text(
                _isLogin ? 'Connectez-vous à votre compte' : 'Rejoignez la communauté Skwilti',
                style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),
              // ── Form card ──
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 4))],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (!_isLogin) ...[
                      _Field(ctrl: _emailCtrl, label: 'Email', icon: LucideIcons.mail,
                        type: TextInputType.emailAddress,
                        validator: (v) => v!.isEmpty ? 'Requis' : (!v.contains('@') ? 'Email invalide' : null)),
                      const SizedBox(height: 12),
                      _Field(ctrl: _passCtrl, label: 'Mot de passe', icon: LucideIcons.lock, obscure: _obscurePass,
                        suffix: IconButton(icon: Icon(_obscurePass ? LucideIcons.x : LucideIcons.search, size: 18, color: AppColors.textSub),
                          onPressed: () => setState(() => _obscurePass = !_obscurePass)),
                        validator: (v) => v!.isEmpty ? 'Requis' : (v.length < 6 ? 'Min 6 car.' : null)),
                      const SizedBox(height: 12),
                      _Field(ctrl: _firstCtrl, label: 'Prénom', icon: LucideIcons.user, validator: (v) => v!.isEmpty ? 'Requis' : null),
                      const SizedBox(height: 12),
                      _Field(ctrl: _lastCtrl, label: 'Nom', icon: LucideIcons.user, validator: (v) => v!.isEmpty ? 'Requis' : null),
                      const SizedBox(height: 16),
                      // Role selector (like screenshot)
                      Text('Choisissez votre rôle', style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary)),
                      const SizedBox(height: 10),
                      _roleCard(UserRole.teacher, 'Enseignant', 'Créez des QCM et suivez la progression de vos élèves', LucideIcons.graduationCap, 'assets/images/teacher-illustration.webp'),
                      const SizedBox(height: 8),
                      _roleCard(UserRole.student, 'Étudiant', 'Apprenez et progressez avec des QCM interactifs', LucideIcons.bookOpen, 'assets/images/student-illustration.webp'),
                      const SizedBox(height: 8),
                      _roleCard(UserRole.parent, 'Parent', 'Suivez les résultats et la progression de votre enfant', LucideIcons.heart, 'assets/images/parent-illustration.webp'),
                      const SizedBox(height: 16),
                      // Account type selector
                      Text('Choisissez votre type de compte', style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _accountType = 'Freemium'),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _accountType == 'Freemium' ? AppColors.primaryLight : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _accountType == 'Freemium' ? AppColors.primary : AppColors.border,
                                    width: _accountType == 'Freemium' ? 1.5 : 0.5,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      LucideIcons.gift,
                                      size: 24,
                                      color: _accountType == 'Freemium' ? AppColors.primary : AppColors.textSub,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Freemium',
                                      style: GoogleFonts.nunito(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: _accountType == 'Freemium' ? AppColors.primary : AppColors.text,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Accès limité',
                                      style: GoogleFonts.nunito(
                                        fontSize: 10,
                                        color: _accountType == 'Freemium' ? AppColors.primary : AppColors.textSub,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _accountType = 'Premium'),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _accountType == 'Premium' ? AppColors.primaryLight : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _accountType == 'Premium' ? AppColors.primary : AppColors.border,
                                    width: _accountType == 'Premium' ? 1.5 : 0.5,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      LucideIcons.crown,
                                      size: 24,
                                      color: _accountType == 'Premium' ? AppColors.primary : AppColors.textSub,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Premium',
                                      style: GoogleFonts.nunito(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: _accountType == 'Premium' ? AppColors.primary : AppColors.text,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Accès complet',
                                      style: GoogleFonts.nunito(
                                        fontSize: 10,
                                        color: _accountType == 'Premium' ? AppColors.primary : AppColors.textSub,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      _Field(ctrl: _emailCtrl, label: 'Email', icon: LucideIcons.mail,
                        type: TextInputType.emailAddress,
                        validator: (v) => v!.isEmpty ? 'Requis' : (!v.contains('@') ? 'Email invalide' : null)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Mot de passe', style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSecondary)),
                          GestureDetector(
                            onTap: () {},
                            child: Text('Mot de passe oublié ?', style: GoogleFonts.nunito(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _Field(ctrl: _passCtrl, label: '', icon: LucideIcons.lock, obscure: _obscurePass,
                        suffix: IconButton(icon: Icon(_obscurePass ? LucideIcons.x : LucideIcons.search, size: 18, color: AppColors.textSub),
                          onPressed: () => setState(() => _obscurePass = !_obscurePass)),
                        validator: (v) => v!.isEmpty ? 'Requis' : null),
                      const SizedBox(height: 10),
                      Row(children: [
                        Checkbox(
                          value: false, onChanged: (_) {},
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        Text('Se souvenir de moi', style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSecondary)),
                      ]),
                    ],
                    const SizedBox(height: 20),
                    // CTA button
                    SizedBox(
                      width: double.infinity, height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : Text(_isLogin ? 'Se connecter' : 'S\'inscrire',
                              style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                      ),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              // Toggle
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(_isLogin ? 'Vous n\'avez pas de compte ? ' : 'Déjà un compte ? ',
                  style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSecondary)),
                GestureDetector(
                  onTap: () => setState(() { _isLogin = !_isLogin; _formKey.currentState?.reset(); }),
                  child: Text(_isLogin ? 'S\'inscrire' : 'Se connecter',
                    style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary)),
                ),
              ]),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _roleCard(UserRole role, String title, String desc, IconData icon, String? illustration) {
    final sel = _role == role;
    return GestureDetector(
      onTap: () => setState(() => _role = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: sel ? AppColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: sel ? AppColors.primary : AppColors.border, width: sel ? 1.5 : 0.5),
        ),
        child: Row(children: [
          Container(
            width: 44, 
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0D0), 
              borderRadius: BorderRadius.circular(10),
            ),
            child: illustration != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      illustration!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(icon, size: 22, color: AppColors.primary);
                      },
                    ),
                  )
                : Center(child: Icon(icon, size: 22, color: AppColors.primary)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800, color: sel ? AppColors.primary : AppColors.text)),
            Text(desc, style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textSecondary, height: 1.4)),
          ])),
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: sel ? AppColors.primary : AppColors.border, width: 2),
              color: sel ? AppColors.primary : Colors.white,
            ),
            child: sel ? const Icon(LucideIcons.check, size: 12, color: Colors.white) : null,
          ),
        ]),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final TextInputType? type;
  final bool obscure;
  final Widget? suffix;
  final String? Function(String?)? validator;

  const _Field({required this.ctrl, required this.label, required this.icon,
    this.type, this.obscure = false, this.suffix, this.validator});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl, keyboardType: type, obscureText: obscure,
      style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label.isEmpty ? null : label,
        hintText: label.isEmpty ? '••••••••' : null,
        prefixIcon: Icon(icon, size: 18),
        suffixIcon: suffix,
      ),
      validator: validator,
    );
  }
}

