import 'package:flutter/material.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:core_ui/theme/app_typography.dart';
import 'package:iconsax/iconsax.dart';

/// Widgets reutilizáveis para tela de autenticação
/// 
/// Reduz duplicação de código e facilita manutenção
/// Todos os widgets usam AppColors/AppTypography para consistência

/// Campo de texto customizado para autenticação
class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final bool enabled;
  final Widget? suffixIcon;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.enabled = true,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(prefixIcon, color: AppColors.primary),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      enabled: enabled,
    );
  }
}

/// Botão primário para ações de autenticação
class AuthPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  const AuthPrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(text),
    );
  }
}

/// Botão secundário/outlined para autenticação
class AuthSecondaryButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Widget? iconWidget;
  final VoidCallback? onPressed;
  final bool isLoading;

  const AuthSecondaryButton({
    super.key,
    required this.text,
    this.icon,
    this.iconWidget,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget? buttonIcon;
    if (iconWidget != null) {
      buttonIcon = iconWidget;
    } else if (icon != null) {
      buttonIcon = Icon(icon, color: AppColors.textPrimary);
    }

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: BorderSide(color: AppColors.border, width: 1.5),
      ),
      onPressed: isLoading ? null : onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (buttonIcon != null) ...[
            buttonIcon,
            const SizedBox(width: 12),
          ],
          Text(
            text,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card de erro com ícone e mensagem
class ErrorMessageBox extends StatelessWidget {
  final String message;

  const ErrorMessageBox({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error),
      ),
      child: Row(
        children: [
          Icon(Iconsax.danger, color: AppColors.error, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppColors.error,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Toggle button para alternar entre login e cadastro
class AuthModeToggle extends StatelessWidget {
  final bool isLogin;
  final VoidCallback onToggle;
  final bool isLoading;

  const AuthModeToggle({
    super.key,
    required this.isLogin,
    required this.onToggle,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          isLogin ? 'Não tem uma conta? ' : 'Já tem uma conta? ',
          style: AppTypography.bodyLight,
        ),
        TextButton(
          onPressed: isLoading ? null : onToggle,
          child: Text(
            isLogin ? 'Cadastre-se' : 'Entrar',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

/// Divider com texto "ou" no meio
class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'ou',
            style: AppTypography.captionLight.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }
}

/// Header da tela de autenticação (logo + título + subtítulo)
class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          Iconsax.musicnote,
          size: 80,
          color: AppColors.primary,
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: AppTypography.displayLarge.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: AppTypography.bodyLight.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Card container para formulário de autenticação
class AuthCard extends StatelessWidget {
  final Widget child;

  const AuthCard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(32),
      child: child,
    );
  }
}
