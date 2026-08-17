// Architecture: host layer — app shell and live-coding editor host.
//
// Boots Flutter Scene resources and mounts a UI host that edits DSL source.
// The host keeps draft text local, commits it on keyboard action, and passes
// committed source to DslStage. DslStage remains the sole scene owner.

import 'package:dondon_live_coding/core/dsl.dart';
import 'package:dondon_live_coding/core/logger.dart';
import 'package:dondon_live_coding/runtime/dsl_stage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_scene/scene.dart';

final _log = AppLogger.get('app.main');

void main() async {
  AppLogger.configure();
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Scene.initializeStaticResources();
  } catch (e) {
    if (kDebugMode) {
      _log.severe('Failed to initialize Flutter Scene resources', e);
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        // traditional live coding background color is black, so keeping that for now
        backgroundColor: Colors.black,
        body: SafeArea(child: DslLiveCodingHost()),
      ),
    );
  }
}

class _ApplyScriptIntent extends Intent {
  const _ApplyScriptIntent();
}

class DslLiveCodingHost extends StatefulWidget {
  const DslLiveCodingHost({super.key});

  @override
  State<DslLiveCodingHost> createState() => _DslLiveCodingHostState();
}

class _DslLiveCodingHostState extends State<DslLiveCodingHost> {
  late final TextEditingController _controller;
  late String _draftSource;
  late String _committedSource;

  @override
  void initState() {
    super.initState();
    _draftSource = circleScriptSource;
    _committedSource = circleScriptSource;
    _controller = TextEditingController(text: _draftSource);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _commitDraft() {
    if (_committedSource == _draftSource) {
      return;
    }

    setState(() {
      _committedSource = _draftSource;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter, meta: true):
            _ApplyScriptIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _ApplyScriptIntent: CallbackAction<_ApplyScriptIntent>(
            onInvoke: (_) {
              _commitDraft();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Flexible(
                flex: 1,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF101010),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF2B2B2B)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'DSL Script (Cmd / Ctrl + Enter to apply)',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                          TextButton(
                            onPressed: _commitDraft,
                            child: const Text('Apply'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          onChanged: (value) {
                            _draftSource = value;
                          },
                          maxLines: null,
                          expands: true,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'monospace',
                            height: 1.35,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Write DSL here...',
                            hintStyle: TextStyle(color: Colors.white38),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Flexible(flex: 2, child: DslStage(source: _committedSource)),
            ],
          ),
        ),
      ),
    );
  }
}
