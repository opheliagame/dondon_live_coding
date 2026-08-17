// Architecture: stage layer — stateful scene owner and last-known-good policy.
//
// The stage is the only stateful widget in this feature: it owns Scene,
// triggers runtime evaluation, applies successful frames, and keeps the scene
// untouched on failures while surfacing the oldest error in the overlay.

import 'package:dondon_live_coding/components/dsl_status_overlay.dart';
import 'package:dondon_live_coding/core/dsl.dart';
import 'package:dondon_live_coding/core/dsl_result.dart';
import 'package:dondon_live_coding/core/logger.dart';
import 'package:dondon_live_coding/runtime/dsl_runtime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_scene/scene.dart';

final _log = AppLogger.get('app.runtime.dsl_stage');

class DslStage extends StatefulWidget {
  const DslStage({super.key, DslRuntime? runtime, this.source})
    : _runtime = runtime;

  final DslRuntime? _runtime;
  final String? source;

  @override
  State<DslStage> createState() => _DslStageState();
}

class _DslStageState extends State<DslStage> {
  final Scene _scene = Scene();
  late final DslRuntime _runtime;

  DslFrame? _frame;
  DslError? _error;
  String _status = 'none';

  @override
  void initState() {
    super.initState();
    _runtime = widget._runtime ?? DslRuntime();
    _evaluateAndApply();
  }

  @override
  void reassemble() {
    super.reassemble();
    _evaluateAndApply();
  }

  @override
  void didUpdateWidget(covariant DslStage oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldSource = oldWidget.source ?? circleScriptSource;
    final nextSource = widget.source ?? circleScriptSource;
    if (oldSource != nextSource) {
      _evaluateAndApply();
    }
  }

  Future<void> _evaluateAndApply() async {
    final frameResult = await _runtime.evaluate(
      widget.source ?? circleScriptSource,
    );
    if (_reportIfFailed(frameResult)) {
      return;
    }

    final frame = frameResult.value;
    if (frame == null) {
      return;
    }

    _scene.removeAll();
    _scene.add(frame.node);

    if (!mounted) {
      return;
    }

    setState(() {
      _frame = frame;
      _status = '${frame.command}';
      _error = null;
    });
  }

  bool _reportIfFailed(DslResult<Object?> result) {
    final error = result.firstError;
    if (error == null) {
      return false;
    }

    _log.severe('DSL error: $error');
    if (mounted) {
      setState(() {
        _error = error;
      });
    }

    return true;
  }

  @override
  void dispose() {
    _scene.removeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = _frame == null
        ? const SizedBox.expand()
        : _runtime.componentFor(_frame!, _scene);

    return Stack(
      children: [
        content,
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: DslStatusOverlay(status: _status, error: _error),
        ),
      ],
    );
  }
}
