# Linux desktop build — GlucoTrack

This directory contains the Linux desktop runner for GlucoTrack. The app runs
on any modern Linux distribution with Flutter 3.27+ and the system
dependencies listed below.

## System requirements

- **Flutter SDK 3.27+** with Linux desktop support enabled
  (`flutter config --enable-linux-desktop`)
- **GTK 3** development headers
- **BlueZ 5.55+** and **D-Bus** (required by `flutter_blue_plus` for BLE sync)
- **libbluetooth-dev** (for native BLE access)

## Install dependencies

### Debian / Ubuntu / Mint
```bash
sudo apt update
sudo apt install clang cmake ninja-build pkg-config \
                 libgtk-3-dev liblzma-dev libstdc++-12-dev \
                 bluez bluez-tools libbluetooth-dev libdbus-1-dev
```

### Fedora
```bash
sudo dnf install clang cmake ninja-build pkg-config \
                 gtk3-devel \
                 bluez bluez-tools bluez-libs-devel dbus-devel
```

### Arch Linux
```bash
sudo pacman -S clang cmake ninja pkgconf \
                 gtk3 \
                 bluez bluez-utils dbus
```

## Enable the Bluetooth service

```bash
sudo systemctl enable --now bluetooth
```

Verify it's running:

```bash
systemctl status bluetooth
```

You should see `active (running)`. If not, check the journal:

```bash
journalctl -u bluetooth -n 50
```

## Build & run

```bash
# From the project root
flutter pub get
flutter run -d linux
```

For a release build:

```bash
flutter build linux --release
# Binary is at build/linux/x64/release/bundle/glucotrack
```

## D-Bus permissions

If you see errors like `Failed to connect to D-Bus` or
`Operation not permitted` when the app tries to scan for BLE devices:

1. Make sure your user is in the `bluetooth` group:
   ```bash
   sudo usermod -aG bluetooth $USER
   # Log out and back in for the change to take effect
   ```

2. If that's not enough, you may need to grant the app broader D-Bus access
   via a polkit rule. Create
   `/etc/polkit-1/rules.d/50-bluetooth-ble.rules`:
   ```javascript
   polkit.addRule(function(action, subject) {
       if (action.id == "org.bluez.adapter.set-powered" ||
           action.id == "org.bluez.adapter.start-discovery" ||
           action.id == "org.bluez.adapter.stop-discovery") {
           return polkit.Result.YES;
       }
   });
   ```

3. Restart polkit:
   ```bash
   sudo systemctl restart polkit
   ```

## BLE sync on Linux

The OneTouch Select Plus Flex uses random private BLE addresses that change
on every re-pair. BlueZ 5.55+ handles this correctly; older versions will
fail to maintain a stable connection.

To verify your BlueZ version:

```bash
bluetoothctl --version
```

For the BLE sync flow itself, see the main
[README's BLE section](../README.md#-ble-meter-sync-onetouch-select-plus-flex)
and the [protocol spec](../docs/BLE_PROTOCOL.md).

## Troubleshooting

### `flutter_blue_plus` plugin not found at build time

Make sure `flutter pub get` ran successfully and that the Linux desktop
target is enabled:

```bash
flutter config --enable-linux-desktop
flutter pub get
```

### App starts but Bluetooth scan finds nothing

1. Verify Bluetooth is on:
   ```bash
   bluetoothctl show
   # Look for "Powered: yes"
   ```
2. Put the meter into pairing mode (OK button, then ▲ + ▼).
3. Try scanning from `bluetoothctl` first to verify BlueZ can see the meter:
   ```bash
   bluetoothctl
   [bluetooth]# scan on
   # Look for "OneTouch ..." in the output
   [bluetooth]# scan off
   ```

### Meter pairs but GlucoTrack can't connect

The meter uses random private BLE addresses. After pairing, the meter may
re-roll its address on the next power cycle. To fix:

1. Remove the meter from BlueZ's known devices:
   ```bash
   bluetoothctl remove <MAC>
   ```
2. Put the meter back into pairing mode and re-pair from within GlucoTrack.

### `D-Bus connection failed: No such file or directory`

The system D-Bus socket isn't where the app expects it. Check:

```bash
ls -la /run/dbus/system_bus_socket
# Should exist; if not:
sudo dbus-uuidgen --ensure
sudo systemctl restart dbus
```
