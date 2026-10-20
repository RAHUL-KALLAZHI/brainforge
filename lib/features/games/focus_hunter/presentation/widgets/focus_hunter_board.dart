import 'package:flutter/material.dart';
import 'package:brainforge/core/constants/app_spacing.dart';
import 'package:brainforge/features/games/focus_hunter/logic/focus_hunter_state.dart';
import 'focus_hunter_tile.dart';

/// Responsive grid board displaying Focus Hunter items adapted for all screen sizes.
class FocusHunterBoard extends StatelessWidget {
  final FocusHunterState state;
  final ValueChanged<int> onItemTapped;

  const FocusHunterBoard({
    super.key,
    required this.state,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    final rows = state.challenge.gridRows;
    final columns = state.challenge.gridColumns;
    final items = state.challenge.items;

    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxW =
              constraints.maxWidth < 420 ? constraints.maxWidth : 420.0;
          final maxH =
              constraints.maxHeight < 500 ? constraints.maxHeight : 500.0;

          return ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxW,
              maxHeight: maxH,
            ),
            child: AspectRatio(
              aspectRatio: columns / rows,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: AppSpacing.sm,
                    crossAxisSpacing: AppSpacing.sm,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isFound = state.foundTargetIndices.contains(index);
                    final isMistake = state.mistakeIndices.contains(index);

                    return FocusHunterTile(
                      key: Key('focus_hunter_tile_$index'),
                      item: item,
                      index: index,
                      isFoundTarget: isFound,
                      isMistake: isMistake,
                      isInputAllowed: state.isInputAllowed,
                      onTap: () => onItemTapped(index),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
