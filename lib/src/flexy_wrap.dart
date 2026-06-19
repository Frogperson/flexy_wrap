// ignore_for_file: prefer_initializing_formals
import 'dart:ui' show lerpDouble;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'flexy.dart';

/// The strategy used to determine where line breaks occur in a [FlexyWrap].
enum FlexyWrapStrategy {
  /// Analyzes the entire layout and calculates the most visually balanced
  /// line breaks to minimize ragged edges and orphaned items.
  balanced,

  /// A standard wrap algorithm that packs as many items into a row as possible
  /// before moving to the next line. Faster, but can lead to visually unbalanced rows.
  greedy,
}

class FlexyParentData extends ContainerBoxParentData<RenderBox> {
  double? baseWidth;
  double? maxWidth;
  double? minWidth;
  FlexyBreakAfter breakAfter = FlexyBreakAfter.auto;

  double get effectiveMinWidth => baseWidth ?? _effectiveMinWidth;
  double _effectiveMinWidth = 0.0;

  Rect? actualRect;
  Rect? oldRect;
  Rect? targetRect;
  int? targetRowIndex;
}

/// A widget that displays its children in multiple horizontal rows, automatically
/// wrapping and distributing them according to a [FlexyWrapStrategy].
///
/// Unlike a standard [Wrap], `FlexyWrap` can distribute remaining horizontal space
/// proportionally among its children by utilizing the [Flexy] widget. It also supports
/// smooth, native layout animations when its constraints or children change.
class FlexyWrap extends StatefulWidget {
  /// The amount of horizontal space to leave between children.
  final double horizontalSpacing;

  /// The amount of vertical space to leave between rows.
  final double verticalSpacing;

  /// Whether to smoothly animate layout changes.
  final bool animate;

  /// The duration of the layout animation.
  final Duration duration;

  /// The easing curve of the layout animation.
  final Curve curve;

  /// The algorithm used to determine where line breaks should occur.
  final FlexyWrapStrategy strategy;

  /// How the children within a row should be placed in the main axis.
  final WrapAlignment horizontalAlignment;

  /// How the children within a row should be aligned relative to each other in the cross axis.
  final WrapCrossAlignment verticalAlignment;

  /// How the rows themselves should be placed in the cross axis.
  final WrapAlignment runAlignment;

  /// The maximum number of rows to display. Extra children are hidden.
  final int? maxRows;

  /// The widgets to be displayed by this layout.
  /// Wrap children in [Flexy] to give them minimum and maximum widths.
  final List<Widget> children;

  const FlexyWrap({
    super.key,
    this.horizontalSpacing = 8.0,
    this.verticalSpacing = 8.0,
    this.horizontalAlignment = WrapAlignment.start,
    this.verticalAlignment = WrapCrossAlignment.start,
    this.runAlignment = WrapAlignment.start,
    this.animate = true,
    this.duration = const Duration(milliseconds: 200),
    this.curve = Curves.easeInOut,
    this.strategy = FlexyWrapStrategy.balanced,
    this.maxRows,
    required this.children,
  });

  @override
  State<FlexyWrap> createState() => _FlexyWrapState();
}

class _FlexyWrapState extends State<FlexyWrap>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return _RawFlexyWrap(
      horizontalSpacing: widget.horizontalSpacing,
      verticalSpacing: widget.verticalSpacing,
      horizontalAlignment: widget.horizontalAlignment,
      verticalAlignment: widget.verticalAlignment,
      runAlignment: widget.runAlignment,
      animate: widget.animate,
      duration: widget.duration,
      curve: widget.curve,
      strategy: widget.strategy,
      maxRows: widget.maxRows,
      vsync: this,
      children: widget.children,
    );
  }
}

class _RawFlexyWrap extends MultiChildRenderObjectWidget {
  final double horizontalSpacing;
  final double verticalSpacing;
  final WrapAlignment horizontalAlignment;
  final WrapCrossAlignment verticalAlignment;
  final WrapAlignment runAlignment;
  final bool animate;
  final Duration duration;
  final Curve curve;
  final FlexyWrapStrategy strategy;
  final int? maxRows;
  final TickerProvider vsync;

