import 'package:flutter/material.dart';

/// Standardized bottom sheet widget with consistent styling
/// 
/// Features:
/// - Rounded top corners (20px radius)
/// - Handle bar indicator
/// - Safe area padding
/// - Smooth animations
/// - Dismiss on drag down
/// 
/// Usage:
/// ```dart
/// AppBottomSheet.show(
///   context,
///   title: 'Opções do Post',
///   children: [
///     ListTile(
///       leading: Icon(Icons.edit),
///       title: Text('Editar'),
///       onTap: () => _editPost(),
///     ),
///     ListTile(
///       leading: Icon(Icons.delete, color: Colors.red),
///       title: Text('Deletar', style: TextStyle(color: Colors.red)),
///       onTap: () => _deletePost(),
///     ),
///   ],
/// );
/// ```
class AppBottomSheet extends StatelessWidget {
  final String? title;
  final List<Widget> children;
  final bool showHandle;
  final EdgeInsets? padding;

  const AppBottomSheet({
    super.key,
    this.title,
    required this.children,
    this.showHandle = true,
    this.padding,
  });

  /// Show bottom sheet with standard styling
  /// 
  /// Returns value passed to Navigator.pop() or null if dismissed by drag/tap
  static Future<T?> show<T>(
    BuildContext context, {
    String? title,
    required List<Widget> children,
    bool showHandle = true,
    EdgeInsets? padding,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AppBottomSheet(
        title: title,
        showHandle: showHandle,
        padding: padding,
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            if (showHandle) ...[
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Title
            if (title != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  title!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Divider(color: Colors.grey.shade200, height: 1),
            ],

            // Content
            Padding(
              padding: padding ?? const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pre-configured list tile for bottom sheets
/// 
/// Usage:
/// ```dart
/// AppBottomSheet.show(
///   context,
///   children: [
///     AppBottomSheetTile(
///       icon: Icons.edit,
///       title: 'Editar',
///       onTap: () => _edit(),
///     ),
///     AppBottomSheetTile(
///       icon: Icons.delete,
///       title: 'Deletar',
///       isDestructive: true,
///       onTap: () => _delete(),
///     ),
///   ],
/// );
/// ```
class AppBottomSheetTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isDestructive;
  final Widget? trailing;

  const AppBottomSheetTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.isDestructive = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.red : null;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(color: color),
      ),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing,
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }
}

/// Scrollable bottom sheet for long content
/// 
/// Usage:
/// ```dart
/// AppBottomSheet.showScrollable(
///   context,
///   title: 'Escolher Perfil',
///   children: profiles.map((p) => ProfileTile(p)).toList(),
/// );
/// ```
class AppScrollableBottomSheet extends StatelessWidget {
  final String? title;
  final List<Widget> children;
  final double? maxHeight;

  const AppScrollableBottomSheet({
    super.key,
    this.title,
    required this.children,
    this.maxHeight,
  });

  static Future<T?> show<T>(
    BuildContext context, {
    String? title,
    required List<Widget> children,
    double? maxHeight,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AppScrollableBottomSheet(
        title: title,
        maxHeight: maxHeight,
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final defaultMaxHeight = screenHeight * 0.7;

    return Container(
      constraints: BoxConstraints(
        maxHeight: maxHeight ?? defaultMaxHeight,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),

            // Title
            if (title != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  title!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Divider(color: Colors.grey.shade200, height: 1),
            ],

            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: children,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
