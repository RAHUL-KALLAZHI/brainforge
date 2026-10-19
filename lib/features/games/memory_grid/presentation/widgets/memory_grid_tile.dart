import 'package:flutter/material.dart';
import 'package:brainforge/core/constants/app_colors.dart';
import 'package:brainforge/core/constants/app_spacing.dart';
import 'package:brainforge/core/theme/theme_extensions.dart';

/// Interactive, accessible grid tile for Memory Grid.
class MemoryGridTile extends StatefulWidget {
  final int index;
  final int row;
  final int column;
  final bool isHighlighted;
  final bool isSelected;
  final bool? isCorrect;
  final bool isInputAllowed;
  final VoidCallback? onTap;

  const MemoryGridTile({
    super.key,
    required this.index,
    required this.row,
    required this.column,
    this.isHighlighted = false,
    this.isSelected = false,
    this.isCorrect,
    this.isInputAllowed = true,
    this.onTap,
  });

  @override
  State<MemoryGridTile> createState() => _MemoryGridTileState();
}

class _MemoryGridTileState extends State<MemoryGridTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(MemoryGridTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isHighlighted && !oldWidget.isHighlighted) {
      _animController.forward().then((_) {
        if (mounted) _animController.reverse();
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Color _resolveTileColor(BrainForgeThemeExtension customTheme) {
    // 1. Sequence preview highlight
    if (widget.isHighlighted) {
      return customTheme.accentCyan;
    }

    // 2. Selection feedback
    if (widget.isSelected) {
      if (widget.isCorrect == true) {
        return AppColors.success;
      } else if (widget.isCorrect == false) {
        return AppColors.error;
      }
      return customTheme.accentViolet;
    }

    // 3. Default idle tile
    return customTheme.surfaceCardElevated;
  }

  Color _resolveBorderColor(BrainForgeThemeExtension customTheme) {
    if (widget.isHighlighted) {
      return customTheme.accentCyan;
    }
    if (widget.isSelected) {
      if (widget.isCorrect == true) {
        return AppColors.successLight;
      } else if (widget.isCorrect == false) {
        return AppColors.error;
      }
      return AppColors.electricVioletLight;
    }
    return customTheme.cardBorder;
  }

  List<BoxShadow> _resolveBoxShadow(BrainForgeThemeExtension customTheme) {
    if (widget.isHighlighted) {
      return [
        BoxShadow(
          color: customTheme.accentCyan.withValues(alpha: 0.5),
          blurRadius: 16,
          spreadRadius: 2,
        ),
      ];
    }
    if (widget.isSelected && widget.isCorrect == true) {
      return [
        BoxShadow(
          color: AppColors.success.withValues(alpha: 0.4),
          blurRadius: 12,
          spreadRadius: 1,
        ),
      ];
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final customTheme = context.brainForgeTheme;
    final tileColor = _resolveTileColor(customTheme);
    final borderColor = _resolveBorderColor(customTheme);
    final boxShadow = _resolveBoxShadow(customTheme);
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    return Semantics(
      label: 'Tile row ${widget.row + 1}, column ${widget.column + 1}',
      button: true,
      enabled: widget.isInputAllowed,
      child: GestureDetector(
        onTapDown: (_) {
          if (widget.isInputAllowed) {
            _animController.forward();
          }
        },
        onTapUp: (_) {
          if (widget.isInputAllowed) {
            _animController.reverse();
          }
        },
        onTapCancel: () {
          if (widget.isInputAllowed) {
            _animController.reverse();
          }
        },
        onTap: widget.isInputAllowed ? widget.onTap : null,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: tileColor,
              borderRadius: AppSpacing.roundedLg,
              border: Border.all(
                color: borderColor,
                width: widget.isHighlighted || widget.isSelected ? 2.5 : 1.5,
              ),
              boxShadow: boxShadow,
            ),
            child: Center(
              child: widget.isHighlighted
                  ? Icon(
                      Icons.star_rounded,
                      color: scaffoldBg,
                      size: 28,
                    )
                  : widget.isSelected && widget.isCorrect == true
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 28,
                        )
                      : widget.isSelected && widget.isCorrect == false
                          ? const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 28,
                            )
                          : null,
            ),
          ),
        ),
      ),
    );
  }
}