  const _RawFlexyWrap({
    required this.horizontalSpacing,
    required this.verticalSpacing,
    required this.horizontalAlignment,
    required this.verticalAlignment,
    required this.runAlignment,
    required this.animate,
    required this.duration,
    required this.curve,
    required this.strategy,
    this.maxRows,
    required this.vsync,
    required super.children,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderFlexyWrap(
      horizontalSpacing: horizontalSpacing,
      verticalSpacing: verticalSpacing,
      horizontalAlignment: horizontalAlignment,
      verticalAlignment: verticalAlignment,
      runAlignment: runAlignment,
      animate: animate,
      duration: duration,
      curve: curve,
      strategy: strategy,
      maxRows: maxRows,
      vsync: vsync,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderFlexyWrap renderObject) {
    renderObject
      ..horizontalSpacing = horizontalSpacing
      ..verticalSpacing = verticalSpacing
      ..horizontalAlignment = horizontalAlignment
      ..verticalAlignment = verticalAlignment
      ..runAlignment = runAlignment
      ..animate = animate
      ..duration = duration
      ..curve = curve
      ..strategy = strategy
      ..maxRows = maxRows
      ..vsync = vsync;
  }
}

class RenderFlexyWrap extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, FlexyParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, FlexyParentData> {
  RenderFlexyWrap({
    double horizontalSpacing = 8.0,
    double verticalSpacing = 8.0,
    WrapAlignment horizontalAlignment = WrapAlignment.start,
    WrapCrossAlignment verticalAlignment = WrapCrossAlignment.start,
    WrapAlignment runAlignment = WrapAlignment.start,
    bool animate = false,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    FlexyWrapStrategy strategy = FlexyWrapStrategy.balanced,
    int? maxRows,
    required TickerProvider vsync,
  }) : _horizontalSpacing = horizontalSpacing,
       _verticalSpacing = verticalSpacing,
       _horizontalAlignment = horizontalAlignment,
       _verticalAlignment = verticalAlignment,
       _runAlignment = runAlignment,
       _animate = animate,
       _duration = duration,
       _curve = curve,
       _strategy = strategy,
       _maxRows = maxRows,
       _vsync = vsync;

  AnimationController? _controller;

  double _horizontalSpacing;
  double get horizontalSpacing => _horizontalSpacing;
  set horizontalSpacing(double value) {
    if (_horizontalSpacing == value) return;
    _horizontalSpacing = value;
    markNeedsLayout();
  }

  double _verticalSpacing;
  double get verticalSpacing => _verticalSpacing;
  set verticalSpacing(double value) {
    if (_verticalSpacing == value) return;
    _verticalSpacing = value;
    markNeedsLayout();
  }

  WrapAlignment _horizontalAlignment;
  WrapAlignment get horizontalAlignment => _horizontalAlignment;
  set horizontalAlignment(WrapAlignment value) {
    if (_horizontalAlignment == value) return;
    _horizontalAlignment = value;
    markNeedsLayout();
  }

  WrapCrossAlignment _verticalAlignment;
  WrapCrossAlignment get verticalAlignment => _verticalAlignment;
  set verticalAlignment(WrapCrossAlignment value) {
    if (_verticalAlignment == value) return;
    _verticalAlignment = value;
    markNeedsLayout();
  }

  WrapAlignment _runAlignment;
  WrapAlignment get runAlignment => _runAlignment;
  set runAlignment(WrapAlignment value) {
    if (_runAlignment == value) return;
    _runAlignment = value;
    markNeedsLayout();
  }

  bool _animate;
  bool get animate => _animate;
  set animate(bool value) {
    if (_animate == value) return;
    _animate = value;
    markNeedsLayout();
  }

  FlexyWrapStrategy _strategy;
  FlexyWrapStrategy get strategy => _strategy;
  set strategy(FlexyWrapStrategy value) {
    if (_strategy == value) return;
    _strategy = value;
    markNeedsLayout();
  }

  int? _maxRows;
  int? get maxRows => _maxRows;
  set maxRows(int? value) {
    if (_maxRows == value) return;
    _maxRows = value;
    markNeedsLayout();
  }

  Duration _duration;
  Duration get duration => _duration;
  set duration(Duration value) {
    if (_duration == value) return;
    _duration = value;
    _controller?.duration = value;
  }

  Curve _curve;
  Curve get curve => _curve;
  set curve(Curve value) {
    if (_curve == value) return;
    _curve = value;
  }

  TickerProvider _vsync;
  TickerProvider get vsync => _vsync;
  set vsync(TickerProvider value) {
    if (_vsync == value) return;
    _vsync = value;
    if (_controller != null) {
      _controller!.resync(value);
    }
  }

  bool _isLayingOut = false;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _controller = AnimationController(vsync: vsync, duration: duration)
      ..addListener(() {
        if (!_isLayingOut) {
          markNeedsLayout();
        }
      });
  }

  @override
  void detach() {
    _controller?.dispose();
    _controller = null;
    super.detach();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! FlexyParentData) {
      child.parentData = FlexyParentData();
    }
  }

