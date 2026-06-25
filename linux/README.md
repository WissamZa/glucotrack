# Linux Desktop Support

GlucoTrack can be built for Linux desktop using Flutter. However, the following features are NOT available on Linux:

- **BLE Sync** — `flutter_blue_plus` does not support Linux. Use the Android or iOS app to sync your OneTouch meter.

## Building

```bash
flutter pub get
flutter build linux --release
```

The built binary will be in `build/linux/x64/release/bundle/`.
