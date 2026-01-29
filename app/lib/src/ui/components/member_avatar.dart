import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/models/member.dart';

class MemberAvatar extends StatelessWidget {
  final Member member;
  final double radius;
  final TextStyle? textStyle;
  final bool isSelected;
  final Color? borderColor;

  const MemberAvatar({
    super.key,
    required this.member,
    this.radius = 22,
    this.textStyle,
    this.isSelected = false,
    this.borderColor,
  });

  String _getInitials(String name) {
    if (name.isEmpty) return '';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fallbackColor = isSelected
        ? colorScheme.primaryContainer
        : member.avatarColor != null
        ? member.displayColor
        : colorScheme.surfaceContainerHighest;
    final onFallbackColor = isSelected
        ? colorScheme.onPrimaryContainer
        : member.avatarColor != null
        ? (ThemeData.estimateBrightnessForColor(member.displayColor) ==
                  Brightness.dark
              ? Colors.white
              : Colors.black)
        : colorScheme.onSurfaceVariant;

    final label = member.hasAvatar
        ? 'Photo of ${member.displayName}'
        : '${member.displayName} with background color';

    Widget avatar;
    if (member.hasAvatar && member.avatarPath != null) {
      final file = File(member.avatarPath!);
      if (file.existsSync()) {
        avatar = ClipOval(
          child: Image.file(
            file,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildFallback(fallbackColor, onFallbackColor);
            },
          ),
        );
      } else {
        avatar = _buildFallback(fallbackColor, onFallbackColor);
      }
    } else {
      avatar = _buildFallback(fallbackColor, onFallbackColor);
    }

    Widget result = avatar;
    if (borderColor != null || isSelected) {
      result = Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: borderColor ?? colorScheme.primary,
            width: 2,
          ),
        ),
        child: avatar,
      );
    }

    return Semantics(label: label, child: result);
  }

  Widget _buildFallback(Color backgroundColor, Color textColor) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: Text(
        _getInitials(member.displayName),
        style:
            textStyle ??
            TextStyle(
              color: textColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
      ),
    );
  }
}
