import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/colors.dart';
import '../../data/models/user_profile.dart';
import '../../state/user_profile_provider.dart';
import 'dashboard_screen.dart';

class ProfileFormScreen extends StatefulWidget {
  final bool skipIfFilled;
  const ProfileFormScreen({super.key, this.skipIfFilled = false});

  @override
  State<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends State<ProfileFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ageCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  Sex _sex = Sex.male;
  ActivityLevel _activity = ActivityLevel.moderate;

  @override
  void initState() {
    super.initState();
    final existing = context.read<UserProfileProvider>().profile;
    if (existing != null) {
      _ageCtrl.text = existing.ageYears.toString();
      _weightCtrl.text = existing.weightKg.toStringAsFixed(0);
      _heightCtrl.text = existing.heightCm.toStringAsFixed(0);
      _sex = existing.sex;
      _activity = existing.activity;
      if (widget.skipIfFilled) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _proceedToDashboard();
        });
      }
    }
  }

  @override
  void dispose() {
    _ageCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final profile = UserProfile(
      ageYears: int.parse(_ageCtrl.text),
      weightKg: double.parse(_weightCtrl.text),
      heightCm: double.parse(_heightCtrl.text),
      sex: _sex,
      activity: _activity,
    );
    context.read<UserProfileProvider>().save(profile);
    _proceedToDashboard();
  }

  void _proceedToDashboard() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Datos demográficos')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const _SectionHeader(
                title: 'Cuéntanos sobre ti',
                subtitle:
                    'Usamos estos datos para calcular tus zonas cardíacas y personalizar las recomendaciones.',
              ),
              const SizedBox(height: 24),
              _NumberField(
                controller: _ageCtrl,
                label: 'Edad',
                suffix: 'años',
                min: 5,
                max: 120,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _NumberField(
                      controller: _weightCtrl,
                      label: 'Peso',
                      suffix: 'kg',
                      min: 20,
                      max: 300,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _NumberField(
                      controller: _heightCtrl,
                      label: 'Estatura',
                      suffix: 'cm',
                      min: 80,
                      max: 250,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const _Label('Sexo'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: Sex.values
                    .map((s) => ChoiceChip(
                          label: Text(s.label),
                          selected: _sex == s,
                          onSelected: (_) => setState(() => _sex = s),
                          selectedColor: AppColors.accentCyan.withValues(alpha: 0.18),
                          backgroundColor: AppColors.surface,
                          labelStyle: TextStyle(
                            color: _sex == s
                                ? AppColors.accentCyan
                                : AppColors.textSecondary,
                            fontWeight:
                                _sex == s ? FontWeight.w600 : FontWeight.w500,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                            side: BorderSide(
                              color: _sex == s
                                  ? AppColors.accentCyan
                                  : AppColors.divider,
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),
              const _Label('Nivel de actividad'),
              const SizedBox(height: 8),
              Column(
                children: ActivityLevel.values
                    .map((a) => _ActivityRow(
                          level: a,
                          selected: _activity == a,
                          onTap: () => setState(() => _activity = a),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Guardar y continuar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTheme.monoNumeric(size: 22, weight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(subtitle,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500));
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String suffix;
  final num min;
  final num max;

  const _NumberField({
    required this.controller,
    required this.label,
    required this.suffix,
    required this.min,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType:
          TextInputType.numberWithOptions(decimal: max - min > 1, signed: false),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Requerido';
        final n = double.tryParse(v);
        if (n == null) return 'Número inválido';
        if (n < min || n > max) return 'Rango: $min-$max';
        return null;
      },
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final ActivityLevel level;
  final bool selected;
  final VoidCallback onTap;

  const _ActivityRow(
      {required this.level, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? AppColors.accentCyan.withValues(alpha: 0.10)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? AppColors.accentCyan : AppColors.divider,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: selected ? AppColors.accentCyan : AppColors.textMuted,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(level.label,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                      Text('HR reposo estimado: ${level.defaultRestingHr} BPM',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
