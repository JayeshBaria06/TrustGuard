import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_theme.dart';

class EmptyState extends StatelessWidget {
  final IconData? icon;
  final String? svgPath;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  const EmptyState({
    super.key,
    this.icon,
    this.svgPath,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onActionPressed,
  }) : assert(
         icon != null || svgPath != null,
         'Either icon or svgPath must be provided',
       );

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (svgPath != null)
              SvgPicture.asset(
                svgPath!,
                height: 160,
                width: 160,
                placeholderBuilder: (context) => const SizedBox(
                  height: 160,
                  width: 160,
                  child: CircularProgressIndicator(),
                ),
              )
            else if (icon != null)
              Icon(
                icon,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
            const SizedBox(height: AppTheme.space24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.space8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (actionLabel != null && onActionPressed != null) ...[
              const SizedBox(height: AppTheme.space24),
              FilledButton.icon(
                onPressed: onActionPressed,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
