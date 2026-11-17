# TetherKit Auto-Connect for macOS

Automatically connect your Mac to the internet as soon as you plug in an Android phone with USB tethering enabled. Uses `tetherkit-cli`, a background auto-detection script, and a macOS `LaunchDaemon` orchestrated by a single CMake script.

## Prerequisites
- macOS (Apple Silicon or Intel)
- [Homebrew](https://brew.sh) installed
- CMake installed (`brew install cmake`)

## Step 1: Enable Automatic USB Tethering on Android
To make tethering completely hands-free when plugging in your phone:
1. Open **Settings > About phone** and tap **Build number** 7 times to unlock Developer Options.
2. Go to **Settings > System > Developer options**.
3. Tap **Default USB configuration** and select **USB tethering**.

## Step 2: Install & Activate on Mac
Clone this repository and run the CMake installer script as your normal user (do **not** run `cmake` itself with `sudo`; it will prompt for your password only when moving system files):

```bash
git clone [https://github.com/jays2002/tetherkit-mac-auto.git](https://github.com/jays2002/tetherkit-mac-auto.git)
cd tetherkit-mac-auto
cmake -P setup_tetherkit.cmake
```

### Or run via one-liner (without cloning):
```bash
curl -fsSL [https://raw.githubusercontent.com/jays2002/tetherkit-mac-auto/main/setup_tetherkit.cmake](https://raw.githubusercontent.com/jays2002/tetherkit-mac-auto/main/setup_tetherkit.cmake) -o /tmp/setup_tetherkit.cmake && cmake -P /tmp/setup_tetherkit.cmake
```

## Logs & Troubleshooting
Check the live background daemon logs at any time:
```bash
cat /tmp/tetherkit-daemon.log
cat /tmp/tetherkit-auto.log
```

## Uninstall
To stop the background service and remove all installed scripts:
```bash
cmake -P uninstall_tetherkit.cmake
```