  Map<RenderBox, double> _calculateWidths(
    List<RenderBox> row,
    double extraWidthPerRow,
    double parentWidth,
  ) {
    Map<RenderBox, double> calculatedWidths = {};
    List<RenderBox> flexibleChildren = [];

    for (var c in row) {
      final parentData = c.parentData as FlexyParentData;
      double maxW = parentData.maxWidth ?? double.infinity;
      if (maxW > parentData.effectiveMinWidth) {
        flexibleChildren.add(c);
      } else {
        calculatedWidths[c] = parentData.effectiveMinWidth;
      }
    }

    // Sort flexible children by (headroom / minWidth) ascending
    flexibleChildren.sort((a, b) {
      final aData = a.parentData as FlexyParentData;
      final bData = b.parentData as FlexyParentData;

      final aMax = aData.maxWidth ?? double.infinity;
      final bMax = bData.maxWidth ?? double.infinity;

      final aMin = aData.effectiveMinWidth == 0
          ? 0.0001
          : aData.effectiveMinWidth;
      final bMin = bData.effectiveMinWidth == 0
          ? 0.0001
          : bData.effectiveMinWidth;

      final aRatio = (aMax - aMin) / aMin;
      final bRatio = (bMax - bMin) / bMin;
      return aRatio.compareTo(bRatio);
    });

    double unallocatedSpace = extraWidthPerRow;

    // Calculate total proportional weight
    double remainingWeight = flexibleChildren.fold(0.0, (sum, c) {
      double minW = (c.parentData as FlexyParentData).effectiveMinWidth;
      return sum + (minW == 0 ? 0.0001 : minW);
    });

    for (var c in flexibleChildren) {
      final parentData = c.parentData as FlexyParentData;
      double maxW = parentData.maxWidth ?? double.infinity;
      double headroom = maxW - parentData.effectiveMinWidth;

      double minW = parentData.effectiveMinWidth == 0
          ? 0.0001
          : parentData.effectiveMinWidth;

      double share = 0;
      if (remainingWeight > 0) {
        share = unallocatedSpace * (minW / remainingWeight);
      }

      double actualExtra = share < headroom ? share : headroom;
      calculatedWidths[c] = parentData.effectiveMinWidth + actualExtra;

      unallocatedSpace -= actualExtra;
      remainingWeight -= minW;
    }

    // Graceful squish for single-item rows that overflow
    if (row.length == 1) {
      RenderBox onlyChild = row.first;
      if (calculatedWidths[onlyChild]! > parentWidth) {
        calculatedWidths[onlyChild] = parentWidth;
      }
    }

    return calculatedWidths;
  }

