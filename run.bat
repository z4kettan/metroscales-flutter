@echo off
REM Runs the app against the API set in config.json (copy config.example.json first).
if not exist config.json copy config.example.json config.json
flutter run --dart-define-from-file=config.json %*
