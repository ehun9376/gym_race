---
name: run-app
description: Launch and drive the AeroRide passenger Flutter app on the iOS simulator to verify a change works. Use when asked to run/start/screenshot the app, confirm a fix works in the real app, or verify UI behaviour. Covers simulator launch, log capture, screenshots, and UI driving via idb.
---

# Run the AeroRide passenger app (iOS simulator)

Flutter app. Verified launch target: **iOS simulator** (debug). This is the
fastest loop for screenshots + UI driving; physical devices need wireless
trust and Developer Mode and are flaky for automation.

## 1. Pick / boot a simulator

```bash
# Already-booted simulator (preferred):
xcrun simctl list devices booted | grep -i booted
# If none booted, boot one and open Simulator.app:
xcrun simctl boot "iPhone 16e" 2>/dev/null; open -a Simulator
```

Grab the UDID from the booted line (e.g. `80B90B39-7D77-4C3C-9F9B-2DD82AB2C1A4`).

## 2. Launch in the background with a FIFO stdin (enables hot reload)

`flutter run` is long-lived — never run it foreground. Launch it reading stdin
from a FIFO so you can send `r` (hot reload) / `R` (hot restart) **without
rebuilding** after edits (no tmux on this machine).

```bash
cd /Users/joh/aeroride_passenger_app
rm -f /tmp/flutter_in /tmp/flutter_run.log; mkfifo /tmp/flutter_in
nohup sh -c 'tail -f /dev/null > /tmp/flutter_in' >/dev/null 2>&1 &   # holder: keeps FIFO open so flutter doesn't get EOF
nohup sh -c 'flutter run -d <UDID> --debug < /tmp/flutter_in > /tmp/flutter_run.log 2>&1' >/dev/null 2>&1 &
```

**After editing Dart files, hot reload instead of relaunching** (user asked for this):
```bash
echo r > /tmp/flutter_in   # hot reload; use R for hot restart
```
Wait ~1-2s, then screenshot. Hot reload re-runs build() so UI/layout changes
apply; it does NOT re-run main()/initState of existing State or DI. Use `R`
(hot restart) when you changed initState, provider wiring, or app-startup code.
Full relaunch only when you changed native/pubspec or hot restart misbehaves.
Stop everything with `pkill -f "flutter_tools.snapshot run"` (the holder dies on its own / `rm /tmp/flutter_in`).

First build runs `pod install` + Xcode build (~80s clean). Wait for readiness
with a Bash `run_in_background` until-loop (do NOT chain sleeps):

```bash
until grep -qE "Dart VM Service|Syncing files|Error|error:|Exception" /tmp/flutter_run.log; do sleep 3; done
tail -25 /tmp/flutter_run.log
```

Success markers: `Flutter run key commands.` + `Dart VM Service ... available at`.
The app prints `🔒 Firebase App Check Token:` once `GetItService.init()` and
startup finish cleanly — a good "no startup crash" signal.

Hot reload after edits: `echo "r" >> ` won't work (detached). Re-launch, or
run `flutter run` in a tmux pane if you need interactive `r`/`R`.

## 3. Screenshot (look at it!)

```bash
xcrun simctl io booted screenshot /tmp/sim.png
```

Then Read /tmp/sim.png. A grey screen with a permission dialog = launched OK
but blocked on a native prompt (see step 4).

## 4. Drive the UI with idb

`xcrun simctl` cannot tap. Use **idb** (installed at
`~/Library/Python/3.9/bin/idb`, not on PATH; needs `idb_companion` from
`brew install facebook/fb/idb-companion`).

```bash
export PATH="$HOME/Library/Python/3.9/bin:$PATH"
idb connect <UDID> 2>/dev/null        # one-time per session
idb ui tap <x> <y> --udid <UDID>      # coords are in SCREEN points, not screenshot px
idb ui text "some text" --udid <UDID> # type into focused field
idb ui describe-all --udid <UDID>     # dump the a11y tree to find tappable element frames
```

Screenshot is at device pixel resolution (e.g. 1179 wide); idb taps use
points. Use `idb ui describe-all` to read each element's `frame` (already in
points) instead of converting screenshot pixels.

**Notification permission prompt** on first launch — either tap 允許/不允許
via idb, or pre-grant before launch:
`xcrun simctl privacy booted grant notifications com.<bundle-id>`.

## 5. Stop the app

```bash
pkill -f "flutter_tools.snapshot run"
```

## Verifying the "進行中訂單 / 即時路線追蹤" feature

Requires a **logged-in account** with a live in-progress order on the backend
(`/profile/order/during` returns a non-empty list, and that order has driver
status). Without that the entry points (home row / order-page progress card /
"進行中" section) correctly render nothing.

Grep the log to confirm the API fires and parses:

```bash
grep -E "🚗 取得進行中訂單|✅ 進行中訂單載入成功|進度卡片輪詢" /tmp/flutter_run.log
```

Entry points and expected screens:
- Home page top row → taps into `TripTrackingPage` (圖二 → 圖三)
- Order page bottom progress card + "進行中" section (圖一)
- Tracking page flight card → flight-info modal sheet (圖三 → 圖四)

Driving the full flow needs login (phone OTP) — ask the user for a test
account / pre-seeded in-progress order if a full visual pass is required.

## Gotchas captured from setup

- `idb-companion` is no longer in homebrew-core; install from the
  `facebook/fb` tap.
- `timeout` is not available by default on this Mac (no coreutils) — don't
  wrap commands in it.
- A new Flutter version banner prints on every command; ignore it.
