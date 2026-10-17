# PolarForecast frontend

Flutter web client for FRC scouting, event analysis, and alliance selection.
Backend routes, authentication settings, and scoring calculations are preserved
by the competition workspace redesign.

Events open directly to the Syncfusion stats grid. Phones use Stats, Matches,
Scout, Picks, and More; desktop retains the event navigation rail. The group
page provides searchable events and direct links to match and pit scouting.
Picklists use their original implementation, including shared saving, live
updates, tiers, notes, reordering, and CSV export. Stats still offer comparison
for up to three teams.

The home page opens directly to team search and the rankings grid. Event search
and account controls remain in the navigation bar; the extra home headers are
removed.

Match scouting offers a live field recorder alongside pre-match, auto, teleop,
and review. Confirm the match and station, or enter a team override when the
schedule is unavailable. Open the field recorder and start its clock on the
field signal. The recorder switches through 20-second auto, the 3-second scoring
delay, 140-second teleop, and the final 30-second endgame. Sync the clock from its
menu when starting late. Timing follows the [2026 FIRST game manual, section 6.4](https://firstfrc.blob.core.windows.net/frc2026/Manual/2026GameManual.pdf).

The recording interaction is inspired by [Highlander Robotics' Lovat collection
workflow](https://github.com/HighlanderRobotics/lovat/blob/main/apps/learn/src/content/docs/guides/scouting-a-match.mdx)
and its [collection source](https://github.com/HighlanderRobotics/lovat/tree/main/apps/collection).
It is independently implemented in Flutter for PolarForecast's existing fields:

- The field image is the main auto-recording surface on every screen size.
  Tap the mapped preload area, trench, bump, depot, or neutral intake. Red and
  blue use their own field images, with a visible Rotate control to match the
  stands. Left/right lanes are labeled, and arrows and step numbers show the
  recorded sequence. The same crossing can be used out and back.
- Hold and drag the green hub on the auto map, or the green teleop pad, while
  fuel scores. Rate mode increases the count
  over time and dragging farther increases the rate. Count mode sets quantity
  by distance; moving closer reduces it. Release commits one shooting burst.
- Auto bursts add one existing hub-shot action. Undo removes both the burst
  count and its route action together. Corrections use the existing fuel limits.
- Defense holds record duration, and disabled-robot observations are toggles.
  The observation timeline shows phase, time, count, and duration. Pointer
  cancellation or app suspension discards an unfinished hold.
- Review flags and notes, then choose **Upload match report**. Every new report
  attempts the existing cloud endpoint, even if device storage is unavailable.
  A failed or timed-out upload automatically starts a `.json` backup download
  containing the complete report, identity metadata, and observation timeline.
  Device history also provides Download JSON and explicit cloud uploads.
  An interrupted upload requires checking server reports before retry.

Drafts and reports persist in browser/device storage, scoped to event, group,
and account where device storage is available. Device backups are attempted
before upload, and their failure does not block cloud submission. A successful
cloud response remains successful even if the subsequent device status write
fails. Reports are retained in history after confirmation.
There are no automatic upload retries: the existing endpoint is not idempotent.
Clearing browser site data removes device copies, and device storage can fail;
the interface reports that failure and offers a draft JSON download. If both
cloud upload and JSON download fail, the current draft stays open with a retry
download action. Browser download settings determine the final file location.
Committed
observations autosave after a short debounce; an unfinished hold is not a saved
observation. Detailed timing and duration are device-local and included in JSON
exports. The server continues receiving its original aggregate match payload.

The pit auto recorder supports multiple named routines using the same visible
field map and mapped action targets. Undo, redo, and rewind preserve valid action
order. Stand mode gives the map the full screen and keeps its fuel counter
separate from path actions. The displayed route connects recorded areas; it
does not measure exact robot coordinates. Hub events do not move the robot
trace to the hub. Existing API action strings and team
replay compatibility are preserved. Auto fuel is capped at the API's 300 limit.

Pit forms have section shortcuts, and mobile pit status uses cards and filters
for unfinished reports, photos, and follow-ups. Global decorative snowflakes
ignore input and semantics, pause in the background, and respect reduced motion.

Run locally from this directory:

```powershell
flutter pub get
flutter run -d chrome --web-port 3000
```

Preserve the deployment's existing API and authentication build definitions.
Build with `flutter build web` and deploy through the existing hosting setup.

Validation:

```powershell
flutter test
flutter test --platform chrome test/widget_test.dart
flutter build web
```

The app navigation smoke tests are browser-only because the existing sign-in
service uses browser APIs. Other suites run on the default test platform.
Responsive checks cover 320px, 390px, and desktop widths with enlarged text.
