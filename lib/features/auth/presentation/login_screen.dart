import 'package:flutter/material.dart';

import '../../../core/state/auth_state.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../core/theme/typography_tokens.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    required this.authState,
    required this.onRegisterTap,
    super.key,
  });

  final AuthState authState;
  final VoidCallback onRegisterTap;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    await widget.authState.login(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorTokens.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.xxl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Column(
                      children: [
                        SizedBox(
                          height: 100,
                          width: 100,
                          child: Image.asset(
                            'assets/teams/universitatea_cluj.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: SpacingTokens.sm),
                        Text(
                          'U CLUJ',
                          style: TypographyTokens.headline.copyWith(
                            color: ColorTokens.accent,
                            letterSpacing: 4,
                            fontSize: 28,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.sm),
                  Text(
                    'PLATFORMĂ DE INTELLIGENCE TACTICĂ',
                    textAlign: TextAlign.center,
                    style: TypographyTokens.sectionLabel,
                  ),
                  const SizedBox(height: 48),
                  Text('AUTENTIFICARE', style: TypographyTokens.sectionLabel),
                  const SizedBox(height: SpacingTokens.md),
                  _buildField(_emailCtrl, 'EMAIL', false),
                  const SizedBox(height: SpacingTokens.md),
                  _buildField(_passCtrl, 'PAROLĂ', true),
                  const SizedBox(height: SpacingTokens.xl),
                  if (widget.authState.error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(SpacingTokens.sm),
                      color: ColorTokens.negative.withValues(alpha: 0.15),
                      child: Text(
                        widget.authState.error!,
                        style: TypographyTokens.body.copyWith(
                          color: ColorTokens.negative,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: SpacingTokens.md),
                  ],
                  SizedBox(
                    height: 48,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: ColorTokens.accent,
                        foregroundColor: ColorTokens.onAccent,
                        shape: const RoundedRectangleBorder(),
                      ),
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: ColorTokens.onAccent,
                              ),
                            )
                          : Text(
                              'INTRĂ',
                              style: TypographyTokens.sectionLabel
                                  .copyWith(color: ColorTokens.onAccent),
                            ),
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'NU AI CONT? ',
                        style: TypographyTokens.sectionLabel,
                      ),
                      GestureDetector(
                        onTap: widget.onRegisterTap,
                        child: Text(
                          'ÎNREGISTREAZĂ-TE',
                          style: TypographyTokens.sectionLabel.copyWith(
                            color: ColorTokens.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    bool obscure,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TypographyTokens.sectionLabel),
        const SizedBox(height: SpacingTokens.xs),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: TypographyTokens.body,
          cursorColor: ColorTokens.accent,
          decoration: InputDecoration(
            filled: true,
            fillColor: ColorTokens.surfaceLow,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: SpacingTokens.md,
              vertical: SpacingTokens.sm,
            ),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: ColorTokens.divider),
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: ColorTokens.divider),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: ColorTokens.accent),
            ),
          ),
        ),
      ],
    );
  }
}
