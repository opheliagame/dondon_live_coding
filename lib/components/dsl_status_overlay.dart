// Architecture: component layer — draw-only status widget.
//
// The stage owns status/error state and passes it to this overlay for display.
// Keeping it separate avoids coupling diagnostics UI to scene ownership.

import 'package:dondon_live_coding/core/dsl_result.dart';
import 'package:flutter/material.dart';

class DslStatusOverlay extends StatelessWidget {
  const DslStatusOverlay({
    required this.status,
    required this.error,
    super.key,
  });

  final String status;
  final DslError? error;

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          hasError
              ? 'DSL error: ${error!.message}\nStill showing: $status'
              : 'SceneView shape: $status\nEdit circleScriptSource in lib/core/dsl.dart and hot reload.',
          style: TextStyle(
            color: hasError ? Colors.orangeAccent : Colors.white,
          ),
        ),
      ),
    );
  }
}
