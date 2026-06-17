import 'package:flutter/widgets.dart';

import 'flexy_wrap.dart';

/// Specifies the preference for breaking to a new row after a Flexy item.
enum FlexyBreakAfter {
  /// Let the layout algorithm decide the best place to break naturally.
  auto,

  /// Heavily bias the algorithm to break the line immediately after this item.
  prefer,

  /// Strongly prefer keeping this item glued to the next item on the same line.
  avoid,
}

/// A widget that controls how a child of a [FlexyWrap] should be laid out.
///
/// Must be a direct descendant of a [FlexyWrap] widget.
class Flexy extends ParentDataWidget<FlexyParentData> {
  /// The base width for this child.
  ///
  /// Determines when line breaks occur. If the remaining space in a row is less
  /// than this width, the child wraps to the next row.
  ///
  /// This value also acts as the child's flex weight. Flexible children share
  /// extra horizontal space proportionally based on their [baseWidth].
  ///
  /// If `null`, `FlexyWrap` automatically calculates the child's natural unconstrained width.
  final double? baseWidth;

  /// The maximum width this child can grow to when there is extra space in the row.
  ///
  /// If [maxWidth] is greater than the child's base width, the child
  /// expands to share available horizontal space with other flexible items.
  ///
  /// * Set to `null` to allow unlimited growth.
  /// * Set to `0` (or <= base width) to prevent the child from growing at all.
  final double? maxWidth;

  /// The hard minimum width this child is allowed to shrink to when space is constrained.
  ///
  /// During extreme layout constraints (such as when forced into a limited number of [maxRows]),
  /// the layout engine will squish children proportionally to fit the available space.
  /// This value sets an absolute floor for this child. If `null`, it can squish down to 0.
  final double? minWidth;

  /// The preference for breaking to a new line after this item.
  /// Defaults to [FlexyBreakAfter.auto].
  final FlexyBreakAfter breakAfter;

  const Flexy({
    super.key,
    this.baseWidth,
    this.maxWidth,
    this.minWidth,
    this.breakAfter = FlexyBreakAfter.auto,
    required super.child,
  });

  @override
  void applyParentData(RenderObject renderObject) {
    final parentData = renderObject.parentData as FlexyParentData;
    bool needsLayout = false;

    if (parentData.baseWidth != baseWidth) {
      parentData.baseWidth = baseWidth;
      needsLayout = true;
    }
    if (parentData.maxWidth != maxWidth) {
      parentData.maxWidth = maxWidth;
      needsLayout = true;
    }
    if (parentData.minWidth != minWidth) {
      parentData.minWidth = minWidth;
      needsLayout = true;
    }
    if (parentData.breakAfter != breakAfter) {
      parentData.breakAfter = breakAfter;
      needsLayout = true;
    }

    if (needsLayout) {
      final targetParent = renderObject.parent;
      if (targetParent is RenderObject) targetParent.markNeedsLayout();
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => FlexyWrap;
}
