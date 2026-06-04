---
name: run-app
description: Launch and drive the gym_race voice-fitness Flutter app on the iOS simulator to verify a change works. Use when asked to run/start/screenshot the app, confirm a fix works in the real app, or verify UI behaviour (e.g. the voice-record flow + 1RM result + history list).
---

# Run the gym_race app (iOS simulator)

Flutter voice-fitness app. Backend = Cloud SQL (Postgres) via Firebase
Functions; identity = Firebase **anonymous** auth. Home screen is
`VoiceRecordPage` ("語音記錄訓練").

Verified launch target: **iOS simulator** (debug). Note the simulator has **no
microphone / Speech recognition**, so the 🎤 "語音輸入" (STT) button won't
produce text there — drive the flow by **typing into the text field** and
tapping **✓ 記錄** instead.

## 1. Pick / boot a simulator

```bash
xcrun simctl list devices booted | grep -i booted
# If none booted:
xcrun simctl boot "iPhone 16e" 2>/dev/null; open -a Simulator
```
Grab the UDID from the booted line.

## 2. Launch in the background with a FIFO stdin (enables hot reload)

`flutter run` is long-lived — never run it foreground. CocoaPods on this Mac
needs a UTF-8 locale or `pod install` crashes (Encoding::CompatibilityError),
so export LANG/LC_ALL.

```bash
cd /Users/joh/gym_race
export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
rm -f /tmp/gr_in /tmp/gr_run.log; mkfifo /tmp/gr_in
nohup sh -c 'tail -f /dev/null > /tmp/gr_in' >/dev/null 2>&1 &   # FIFO holder (keeps stdin open)
nohup sh -c 'cd /Users/joh/gym_race && LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 flutter run -d <UDID> --debug < /tmp/gr_in > /tmp/gr_run.log 2>&1' >/dev/null 2>&1 &
```

After editing Dart files: `echo r > /tmp/gr_in` (hot reload) or `echo R`
(hot restart — use when you changed initState / DI / provider wiring).
Stop: `pkill -f "flutter_tools.snapshot run"` (FIFO holder dies on its own).

First simulator build runs pod install + Xcode build (several minutes — many
plugins: firebase, maps, video_player…). Wait with a background until-loop:

```bash
until grep -qE "Dart VM Service|Syncing files|Error|error:|Exception|Lost connection" /tmp/gr_run.log; do sleep 5; done
tail -30 /tmp/gr_run.log
```
Success markers: `Flutter run key commands.` + `A Dart VM Service ... is available at`.

## 3. Screenshot (look at it!)

```bash
xcrun simctl io booted screenshot /tmp/gr.png
```
Then Read /tmp/gr.png. Expect the "語音記錄訓練" page: hint card, an input
field, 🎤 語音輸入 / ✓ 記錄 buttons, a 匿名 chip top-right, and (after logging)
a 1RM result card + 歷史紀錄 list.

## 4. Drive the UI with idb

`xcrun simctl` cannot tap. Use **idb** (at `~/Library/Python/3.9/bin/idb`, not
on PATH; needs `idb_companion`).

```bash
export PATH="$HOME/Library/Python/3.9/bin:$PATH"
idb connect <UDID> 2>/dev/null
idb ui describe-all --udid <UDID>     # find element frames (points)
idb ui tap <x> <y> --udid <UDID>      # tap (SCREEN points, not screenshot px)
idb ui text "槓鈴臥推 60 公斤 6 下 體感 8" --udid <UDID>  # type into focused field
```

## 5. Verify the voice-log flow end-to-end

1. Tap the input field → `idb ui text "槓鈴臥推 60 公斤 6 下 體感 8"`.
2. Tap **✓ 記錄**.
3. Screenshot → expect a 1RM card (bench_press_barbell, 1RM 69.7) and the row
   appended to 歷史紀錄.
4. Confirm the backend write hit Postgres (a new `training_logs` row with the
   app's anonymous uid). Quick check from `gym_race_api/functions`:
   ```bash
   # connection: host 34.81.223.44 / db gym_race / user postgres / sslmode no-verify
   # query: select id,user_id,exercise_id,one_rm_est from training_logs order by id desc limit 3;
   ```
5. **History persistence**: hot restart (`echo R > /tmp/gr_in`) → the 歷史紀錄
   list should still show prior entries (local cache via shared_preferences,
   keyed by the persisted anonymous uid).

Grep the run log to confirm the API fired / parsed:
```bash
grep -E "語音紀錄|紀錄成功|parseVoiceLog" /tmp/gr_run.log
```

## Gotchas

- Simulator has no mic/STT — drive via the text field, not 🎤.
- `pod install` needs `LANG=en_US.UTF-8` or it crashes with an encoding error.
- `idb-companion` from the `facebook/fb` tap; `timeout` is unavailable on this Mac.
- A new Flutter version banner prints on every command; ignore it.
```
