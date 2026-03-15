import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/problem.dart';
import '../providers/app_provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'feed_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  // Step 1 = sign in, Step 2 = pick role
  int _step = 1;
  UserRole? _selectedRole;
  bool _loading = false;
  AuthResult? _authResult;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  final _roles = [
    (
      role: UserRole.student,
      emoji: '🎓',
      title: 'Student',
      sub: 'Preparing for my first job',
    ),
    (
      role: UserRole.professional,
      emoji: '👨‍💻',
      title: 'Professional',
      sub: "Already employed, ready to level up",
    ),
    (
      role: UserRole.competitive,
      emoji: '⚔️',
      title: 'Competitive',
      sub: 'I eat Leetcode for breakfast',
    ),
  ];

  Future<void> _handleGoogleSignIn() async {
    setState(() => _loading = true);
    try {
      final result = await AuthService.signInWithGoogle();
      if (result == null) {
        setState(() => _loading = false);
        return;
      }
      _authResult = result;
      setState(() {
        _loading = false;
        _step = 2;
      });
      _fadeController.forward(from: 0);
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign-in failed: $e',
                style: AppTheme.mono(size: 12, color: AppTheme.black)),
            backgroundColor: AppTheme.red,
          ),
        );
      }
    }
  }

  Future<void> _proceed() async {
    if (_selectedRole == null || _loading || _authResult == null) return;
    setState(() => _loading = true);

    try {
      await context.read<AppProvider>().initUser(
            email: _authResult!.email,
            name: _authResult!.name,
            role: _selectedRole!,
          );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const FeedScreen(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e',
                style: AppTheme.mono(size: 12, color: AppTheme.black)),
            backgroundColor: AppTheme.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _step == 1 ? _buildSignIn() : _buildRolePicker(),
          ),
        ),
      ),
    );
  }

  Widget _buildSignIn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Text('⚠ USE RESPONSIBLY',
            style: AppTheme.mono(size: 11, color: AppTheme.red)),
        const SizedBox(height: 24),
        Text('cheatcode()',
            style: AppTheme.mono(
                size: 22, color: AppTheme.green, weight: FontWeight.bold)),
        const SizedBox(height: 16),
        Text(
          'Technical interviews are\na pattern recognition game.\n\nWe reverse engineered\nthe patterns.',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                height: 1.2,
                letterSpacing: -0.5,
              ),
        ),
        const Spacer(),
        Text('// 30 days · 10 minutes · unfair advantage',
            style: AppTheme.mono(
                size: 11, color: AppTheme.white.withOpacity(0.35))),
        const SizedBox(height: 24),

        // Google Sign-In button
        GestureDetector(
          onTap: _loading ? null : _handleGoogleSignIn,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(2),
            ),
            child: _loading
                ? const Center(
                    child: SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          color: AppTheme.black, strokeWidth: 2),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('G',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700)),
                      const SizedBox(width: 10),
                      Text(
                        'Continue with Google',
                        style: AppTheme.mono(
                            size: 13,
                            color: AppTheme.black,
                            weight: FontWeight.bold),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'By continuing you agree to our Terms of Service\nand Privacy Policy.',
          textAlign: TextAlign.center,
          style: AppTheme.mono(
              size: 10, color: AppTheme.white.withOpacity(0.2)),
        ),
      ],
    );
  }

  Widget _buildRolePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        if (_authResult != null) ...[
          Text('Hey, ${_authResult!.name.split(' ').first} 👋',
              style: AppTheme.mono(
                  size: 14,
                  color: AppTheme.green,
                  weight: FontWeight.bold)),
          const SizedBox(height: 8),
        ],
        Text(
          'One quick\nquestion.',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w900,
                height: 1.1,
                letterSpacing: -0.5,
              ),
        ),
        const SizedBox(height: 48),
        Text('// who are you?',
            style: AppTheme.mono(
                size: 12, color: AppTheme.white.withOpacity(0.4))),
        const SizedBox(height: 16),
        ...(_roles.map((r) => _RoleCard(
              emoji: r.emoji,
              title: r.title,
              sub: r.sub,
              selected: _selectedRole == r.role,
              onTap: () => setState(() => _selectedRole = r.role),
            ))),
        const Spacer(),
        AnimatedOpacity(
          opacity: _selectedRole != null ? 1.0 : 0.3,
          duration: const Duration(milliseconds: 300),
          child: GestureDetector(
            onTap: _proceed,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              color: AppTheme.green,
              child: Center(
                child: _loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            color: AppTheme.black, strokeWidth: 2),
                      )
                    : Text("LET'S GO →",
                        style: AppTheme.mono(
                            size: 13,
                            color: AppTheme.black,
                            weight: FontWeight.bold)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String sub;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.emoji,
    required this.title,
    required this.sub,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              selected ? AppTheme.green.withOpacity(0.08) : AppTheme.dim,
          border: Border.all(
            color: selected ? AppTheme.green : AppTheme.mid,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style:
                        Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: selected
                                  ? AppTheme.green
                                  : AppTheme.white,
                            ),
                  ),
                  const SizedBox(height: 2),
                  Text(sub,
                      style: AppTheme.mono(
                          size: 11,
                          color: AppTheme.white.withOpacity(0.4))),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check, color: AppTheme.green, size: 18),
          ],
        ),
      ),
    );
  }
}
