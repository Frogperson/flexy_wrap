import 'package:flutter/material.dart';
import 'package:flexy_wrap/flexy_wrap.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlexyWrap Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const FlexyWrapExamplePage(),
    );
  }
}

class InteractiveFlexyItem extends StatefulWidget {
  final double initialBaseWidth;
  final double? initialMinWidth;
  final double? initialMaxWidth;
  final Color color;

  const InteractiveFlexyItem({
    super.key,
    required this.initialBaseWidth,
    this.initialMinWidth,
    this.initialMaxWidth,
    required this.color,
  });

  @override
  State<InteractiveFlexyItem> createState() => _InteractiveFlexyItemState();
}

class _InteractiveFlexyItemState extends State<InteractiveFlexyItem> {
  late double baseWidth;
  late double? minWidth;
  late double? maxWidth;
  FlexyBreakAfter breakAfter = FlexyBreakAfter.auto;

  @override
  void initState() {
    super.initState();
    baseWidth = widget.initialBaseWidth;
    minWidth = widget.initialMinWidth;
    maxWidth = widget.initialMaxWidth;
  }

  void _editValues() {
    final dialogBaseController = TextEditingController(
      text: baseWidth.toInt().toString(),
    );
    final dialogMinController = TextEditingController(
      text: minWidth == null ? '' : minWidth!.toInt().toString(),
    );
    final dialogMaxController = TextEditingController(
      text: maxWidth == null ? 'inf' : maxWidth!.toInt().toString(),
    );
    FlexyBreakAfter dialogBreakAfter = breakAfter;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Constraints'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: dialogBaseController,
                    decoration: const InputDecoration(labelText: 'Base Width'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: dialogMinController,
                    decoration: const InputDecoration(labelText: 'Min Width (optional)'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: dialogMaxController,
                    decoration: const InputDecoration(
                      labelText: 'Max Width (or "inf")',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Break After: '),
                      const SizedBox(width: 8),
                      DropdownButton<FlexyBreakAfter>(
                        value: dialogBreakAfter,
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => dialogBreakAfter = val);
                          }
                        },
                        items: FlexyBreakAfter.values.map((s) {
                          return DropdownMenuItem(value: s, child: Text(s.name));
                        }).toList(),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      baseWidth =
                          double.tryParse(dialogBaseController.text) ?? baseWidth;
                      if (dialogMinController.text.trim().isEmpty) {
                        minWidth = null;
                      } else {
                        minWidth =
                            double.tryParse(dialogMinController.text) ?? minWidth;
                      }
                      if (dialogMaxController.text.toLowerCase() == 'inf' ||
                          dialogMaxController.text.trim().isEmpty) {
                        maxWidth = null;
                      } else {
                        maxWidth =
                            double.tryParse(dialogMaxController.text) ?? maxWidth;
                      }
                      breakAfter = dialogBreakAfter;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Flexy(
      baseWidth: baseWidth,
      minWidth: minWidth,
      maxWidth: maxWidth,
      breakAfter: breakAfter,
      child: Material(
        color: widget.color,
        child: InkWell(
          onTap: _editValues,
          child: Container(
            height: 120,
            padding: const EdgeInsets.all(8),
            child: Stack(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('base: ${baseWidth.toInt()}'),
                    const SizedBox(height: 4),
                    if (minWidth != null) ...[
                      Text('min: ${minWidth!.toInt()}'),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      'max: ${maxWidth == null ? "inf" : maxWidth!.toInt()}',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'break: ${breakAfter.name}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const Positioned(
                  top: 0,
                  right: 0,
                  child: Icon(Icons.edit, size: 16, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FlexyWrapExamplePage extends StatefulWidget {
  const FlexyWrapExamplePage({super.key});

  @override
  State<FlexyWrapExamplePage> createState() => _FlexyWrapExamplePageState();
}

class _FlexyWrapExamplePageState extends State<FlexyWrapExamplePage> {
  bool _animate = true;
  FlexyWrapStrategy _strategy = FlexyWrapStrategy.balanced;
  int _durationMs = 300;
  int? _maxRows;
  Curve _curve = Curves.easeInOut;
  WrapAlignment _horizontalAlignment = WrapAlignment.start;
  WrapCrossAlignment _verticalAlignment = WrapCrossAlignment.start;
  WrapAlignment _runAlignment = WrapAlignment.start;

  late final TextEditingController _durationController;
  late final TextEditingController _maxRowsController;

  @override
  void initState() {
    super.initState();
    _durationController = TextEditingController(text: '$_durationMs');
    _maxRowsController = TextEditingController(text: _maxRows?.toString() ?? '');
  }

  @override
  void dispose() {
    _durationController.dispose();
    _maxRowsController.dispose();
    super.dispose();
  }

  final Map<String, Curve> _curveMap = {
    'easeInOut': Curves.easeInOut,
    'linear': Curves.linear,
    'bounceOut': Curves.bounceOut,
    'elasticOut': Curves.elasticOut,
    'fastOutSlowIn': Curves.fastOutSlowIn,
  };

  Widget _buildFlexyItem({
    required double baseWidth,
    double? minWidth,
    double? maxWidth,
    required Color color,
  }) {
    return InteractiveFlexyItem(
      initialBaseWidth: baseWidth,
      initialMinWidth: minWidth,
      initialMaxWidth: maxWidth,
      color: color,
    );
  }

  Widget _buildLayoutSection(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FlexyWrap(
            horizontalSpacing: 8,
            verticalSpacing: 8,
            horizontalAlignment: _horizontalAlignment,
            verticalAlignment: _verticalAlignment,
            runAlignment: _runAlignment,
            animate: _animate,
            maxRows: _maxRows,
            duration: Duration(milliseconds: _durationMs),
            curve: _curve,
            strategy: _strategy,
            children: children,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FlexyWrap Example'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey.shade100,
            child: Wrap(
              spacing: 24,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Animations: '),
                    Switch(
                      value: _animate,
                      onChanged: (val) => setState(() => _animate = val),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Speed (ms): '),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 60,
                      child: TextField(
                        controller: _durationController,
                        enabled: _animate,
                        keyboardType: TextInputType.number,
                        onChanged: (val) {
                          int? parsed = int.tryParse(val);
                          if (parsed != null && parsed >= 0) {
                            setState(() => _durationMs = parsed);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Curve: '),
                    const SizedBox(width: 8),
                    DropdownButton<Curve>(
                      value: _curve,
                      onChanged: _animate
                          ? (val) {
                              if (val != null) setState(() => _curve = val);
                            }
                          : null,
                      items: _curveMap.entries.map((e) {
                        return DropdownMenuItem(
                          value: e.value,
                          child: Text(e.key),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Strategy: '),
                    const SizedBox(width: 8),
                    DropdownButton<FlexyWrapStrategy>(
                      value: _strategy,
                      onChanged: (val) {
                        if (val != null) setState(() => _strategy = val);
                      },
                      items: FlexyWrapStrategy.values.map((s) {
                        return DropdownMenuItem(value: s, child: Text(s.name));
                      }).toList(),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Horizontal: '),
                    const SizedBox(width: 8),
                    DropdownButton<WrapAlignment>(
                      value: _horizontalAlignment,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _horizontalAlignment = val);
                        }
                      },
                      items: WrapAlignment.values.map((s) {
                        return DropdownMenuItem(value: s, child: Text(s.name));
                      }).toList(),
                    ),
                  ],
                ),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Max Rows: '),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 60,
                      child: TextField(
                        controller: _maxRowsController,
                        keyboardType: TextInputType.number,
                        onChanged: (val) {
                          if (val.trim().isEmpty) {
                            setState(() => _maxRows = null);
                            return;
                          }
                          int? parsed = int.tryParse(val);
                          if (parsed != null && parsed >= 1) {
                            setState(() => _maxRows = parsed);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildLayoutSection([
                    _buildFlexyItem(
                      baseWidth: 100,
                      color: Colors.indigo.shade200,
                    ),
                    _buildFlexyItem(
                      baseWidth: 200,
                      color: Colors.lime.shade200,
                    ),
                    _buildFlexyItem(
                      baseWidth: 400,
                      color: Colors.cyan.shade200,
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildLayoutSection([
                    _buildFlexyItem(
                      baseWidth: 400,
                      color: Colors.brown.shade200,
                    ),
                    _buildFlexyItem(
                      baseWidth: 200,
                      color: Colors.deepOrange.shade200,
                    ),
                    _buildFlexyItem(
                      baseWidth: 100,
                      color: Colors.grey.shade400,
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildLayoutSection([
                    _buildFlexyItem(
                      baseWidth: 400,
                      color: Colors.blue.shade200,
                    ),
                    _buildFlexyItem(
                      baseWidth: 200,
                      maxWidth: 200,
                      color: Colors.green.shade200,
                    ),
                    _buildFlexyItem(
                      baseWidth: 200,
                      maxWidth: 200,
                      color: Colors.orange.shade200,
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildLayoutSection([
                    for (int i = 0; i < 6; i++)
                      _buildFlexyItem(
                        baseWidth: 250,
                        color: Colors.purple.shade200,
                      ),
                  ]),
                  const SizedBox(height: 24),
                  _buildLayoutSection([
                    _buildFlexyItem(baseWidth: 300, color: Colors.red.shade200),
                    _buildFlexyItem(
                      baseWidth: 300,
                      color: Colors.teal.shade200,
                    ),
                    _buildFlexyItem(
                      baseWidth: 150,
                      maxWidth: 150,
                      color: Colors.amber.shade200,
                    ),
                    _buildFlexyItem(
                      baseWidth: 200,
                      maxWidth: 400,
                      color: Colors.pink.shade200,
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