  Map<RenderBox, double> _calculateSquishedWidths(
    List<RenderBox> row,
    double targetTotalWidth,
  ) {
    Map<RenderBox, double> widths = {};
    List<RenderBox> unlocked = List.from(row);
    double unallocatedSpace = targetTotalWidth;

    bool newlyLocked;
    do {
      newlyLocked = false;
      double unlockedTotalBase = unlocked.fold(
        0.0,
        (s, c) => s + (c.parentData as FlexyParentData).effectiveMinWidth,
      );

      if (unlockedTotalBase <= 0) {
        double evenShare = unallocatedSpace / unlocked.length;
        for (var c in unlocked) {
          final pd = c.parentData as FlexyParentData;
          double min = pd.minWidth ?? 0.0;
          widths[c] = min > evenShare ? min : evenShare;
        }
        break;
      }

      List<RenderBox> remainingUnlocked = [];

      for (var c in unlocked) {
        final pd = c.parentData as FlexyParentData;
        double minW = pd.minWidth ?? 0.0;
        double proposed =
            unallocatedSpace * (pd.effectiveMinWidth / unlockedTotalBase);

        if (proposed <= minW) {
          widths[c] = minW;
          unallocatedSpace -= minW;
          newlyLocked = true;
        } else {
          remainingUnlocked.add(c);
        }
      }
      unlocked = remainingUnlocked;
    } while (newlyLocked && unlocked.isNotEmpty);

    if (unlocked.isNotEmpty) {
      double unlockedTotalBase = unlocked.fold(
        0.0,
        (s, c) => s + (c.parentData as FlexyParentData).effectiveMinWidth,
      );
      for (var c in unlocked) {
        final pd = c.parentData as FlexyParentData;
        widths[c] =
            unallocatedSpace * (pd.effectiveMinWidth / unlockedTotalBase);
      }
    }

    return widths;
  }

  @override
  void performLayout() {
    _isLayingOut = true;
    try {
      if (childCount == 0) {
        size = constraints.biggest;
        return;
      }

      final parentWidth = constraints.maxWidth;
      List<RenderBox> childrenList = [];
      RenderBox? child = firstChild;
      while (child != null) {
        final pd = child.parentData as FlexyParentData;

        if (pd.baseWidth == null) {
          // getDryLayout is generally more performant than getMaxIntrinsicWidth
          pd._effectiveMinWidth = child
              .getDryLayout(const BoxConstraints())
              .width;
        }

        childrenList.add(child);
        child = pd.nextSibling;
      }

      List<List<RenderBox>> rows = _computeSmartRows(childrenList, parentWidth);

      if (maxRows != null && rows.length > maxRows!) {
        rows = _computeProportionalRows(childrenList, maxRows!);
      }

      _LayoutResult result = _computeLayoutMetrics(
        rows,
        parentWidth,
        constraints,
      );

      if (!animate || _controller == null) {
        for (var c in childrenList) {
          final pd = c.parentData as FlexyParentData;
          final rect = result.rects[c]!;
          pd.offset = rect.topLeft;
          pd.actualRect = rect;
        }
        size = constraints.constrainDimensions(parentWidth, result.height);
        return;
      }

      // --- ANIMATION LOGIC ---
      bool rowsChanged = false;
      for (var c in childrenList) {
        final pd = c.parentData as FlexyParentData;
        if (pd.targetRowIndex != result.rows[c]) {
          rowsChanged = true;
          break;
        }
      }

      if (rowsChanged) {
        for (var c in childrenList) {
          final pd = c.parentData as FlexyParentData;
          pd.oldRect = pd.actualRect ?? result.rects[c]!;
          pd.targetRect = result.rects[c]!;
          pd.targetRowIndex = result.rows[c]!;
        }
        _controller!.forward(from: 0);
      } else {
        for (var c in childrenList) {
          final pd = c.parentData as FlexyParentData;
          pd.targetRect = result.rects[c]!;
          pd.targetRowIndex = result.rows[c]!;
        }
      }

      // If the controller is not animating, the children are already laid out at
      // their final sizes in _computeLayoutMetrics, so we can early return.
      if (!_controller!.isAnimating) {
        for (var c in childrenList) {
          final pd = c.parentData as FlexyParentData;
          final rect = result.rects[c]!;
          pd.offset = rect.topLeft;
          pd.actualRect = rect;
        }
        size = constraints.constrainDimensions(parentWidth, result.height);
        return;
      }

      double t = _controller!.isAnimating ? _controller!.value : 1.0;
      t = curve.transform(t);

      double actualMaxY = 0;
      double actualMaxX = 0;

      for (var c in childrenList) {
        final pd = c.parentData as FlexyParentData;
        final oldRect = pd.oldRect!;
        final targetRect = pd.targetRect!;

        double actualW = lerpDouble(oldRect.width, targetRect.width, t)!;
        double actualX = lerpDouble(oldRect.left, targetRect.left, t)!;
        double actualY = lerpDouble(oldRect.top, targetRect.top, t)!;

        c.layout(BoxConstraints.tightFor(width: actualW), parentUsesSize: true);
        pd.offset = Offset(actualX, actualY);
        pd.actualRect = Rect.fromLTWH(actualX, actualY, actualW, c.size.height);

        if (actualY + c.size.height > actualMaxY) {
          actualMaxY = actualY + c.size.height;
        }
        if (actualX + actualW > actualMaxX) {
          actualMaxX = actualX + actualW;
        }
      }

      // Ensure the container bounds encompass both the animating bounds and the target bounds
      double finalConstrainedWidth = actualMaxX > result.width
          ? actualMaxX
          : result.width;
      double finalConstrainedHeight = actualMaxY > result.height
          ? actualMaxY
          : result.height;
      size = constraints.constrainDimensions(
        finalConstrainedWidth,
        finalConstrainedHeight,
      );
    } finally {
      _isLayingOut = false;
    }
  }

