# DSL Design Document

## Goals

- be able to explore all the features of flutter_gpu and flutter_scene
- be able to change shaders on the fly
- simple and easy to write during a performance
- powerful and dynamic like hydra

## Inspiration

- https://github.com/hydra-synth/hydra
- https://gitlab.com/unlessgames/mumux

# Functionality

- load image
- load model
- show image
- show model
- load shader
- use shader

# Implementation details

Define API using [Dscript](https://github.com/mcquenji/dscript)

Why dscript Works Well for a Hydra-like Engine
Hydra relies on a Domain-Specific Language (DSL). Users aren't writing full JavaScript apps; they are using a custom, high-level API designed strictly for visual pipelines.

dscript matches this paradigm well:

Safety During Live Performances:
In live coding, you execute code in real-time while a loop/render frame is running. If a user writes an infinite loop in raw Dart, your whole app crashes mid-show. dscript runs inside a controlled VM/interpreter, allowing you to catch errors or sandbox execution safely.

Method-Chaining Syntax:
You can define a contract in Flutter that exposes visual primitives (e.g., osc(), kaleid(), rotate(), blend()). dscript compiles or interprets these commands into Dart calls that feed directly into your rendering loop (like CustomPainter, WebGL/Impeller, or Shaders).

No Heavy Dart Compiler Needed:
Instead of compiling full Flutter apps on the fly, dscript offers a lightweight parser and runtime designed specifically to evaluate custom scripting blocks instantly.

How It Would Work in Practice
Step 1: Define Your Visual "Contract" in Flutter
You build the engine in Flutter (using Fragment Shaders or CustomPainter) and expose your functions to dscript:

Dart
// Expose your visual engine to dscript
final visualContract = contract('VisualEngine')
.impl('osc', returnType: PrimitiveType.OBJECT)
.param('frequency', PrimitiveType.NUMBER)
.impl('rotate', returnType: PrimitiveType.OBJECT)
.param('angle', PrimitiveType.NUMBER)
.impl('out', returnType: PrimitiveType.VOID)
.build();
Step 2: The User Live-Codes in Your UI
The live coder types dscript expressions into a text box overlaid on your visual canvas:

Code snippet
// User's live script
osc(40.0).rotate(0.5).out();
Step 3: Parse and Pipe to Shaders
When the user hits Shift + Enter (or as they type), dscript parses the string, validates the arguments, and calls your underlying Flutter shader or canvas pipeline to update the visuals dynamically.
