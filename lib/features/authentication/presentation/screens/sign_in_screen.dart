import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/auth_service.dart';

typedef AuthSubmission =
    Future<String?> Function(String email, String password);

class SignInScreen extends StatefulWidget {
  const SignInScreen({
    super.key,
    required this.onSignIn,
    required this.onSignUp,
    required this.onContinueAsGuest,
  });

  final AuthSubmission onSignIn;
  final AuthSubmission onSignUp;
  final VoidCallback onContinueAsGuest;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSignUp = false;
  bool _hidePassword = true;
  bool _isLoading = false;
  String? _authMessage;
  String? _authError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _authMessage = null;
      _authError = null;
    });

    try {
      final action = _isSignUp ? widget.onSignUp : widget.onSignIn;
      final message = await action(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;
      setState(() {
        _authMessage = message;
      });
    } on AuthFailure catch (error) {
      if (!mounted) return;
      setState(() {
        _authError = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _authError = 'Authentication failed. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _switchMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _authMessage = null;
      _authError = null;
    });
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Enter your email.';
    if (!email.contains('@')) return 'Enter a valid email address.';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Enter your password.';
    if (value.length < 6) return 'Use at least 6 characters.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.floodBlue,
      body: Stack(
        children: [
          const _DecorativeBackground(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.lg,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - (AppSpacing.md * 2),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: AppSpacing.lg),
                        const _BrandHeader(),
                        const SizedBox(height: AppSpacing.md * 2),
                        _buildFormCard(),
                        const SizedBox(height: AppSpacing.lg),
                        _buildModeSwitch(),
                        const SizedBox(height: AppSpacing.md * 4),
                        Text(
                          'Community flood reports for safer routes.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppColors.surface.withValues(
                                  alpha: 0.65,
                                ),
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surface.withValues(alpha: 0.22)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _FieldLabel('Email'),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              validator: _validateEmail,
              decoration: _fieldDecoration('Enter your email'),
            ),
            const SizedBox(height: AppSpacing.lg),
            const _FieldLabel('Password'),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _passwordController,
              obscureText: _hidePassword,
              autofillHints: [
                _isSignUp ? AutofillHints.newPassword : AutofillHints.password,
              ],
              validator: _validatePassword,
              decoration: _fieldDecoration('Enter your password').copyWith(
                suffixIcon: IconButton(
                  tooltip: _hidePassword ? 'Show password' : 'Hide password',
                  onPressed: () {
                    setState(() {
                      _hidePassword = !_hidePassword;
                    });
                  },
                  icon: Icon(
                    _hidePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.mutedText,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: _isSignUp ? 'Sign Up' : 'Sign In',
              isLoading: _isLoading,
              onPressed: _submit,
            ),
            if (_authMessage != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _authMessage!,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppColors.surface),
              ),
            ],
            if (_authError != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _authError!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.surface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isLoading ? null : widget.onContinueAsGuest,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.surface,
                  backgroundColor: AppColors.surface.withValues(alpha: 0.12),
                  side: BorderSide(
                    color: AppColors.surface.withValues(alpha: 0.35),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  textStyle: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                child: const Text('Continue as Guest'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSwitch() {
    return TextButton(
      onPressed: _switchMode,
      style: TextButton.styleFrom(foregroundColor: AppColors.surface),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _isSignUp ? 'Already have an account? ' : 'Don’t have an account? ',
          ),
          Text(
            _isSignUp ? 'Sign In' : 'Sign Up',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.mutedText),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.all(AppSpacing.md),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.floodBlue, width: 2),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'docs/assets/Sign Up Page Logo.png',
          width: 132,
          height: 112,
          fit: BoxFit.contain,
        ),
        Text(
          'Bahantabay',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.surface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Iwas Baha, Iwas Abala.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.surface,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: AppColors.surface,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _DecorativeBackground extends StatelessWidget {
  const _DecorativeBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              top: 60,
              right: -100,
              child: _circle(360, AppColors.ink.withValues(alpha: 0.12)),
            ),
            Positioned(
              top: 190,
              left: -100,
              child: _circle(230, AppColors.surface.withValues(alpha: 0.05)),
            ),
            Positioned(
              bottom: 50,
              left: -110,
              child: _circle(280, AppColors.ink.withValues(alpha: 0.10)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