  _LayoutResult _computeLayoutMetrics(
    List<List<RenderBox>> rows,
    double parentWidth,
    BoxConstraints constraints,
  ) {
    Map<RenderBox, double> calculatedWidths = {};
    List<double> rowHeights = [];
    List<double> allocatedWidths = [];

    for (int i = 0; i < rows.length; i++) {
      final row = rows[i];
      double rowTotalMinWidth = row.fold(
        0.0,
        (sum, c) => sum + (c.parentData as FlexyParentData).effectiveMinWidth,
      );
      double requiredSpacing = horizontalSpacing * (row.length - 1);
      double extraWidthPerRow =
          parentWidth - rowTotalMinWidth - requiredSpacing;

      Map<RenderBox, double> rowWidths;
      if (extraWidthPerRow < 0) {
        double availableW = parentWidth - requiredSpacing;
        if (availableW < 0) availableW = 0;
        rowWidths = _calculateSquishedWidths(row, availableW);
      } else {
        rowWidths = _calculateWidths(row, extraWidthPerRow, parentWidth);
      }
      calculatedWidths.addAll(rowWidths);

      double rowMaxHeight = 0;
      double totalAllocatedWidth = 0;
      for (var c in row) {
        double targetW = rowWidths[c]!;
        c.layout(BoxConstraints.tightFor(width: targetW), parentUsesSize: true);
        if (c.size.height > rowMaxHeight) {
          rowMaxHeight = c.size.height;
        }
        totalAllocatedWidth += targetW;
      }
      totalAllocatedWidth += horizontalSpacing * (row.length - 1);

      rowHeights.add(rowMaxHeight);
      allocatedWidths.add(totalAllocatedWidth);
    }

    double totalRowsHeight = rowHeights.fold(0.0, (s, h) => s + h);
    if (rows.length > 1) totalRowsHeight += verticalSpacing * (rows.length - 1);

    double remainingHeight = constraints.hasBoundedHeight
        ? constraints.maxHeight - totalRowsHeight
        : 0;

    double currentY = 0;
    double stepY = verticalSpacing;
    if (remainingHeight > 0) {
      switch (runAlignment) {
        case WrapAlignment.start:
          break;
        case WrapAlignment.end:
          currentY = remainingHeight;
          break;
        case WrapAlignment.center:
          currentY = remainingHeight / 2.0;
          break;
        case WrapAlignment.spaceBetween:
          if (rows.length > 1) {
            stepY += remainingHeight / (rows.length - 1);
          }
          break;
        case WrapAlignment.spaceAround:
          double space = remainingHeight / rows.length;
          currentY = space / 2.0;
          stepY += space;
          break;
        case WrapAlignment.spaceEvenly:
          double space = remainingHeight / (rows.length + 1);
          currentY = space;
          stepY += space;
          break;
      }
    }

    double maxAllocatedWidth = allocatedWidths.isEmpty
        ? 0
        : allocatedWidths.reduce((a, b) => a > b ? a : b);

    double finalAllocatedWidth = constraints.constrainWidth(maxAllocatedWidth);

    Map<RenderBox, Rect> calculatedTargets = {};
    Map<RenderBox, int> calculatedRows = {};

    for (int i = 0; i < rows.length; i++) {
      final row = rows[i];
      double rowMaxHeight = rowHeights[i];
      double allocatedWidth = allocatedWidths[i];
      double remainingSpace = finalAllocatedWidth - allocatedWidth;

      double currentX = 0;
      double stepX = horizontalSpacing;

      if (remainingSpace > 0) {
        switch (horizontalAlignment) {
          case WrapAlignment.start:
            break;
          case WrapAlignment.end:
            currentX = remainingSpace;
            break;
          case WrapAlignment.center:
            currentX = remainingSpace / 2.0;
            break;
          case WrapAlignment.spaceBetween:
            if (row.length > 1) {
              stepX += remainingSpace / (row.length - 1);
            } else {
              currentX = remainingSpace / 2.0;
            }
            break;
          case WrapAlignment.spaceAround:
            double space = remainingSpace / row.length;
            currentX = space / 2.0;
            stepX += space;
            break;
          case WrapAlignment.spaceEvenly:
            double space = remainingSpace / (row.length + 1);
            currentX = space;
            stepX += space;
            break;
        }
      }

      for (var c in row) {
        double targetW = calculatedWidths[c]!;
        double targetH = c.size.height;
        double yOffset = 0;
        switch (verticalAlignment) {
          case WrapCrossAlignment.start:
            yOffset = 0;
            break;
          case WrapCrossAlignment.end:
            yOffset = rowMaxHeight - targetH;
            break;
          case WrapCrossAlignment.center:
            yOffset = (rowMaxHeight - targetH) / 2.0;
            break;
        }

        calculatedTargets[c] = Rect.fromLTWH(
          currentX,
          currentY + yOffset,
          targetW,
          targetH,
        );
        calculatedRows[c] = i;

        currentX += targetW + stepX;
      }
      currentY += rowMaxHeight + stepY;
    }

    double finalHeight = remainingHeight > 0
        ? constraints.maxHeight
        : totalRowsHeight;
    return _LayoutResult(
      calculatedTargets,
      calculatedRows,
      finalAllocatedWidth,
      finalHeight,
    );
  }

