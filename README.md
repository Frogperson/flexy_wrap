# FlexyWrap

A flexible, animated `Wrap` widget for Flutter.

`FlexyWrap` is a layout widget that displays its children in multiple rows. It provides an alternative to Flutter's standard `Wrap` with support for layout animations, proportional spacing, and different line-breaking algorithms.

## Features


* **Proportional expansion**: Using the `Flexy` widget, children can be assigned a `baseWidth` and `maxWidth`. Unallocated horizontal space in a row is distributed proportionally among flexible children based on their `baseWidth`.
* **Line breaking algorithms**: Choose between `FlexyWrapStrategy.balanced` (attempts to minimize ragged edges across all rows) or `FlexyWrapStrategy.greedy` (packs as many items into a row as possible).
* **Animations**: Implicitly animates changes to layout constraints, spacing, alignment, and child counts.

## Usage

Use `FlexyWrap` just as you would use a standard `Wrap` widget. To define custom scaling behavior for specific children, wrap them in a `Flexy` widget.

```dart
import 'package:flexy_wrap/flexy_wrap.dart';

FlexyWrap(
  horizontalSpacing: 10.0,
  verticalSpacing: 10.0,
  children: [
    // A standard widget without a Flexy wrapper.
    // By default, it will use its intrinsic width as its flex weight and WILL 
    // expand indefinitely to fill extra space (equivalent to maxWidth: null).
    Container(
      color: Colors.purple,
      width: 100,
      height: 100,
    ),
    
    // A flexible item that starts at 200 width but can grow up to 400.
    Flexy(
      baseWidth: 200, 
      maxWidth: 400,
      child: Container(color: Colors.blue, height: 100),
    ),
    
    // A flexible item with no max width. It will grow indefinitely to fill the row.
    Flexy(
      baseWidth: 300,
      child: Container(color: Colors.green, height: 100),
    ),
    
    // Setting maxWidth equal to (or less than) baseWidth enforces a strict, non-flexible size.
    Flexy(
      baseWidth: 150,
      maxWidth: 150, 
      child: Container(color: Colors.red, height: 100),
    ),
  ],
)
```

## `FlexyWrap` Properties

| Property | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `children` | `List<Widget>` | **Required** | The widgets to display. Wrap them in `Flexy` to enable flexible sizing. |
| `maxRows` | `int?` | `null` | The maximum number of rows to display. If exceeded, items are grouped evenly and squished proportionally to fit the bounds. |
| `strategy` | `FlexyWrapStrategy` | `.balanced` | The algorithm used to determine line breaks (`.balanced` or `.greedy`). |
| `horizontalSpacing` | `double` | `8.0` | Horizontal space between children. |
| `verticalSpacing` | `double` | `8.0` | Vertical space between rows. |
| `horizontalAlignment` | `WrapAlignment` | `.start` | Main axis alignment for children within a row. |
| `verticalAlignment` | `WrapCrossAlignment` | `.start` | Cross axis alignment for children within a row. |
| `runAlignment` | `WrapAlignment` | `.start` | Cross axis alignment for the rows themselves. |
| `animate` | `bool` | `true` | Whether to animate layout changes. |
| `duration` | `Duration` | `200ms` | The duration of the layout animation. |
| `curve` | `Curve` | `Curves.easeInOut` | The easing curve of the layout animation. |

## `Flexy` Properties

The `Flexy` widget configures how individual children are sized and when they break to a new line.

| Property | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `child` | `Widget` | **Required** | The widget to display. |
| `baseWidth` | `double?` | `null` | The target minimum width required before wrapping to the next line. Also acts as the flex weight when distributing extra space. If `null`, defaults to the child's intrinsic width. |
| `minWidth` | `double?` | `null` | The absolute minimum width constraint. Prevents the child from squishing smaller than this value when restricted by `maxRows`. |
| `maxWidth` | `double?` | `null` | The maximum width the child can expand to. If set and greater than `baseWidth`, the child becomes flexible. If `null`, it can grow indefinitely. |
| `breakAfter` | `FlexyBreakAfter` | `.auto` | Used by the `.balanced` strategy. `.prefer` encourages a line break after this item; `.avoid` discourages it. |
