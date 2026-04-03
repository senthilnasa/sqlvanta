import 'package:flutter/material.dart';
import 'package:split_view/split_view.dart';

class AppSplitView extends StatelessWidget {
  final Widget leading;
  final Widget trailing;
  final Axis axis;
  final double initialRatio;
  final double minRatio;
  final double maxRatio;

  const AppSplitView({
    super.key,
    required this.leading,
    required this.trailing,
    this.axis = Axis.horizontal,
    this.initialRatio = 0.25,
    this.minRatio = 0.10,
    this.maxRatio = 0.60,
  });

  @override
  Widget build(BuildContext context) {
    return SplitView(
      viewMode:
          axis == Axis.horizontal
              ? SplitViewMode.Horizontal
              : SplitViewMode.Vertical,
      indicator: SplitIndicator(
        viewMode:
            axis == Axis.horizontal
                ? SplitViewMode.Horizontal
                : SplitViewMode.Vertical,
        color: Theme.of(context).dividerColor,
      ),
      activeIndicator: SplitIndicator(
        viewMode:
            axis == Axis.horizontal
                ? SplitViewMode.Horizontal
                : SplitViewMode.Vertical,
        isActive: true,
        color: Theme.of(context).colorScheme.primary,
      ),
      controller: SplitViewController(
        weights: [initialRatio, 1 - initialRatio],
        limits: [WeightLimit(min: minRatio, max: maxRatio), null],
      ),
      children: [leading, trailing],
    );
  }
}
