import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class ContextMenuAction {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  ContextMenuAction({
    required this.title,
    required this.icon,
    required this.onTap,
    this.color,
  });
}

class LuxemContextMenu extends StatefulWidget {
  final Widget child;
  final List<ContextMenuAction> actions;
  final String? title;

  const LuxemContextMenu({
    super.key,
    required this.child,
    required this.actions,
    this.title,
  });

  @override
  State<LuxemContextMenu> createState() => _LuxemContextMenuState();
}

class _LuxemContextMenuState extends State<LuxemContextMenu> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showMenu(BuildContext context, LongPressStartDetails details) {
    HapticFeedback.heavyImpact();
    _controller.forward();

    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RenderBox button = context.findRenderObject() as RenderBox;
    final Offset position = button.localToGlobal(Offset.zero, ancestor: overlay);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.7),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(color: Colors.transparent),
              ),
            ),
            Positioned(
              top: position.dy - 10,
              left: position.dx,
              width: button.size.width,
              child: Material(
                color: Colors.transparent,
                child: Hero(
                  tag: 'context_menu_child_${identityHashCode(widget.child)}',
                  child: Transform.scale(
                    scale: 0.96,
                    child: widget.child,
                  ),
                ),
              ),
            ),
            _buildMenuItems(context, position, button.size),
          ],
        );
      },
    ).then((_) {
      _controller.reverse();
    });
  }

  Widget _buildMenuItems(BuildContext context, Offset position, Size size) {
    // Calculate if menu should be above or below
    final double screenHeight = MediaQuery.of(context).size.height;
    final bool showAbove = (position.dy + size.height + 200) > screenHeight;

    return Positioned(
      top: showAbove ? null : position.dy + size.height + 12,
      bottom: showAbove ? (screenHeight - position.dy) + 12 : null,
      left: position.dx + (size.width > 250 ? (size.width - 250) / 2 : 0),
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 250,
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 24,
                spreadRadius: 4,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.title != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text(
                      widget.title!,
                      style: TextStyle(
                        color: AppTheme.textSecondary.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
                ],
                ...widget.actions.asMap().entries.map((entry) {
                  final int index = entry.key;
                  final action = entry.value;
                  return _buildActionRow(context, action, index == widget.actions.length - 1);
                }),
              ],
            ),
          ),
        ).animate().scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1, 1),
          curve: Curves.easeOutBack,
          duration: 300.ms,
        ).fadeIn(duration: 200.ms),
      ),
    );
  }

  Widget _buildActionRow(BuildContext context, ContextMenuAction action, bool isLast) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        action.onTap();
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(action.icon, color: action.color ?? AppTheme.textPrimary, size: 18),
                const SizedBox(width: 14),
                Text(
                  action.title,
                  style: TextStyle(
                    color: action.color ?? AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
          if (!isLast) Divider(color: Colors.white.withValues(alpha: 0.05), height: 1, indent: 48),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (details) => _showMenu(context, details),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}
