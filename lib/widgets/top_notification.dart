import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum NotificationType { success, error, info }

class TopNotification extends StatelessWidget {
  final String message;
  final NotificationType type;
  final VoidCallback onDismiss;
  final String? actionLabel;
  final VoidCallback? onAction;

  const TopNotification({super.key, required this.message, required this.type, required this.onDismiss, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    IconData iconData;
    List<Color> gradientColors;

    switch (type) {
      case NotificationType.success:
        iconData = Icons.check_circle_rounded;
        gradientColors = [const Color(0xFF10B981), const Color(0xFF34D399)];
        break;
      case NotificationType.error:
        iconData = Icons.error_rounded;
        gradientColors = [const Color(0xFFEF4444), const Color(0xFFF87171)];
        break;
      case NotificationType.info:
        iconData = Icons.info_rounded;
        gradientColors = [AppColors.gradientStart, AppColors.gradientEnd];
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      // Glassmorphism effect
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85), // Slightly more opaque for readability
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
              boxShadow: [
                BoxShadow(color: const Color(0xFF000000).withValues(alpha: 0.1), blurRadius: 24, offset: const Offset(0, 8)),
                BoxShadow(color: const Color(0xFF000000).withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                // Icon Container with gradient background
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: gradientColors[0].withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Icon(iconData, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                // Text
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.2,
                      decoration: TextDecoration.none, // Ensure no underline if not in Scaffold text theme
                      fontFamily: 'Inter',
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: onAction,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      foregroundColor: AppColors.gradientStart,
                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    child: Text(actionLabel!),
                  ),
                ],
                // Close Button
                GestureDetector(
                  onTap: onDismiss,
                  child: Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: AppColors.textTertiary.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textTertiary),
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

class NotificationOverlay {
  static void show({required BuildContext context, required String message, NotificationType type = NotificationType.info, Duration duration = const Duration(seconds: 4), String? actionLabel, VoidCallback? onAction}) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _NotificationWrapper(
        message: message,
        type: type,
        duration: duration,
        actionLabel: actionLabel,
        onAction: onAction,
        onDismiss: () {
          if (overlayEntry.mounted) {
            overlayEntry.remove();
          }
        },
      ),
    );

    overlay.insert(overlayEntry);
  }
}

class _NotificationWrapper extends StatefulWidget {
  final String message;
  final NotificationType type;
  final Duration duration;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismiss;

  const _NotificationWrapper({required this.message, required this.type, required this.duration, this.actionLabel, this.onAction, required this.onDismiss});

  @override
  State<_NotificationWrapper> createState() => _NotificationWrapperState();
}

class _NotificationWrapperState extends State<_NotificationWrapper> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600), reverseDuration: const Duration(milliseconds: 400));

    _slideAnimation = Tween<Offset>(begin: const Offset(0, -1.2), end: const Offset(0, 0)).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.4, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    // Auto dismiss
    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    _controller.reverse().then((_) => widget.onDismiss());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + 12;

    return Positioned(
      top: topPadding,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            type: MaterialType.transparency,
            child: TopNotification(
              message: widget.message,
              type: widget.type,
              actionLabel: widget.actionLabel,
              onAction: widget.onAction == null
                  ? null
                  : () {
                      _dismiss();
                      widget.onAction?.call();
                    },
              onDismiss: _dismiss,
            ),
          ),
        ),
      ),
    );
  }
}