  List<List<RenderBox>> _computeProportionalRows(
    List<RenderBox> children,
    int maxRows,
  ) {
    if (children.isEmpty) return [];
    if (maxRows <= 1) return [children];

    double totalWidth = children.fold(
      0.0,
      (sum, c) => sum + (c.parentData as FlexyParentData).effectiveMinWidth,
    );

    List<List<RenderBox>> rows = [];
    List<RenderBox> currentRow = [];
    double currentRowWidth = 0;

    double targetRowWidth = totalWidth / maxRows;
    int remainingRows = maxRows;

    for (int i = 0; i < children.length; i++) {
      var c = children[i];
      double cWidth = (c.parentData as FlexyParentData).effectiveMinWidth;

      if (remainingRows == 1) {
        currentRow.add(c);
        continue;
      }

      if (currentRow.isNotEmpty &&
          (currentRowWidth + cWidth - targetRowWidth).abs() >
              (currentRowWidth - targetRowWidth).abs()) {
        rows.add(List.from(currentRow));
        remainingRows--;

        double remainingTotalWidth = 0;
        for (int j = i; j < children.length; j++) {
          remainingTotalWidth +=
              (children[j].parentData as FlexyParentData).effectiveMinWidth;
        }
        targetRowWidth = remainingTotalWidth / remainingRows;

        currentRow.clear();
        currentRow.add(c);
        currentRowWidth = cWidth;
      } else {
        currentRow.add(c);
        currentRowWidth += cWidth;
      }
    }
    if (currentRow.isNotEmpty) rows.add(currentRow);
    return rows;
  }

