# dondon_live_coding

## Getting Started

`flutter_scene` requires flutter master channel

### Before debugging

```bash
$ flutter channel master
$ flutter upgrade
$ export FLUTTER_DART_DATA_ASSETS=true # one-time setup
$ flutter config --enable-native-assets # one-time setup
$ flutter config --enable-dart-data-assets # one-time setup
$ flutter pub get
```

### Running the app

```bash
$ flutter run -d macos --enable-flutter-gpu --enable-impeller
```

Or use VSCode `launch.json` file to run any of the defined configuration and use hot reload.

## Assets

- Textures
  - TeamLab logo
- Models
  - nonkus https://sketchfab.com/3d-models/nonkus-179e65f8cb424921af7723a841f2fe42
