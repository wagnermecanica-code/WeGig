import 'dart:io' show Platform;

import 'package:core_ui/theme/app_colors.dart';
import 'package:core_ui/theme/app_typography.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Idade mínima para usar o app
const int kMinimumAge = 18;

/// Provider para armazenar o ano de nascimento verificado durante o cadastro
/// 
/// Usado para pré-preencher o campo de ano de nascimento na criação de perfil.
/// É resetado quando o usuário faz logout.
final verifiedBirthYearProvider = StateProvider<int?>((ref) => null);

/// Resultado da verificação de idade
class AgeVerificationResult {
  /// Se o usuário passou na verificação (18+)
  final bool isAdult;
  
  /// Ano de nascimento informado (null se cancelou)
  final int? birthYear;
  
  /// Construtor
  const AgeVerificationResult({
    required this.isAdult,
    this.birthYear,
  });
  
  /// Usuário cancelou o dialog
  static const cancelled = AgeVerificationResult(isAdult: false);
  
  /// Usuário é menor de idade
  static const underage = AgeVerificationResult(isAdult: false);
}

/// Dialog para verificação de idade antes do cadastro
/// 
/// Exibe um DatePicker para o usuário informar sua data de nascimento.
/// Se o usuário tiver menos de 18 anos, o cadastro é bloqueado.
class AgeVerificationDialog extends StatefulWidget {
  /// Cria um dialog de verificação de idade
  const AgeVerificationDialog({super.key});

  /// Mostra o dialog e retorna o resultado da verificação
  /// 
  /// Para uso simples (apenas verificar se é adulto):
  /// ```dart
  /// final result = await AgeVerificationDialog.show(context);
  /// if (!result.isAdult) return;
  /// ```
  /// 
  /// Para pré-preencher o ano de nascimento no perfil:
  /// ```dart
  /// final result = await AgeVerificationDialog.show(context, ref: ref);
  /// if (result.isAdult && result.birthYear != null) {
  ///   // birthYear já foi salvo no verifiedBirthYearProvider
  /// }
  /// ```
  static Future<AgeVerificationResult> show(
    BuildContext context, {
    WidgetRef? ref,
  }) async {
    final result = await showDialog<AgeVerificationResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AgeVerificationDialog(),
    );
    
    final verificationResult = result ?? AgeVerificationResult.cancelled;
    
    // Salva o ano de nascimento no provider se foi fornecido
    if (ref != null && verificationResult.isAdult && verificationResult.birthYear != null) {
      ref.read(verifiedBirthYearProvider.notifier).state = verificationResult.birthYear;
    }
    
    return verificationResult;
  }

  @override
  State<AgeVerificationDialog> createState() => _AgeVerificationDialogState();
}

class _AgeVerificationDialogState extends State<AgeVerificationDialog> {
  DateTime? _selectedDate;
  bool _isUnderage = false;

  /// Calcula a idade a partir da data de nascimento
  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    var age = now.year - birthDate.year;
    
    // Ajusta se ainda não fez aniversário este ano
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    
    return age;
  }

  /// Data máxima permitida (hoje)
  DateTime get _maxDate => DateTime.now();

  /// Data mínima para seleção (100 anos atrás)
  DateTime get _minDate => DateTime(DateTime.now().year - 100);

  /// Data inicial do picker (18 anos atrás)
  DateTime get _initialDate => DateTime(
    DateTime.now().year - kMinimumAge,
    DateTime.now().month,
    DateTime.now().day,
  );

  void _onDateSelected(DateTime date) {
    final age = _calculateAge(date);
    setState(() {
      _selectedDate = date;
      _isUnderage = age < kMinimumAge;
    });
  }

  Future<void> _showDatePicker() async {
    if (Platform.isIOS) {
      await _showCupertinoDatePicker();
    } else {
      await _showMaterialDatePicker();
    }
  }

  Future<void> _showMaterialDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? _initialDate,
      firstDate: _minDate,
      lastDate: _maxDate,
      helpText: 'Selecione sua data de nascimento',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
      fieldLabelText: 'Data de nascimento',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _onDateSelected(picked);
    }
  }

  Future<void> _showCupertinoDatePicker() async {
    var tempDate = _selectedDate ?? _initialDate;
    
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: Colors.white,
        child: Column(
          children: [
            Container(
              height: 50,
              color: AppColors.surface,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Cancelar'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  CupertinoButton(
                    child: const Text(
                      'Confirmar',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      _onDateSelected(tempDate);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _selectedDate ?? _initialDate,
                minimumDate: _minDate,
                maximumDate: _maxDate,
                onDateTimeChanged: (date) => tempDate = date,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirm() {
    if (_selectedDate == null) {
      return;
    }
    
    if (_isUnderage) {
      // Não permite continuar - mostra mensagem de bloqueio
      return;
    }
    
    // Retorna resultado com ano de nascimento
    Navigator.of(context).pop(AgeVerificationResult(
      isAdult: true,
      birthYear: _selectedDate!.year,
    ));
  }

  void _cancel() {
    Navigator.of(context).pop(AgeVerificationResult.cancelled);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            Icons.cake_outlined,
            color: _isUnderage ? AppColors.error : AppColors.primary,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text('Verificação de Idade'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Para usar o WeGig, você precisa ter pelo menos $kMinimumAge anos.',
              style: AppTypography.bodyLight.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            
            // Botão para selecionar data
            InkWell(
              onTap: _showDatePicker,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isUnderage 
                        ? AppColors.error 
                        : (_selectedDate != null ? AppColors.primary : AppColors.border),
                    width: _selectedDate != null ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      color: _isUnderage ? AppColors.error : AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedDate != null
                            ? '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}'
                            : 'Toque para selecionar',
                        style: TextStyle(
                          fontSize: 16,
                          color: _selectedDate != null 
                              ? AppColors.textPrimary 
                              : AppColors.textHint,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_drop_down,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
            
            // Mensagem de idade (se selecionou data)
            if (_selectedDate != null) ...[
              const SizedBox(height: 16),
              if (_isUnderage)
                _buildUnderageWarning()
              else
                _buildAgeConfirmation(),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _cancel,
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _selectedDate != null && !_isUnderage ? _confirm : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey[300],
            disabledForegroundColor: Colors.grey[500],
          ),
          child: const Text('Confirmar'),
        ),
      ],
    );
  }

  Widget _buildUnderageWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: AppColors.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Acesso não permitido',
                style: AppTypography.bodyLight.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Desculpe, o WeGig é exclusivo para maiores de 18 anos, para garantir segurança e conformidade legal em conexões profissionais.',
            style: AppTypography.captionLight.copyWith(
              color: AppColors.error,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgeConfirmation() {
    final age = _calculateAge(_selectedDate!);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: Colors.green,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Você tem $age anos ✓',
            style: AppTypography.bodyLight.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.green[700],
            ),
          ),
        ],
      ),
    );
  }
}
