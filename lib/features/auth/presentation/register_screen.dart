import 'package:flutter/material.dart';

import '../../../core/services/api_client.dart';
import '../../../core/state/auth_state.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../core/theme/typography_tokens.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    required this.authState,
    required this.onLoginTap,
    super.key,
  });

  final AuthState authState;
  final VoidCallback onLoginTap;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  List<String> _teams = [];
  String? _selectedTeam;
  bool _loadingTeams = true;
  bool _submitting = false;
  String? _localError;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    try {
      final teams = await widget.authState.authService.fetchTeams();
      if (mounted) {
        setState(() {
          _teams = teams;
          _loadingTeams = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _localError = 'Could not load teams: ${e.message}';
          _loadingTeams = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;

    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final confirm = _confirmCtrl.text;

    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      setState(() => _localError = 'All fields are required');
      return;
    }
    if (pass.length < 8) {
      setState(() => _localError = 'Password must be at least 8 characters');
      return;
    }
    if (pass != confirm) {
      setState(() => _localError = 'Passwords do not match');
      return;
    }
    if (_selectedTeam == null) {
      setState(() => _localError = 'Please select a team');
      return;
    }

    setState(() {
      _submitting = true;
      _localError = null;
    });

    final success = await widget.authState.register(
      email: email,
      password: pass,
      fullName: name,
      teamName: _selectedTeam!,
    );

    if (mounted) {
      setState(() {
        _submitting = false;
        if (!success) _localError = widget.authState.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayError = _localError ?? widget.authState.error;

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
                    child: SizedBox(
                      height: 120,
                      child: Image.asset(
                        'assets/branding/logo_full.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.md),
                  Text(
                    'CREATE YOUR ACCOUNT',
                    textAlign: TextAlign.center,
                    style: TypographyTokens.sectionLabel,
                  ),
                  const SizedBox(height: 48),
                  _buildField(_nameCtrl, 'FULL NAME', false),
                  const SizedBox(height: SpacingTokens.md),
                  _buildField(_emailCtrl, 'EMAIL', false),
                  const SizedBox(height: SpacingTokens.md),
                  _buildField(_passCtrl, 'PASSWORD', true),
                  const SizedBox(height: SpacingTokens.md),
                  _buildField(_confirmCtrl, 'CONFIRM PASSWORD', true),
                  const SizedBox(height: SpacingTokens.md),
                  _buildTeamDropdown(),
                  const SizedBox(height: SpacingTokens.xl),
                  if (displayError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(SpacingTokens.sm),
                      color: ColorTokens.negative.withValues(alpha: 0.15),
                      child: Text(
                        displayError,
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
                              'REGISTER',
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
                        'ALREADY HAVE AN ACCOUNT? ',
                        style: TypographyTokens.sectionLabel,
                      ),
                      GestureDetector(
                        onTap: widget.onLoginTap,
                        child: Text(
                          'SIGN IN',
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

  Widget _buildTeamDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SELECT TEAM', style: TypographyTokens.sectionLabel),
        const SizedBox(height: SpacingTokens.xs),
        Container(
          decoration: BoxDecoration(
            color: ColorTokens.surfaceLow,
            border: Border.all(
              color: _selectedTeam != null
                  ? ColorTokens.accent
                  : ColorTokens.divider,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.md),
          child: _loadingTeams
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: SpacingTokens.sm),
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ColorTokens.accent,
                    ),
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedTeam,
                    hint: Text(
                      'Choose your team',
                      style: TypographyTokens.body
                          .copyWith(color: ColorTokens.textMuted),
                    ),
                    dropdownColor: ColorTokens.surfaceLow,
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: ColorTokens.accent,
                    ),
                    style: TypographyTokens.body,
                    items: _teams.map((team) {
                      return DropdownMenuItem<String>(
                        value: team,
                        child: Text(team),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedTeam = value);
                    },
                  ),
                ),
        ),
      ],
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
