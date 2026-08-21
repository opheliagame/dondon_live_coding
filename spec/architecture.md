# dondon_live_coding Architecture

## Purpose

This app renders live-coded shapes from a DSL into a Flutter Scene view.
The design is intentionally split into three layers so each concern stays isolated:

1. Component layer: draw-only widgets
2. Runtime layer: DSL evaluation plus shape-to-widget mapping
3. Stage layer: scene ownership, state, and error policy

## Layer Model

### 1) Component layer (dumb components)

Location:

- lib/components/circle_component.dart
- lib/components/rect_component.dart
- lib/components/dsl_status_overlay.dart

Responsibilities:

- Receive prepared data from higher layers
- Render visuals only
- Choose camera framing per shape view

Non-responsibilities:

- No DSL parsing
- No interpreter calls
- No scene mutation policy

Key rule:

- Components do not decide what to render from source text. They only render what they are given.

### 2) Runtime layer (mapping and evaluation)

Location:

- lib/runtime/dsl_runtime.dart

Responsibilities:

- Evaluate source through the DSL pipeline
- Package successful output as DslFrame
- Map ShapeType to a component factory via registry

Types:

- DslFrame = ShapeCommand + Node
- DslRuntime with:
  - evaluate(source) -> DslResult<DslFrame>
  - componentFor(frame, scene) -> Widget

Pipeline inside evaluate:

1. runCircleScript(source)
2. ShapeCommand.parse(commandString)
3. DslInterpreter.interpret(command)
4. Return DslFrame on success

Registry policy:

- ShapeType to component mapping is constructor-injected for testability and swapability.
- Default registry currently maps:
  - circle -> CircleComponent
  - rect -> RectComponent

Architectural boundary:

- Core stays widget-free.
- Runtime is the adapter that imports both core pipeline and UI components.

### 3) Stage layer (scene owner)

Location:

- lib/runtime/dsl_stage.dart

Responsibilities:

- Own the single Scene instance
- Trigger evaluation on initState and reassemble
- Apply successful frames to Scene
- Preserve last-known-good scene on failures
- Compose mapped component and status overlay

State held by stage:

- Scene \_scene
- DslFrame? \_frame
- DslError? \_error
- String \_status

Last-known-good policy:

- On error, stage updates error state only.
- Stage does not clear or mutate scene on failed evaluation.
- Previous valid frame remains visible while overlay shows the error.

## Core DSL Pipeline (unchanged)

Locations:

- lib/core/dsl.dart
- lib/core/interpreter.dart
- lib/core/dsl_result.dart

Flow:

1. DScript source is analyzed and executed in sandboxed runtime
2. Script returns a shape command string
3. ShapeCommand.parse builds IR (ShapeType + numeric args)
4. ShapeCommandInterpreter produces flutter_scene Node
5. Errors are carried with DslResult instead of thrown exceptions

Error strategy:

- Invalid user DSL input is expected, not exceptional.
- Failures return DslResult with FIFO error queue semantics.
- UI surfaces first error without crashing or blanking the stage.

## App Shell

Location:

- lib/main.dart

Responsibilities:

- Configure logging
- Initialize Scene static resources
- Mount DslStage

Rule:

- main.dart remains boot + mount only.

## End-to-End Rendering Sequence

1. App starts and mounts DslStage
2. DslStage asks DslRuntime to evaluate source
3. Runtime executes DSL pipeline and returns DslFrame or errors
4. On success, stage replaces scene contents with new frame node
5. Stage asks runtime for the component mapped to frame.command.type
6. Component renders SceneView with its camera framing
7. Overlay displays either status or error details

## Dependency Direction

- lib/core has no Flutter widget dependencies
- lib/components depends on Flutter and flutter_scene only
- lib/runtime depends on core plus components
- lib/main depends on runtime

This keeps domain logic and UI composition decoupled.

## Invariants

1. There is only one stateful scene owner: DslStage.
2. Components are render-only and stateless.
3. Runtime evaluation returns DslResult, never throws for user DSL mistakes.
4. Failed evaluations never mutate the currently visible scene.
5. ShapeType mapping stays in runtime, not core.

## Extending with a New Shape

To add a new shape, update each layer in order:

1. Core:

- Add new ShapeType value
- Extend parser/interpreter behavior

2. Components:

- Add a new draw-only component for that shape's framing

3. Runtime:

- Add new ShapeType entry in registry

4. Stage:

- No changes expected if contracts are preserved

5. Validation:

- Run dart analyze lib test
- Run flutter test
- Manual hot reload check in flutter run for valid and invalid DSL input

## Testing Strategy

Automated:

- Runtime tests should use injected fake DslInterpreter implementations when possible.
- Avoid GPU-dependent flutter_scene geometry creation in headless test mode.

Manual:

- Use flutter run for scene and camera verification.
- Confirm last-known-good behavior by introducing invalid DSL input and hot reloading.