  List<List<RenderBox>> _computeSmartRows(
    List<RenderBox> children,
    double maxWidth,
  ) {
    if (strategy == FlexyWrapStrategy.greedy) {
      return _computeGreedyRows(children, maxWidth);
    }

    double totalMinWidth =
        children.fold(
          0.0,
          (sum, c) =>
              sum + (c.parentData as FlexyParentData).effectiveMinWidth,
        ) +
        (horizontalSpacing * (children.length - 1));

    if (totalMinWidth <= maxWidth || children.length == 1) {
      return [children];
    }

    int bestSplitIndex = 1;
    double smallestDiff = double.infinity;

    double totalItemWidth = children.fold(
      0.0,
      (sum, c) => sum + (c.parentData as FlexyParentData).effectiveMinWidth,
    );
    double currentLeftItemSum =
        (children[0].parentData as FlexyParentData).effectiveMinWidth;

    for (int i = 1; i < children.length; i++) {
      double leftSum = currentLeftItemSum + horizontalSpacing * (i - 1);
      double rightSum =
          (totalItemWidth - currentLeftItemSum) +
          horizontalSpacing * (children.length - i - 1);

      // Prevent breaks that cause the left row to overflow the max width,
      // unless we are forced to break after the first item.
      if (leftSum > maxWidth && i > 1) {
        currentLeftItemSum +=
            (children[i].parentData as FlexyParentData).effectiveMinWidth;
        continue;
      }

      double diff = (leftSum - rightSum).abs();

      // Incorporate user-defined break preferences to encourage/discourage splitting here
      FlexyBreakAfter breakAfter =
          (children[i - 1].parentData as FlexyParentData).breakAfter;
      if (breakAfter == FlexyBreakAfter.prefer) {
        diff -= 10000;
      } else if (breakAfter == FlexyBreakAfter.avoid) {
        diff += 10000;
      }

      if (diff < smallestDiff) {
        smallestDiff = diff;
        bestSplitIndex = i;
      }

      currentLeftItemSum +=
          (children[i].parentData as FlexyParentData).effectiveMinWidth;
    }

    List<RenderBox> row1 = children.sublist(0, bestSplitIndex);
    List<RenderBox> row2 = children.sublist(bestSplitIndex);

    double r1Width =
        row1.fold(
          0.0,
          (s, c) => s + (c.parentData as FlexyParentData).effectiveMinWidth,
        ) +
        horizontalSpacing * (row1.length - 1);
    double r2Width =
        row2.fold(
          0.0,
          (s, c) => s + (c.parentData as FlexyParentData).effectiveMinWidth,
        ) +
        horizontalSpacing * (row2.length - 1);

    if (r1Width <= maxWidth && r2Width <= maxWidth) {
      return [row1, row2];
    }

    return _computeGreedyRows(children, maxWidth);
  }

  List<List<RenderBox>> _computeGreedyRows(
    List<RenderBox> children,
    double maxWidth,
  ) {
    List<List<RenderBox>> runs = [];
    List<RenderBox> currentRun = [];
    double currentRunWidth = 0;

    for (var c in children) {
      double cWidth = (c.parentData as FlexyParentData).effectiveMinWidth;
      if (currentRun.isEmpty) {
        currentRun.add(c);
        currentRunWidth = cWidth;
      } else if (currentRunWidth + horizontalSpacing + cWidth <= maxWidth) {
        currentRun.add(c);
        currentRunWidth += horizontalSpacing + cWidth;
      } else {
        runs.add(List.from(currentRun));
        currentRun.clear();
        currentRun.add(c);
        currentRunWidth = cWidth;
      }
    }
    if (currentRun.isNotEmpty) runs.add(currentRun);
    return runs;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    RenderBox? child = firstChild;
    while (child != null) {
      final pd = child.parentData as FlexyParentData;
      context.paintChild(child, pd.offset + offset);
      child = pd.nextSibling;
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    RenderBox? child = lastChild;
    while (child != null) {
      final pd = child.parentData as FlexyParentData;
      final bool isHit = result.addWithPaintOffset(
        offset: pd.offset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          return child!.hitTest(result, position: transformed);
        },
      );
      if (isHit) return true;
      child = pd.previousSibling;
    }
    return false;
  }
}

class _LayoutResult {
  final Map<RenderBox, Rect> rects;
  final Map<RenderBox, int> rows;
  final double width;
  final double height;

  _LayoutResult(this.rects, this.rows, this.width, this.height);
}
