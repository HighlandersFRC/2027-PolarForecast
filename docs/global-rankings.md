# Homepage global rankings

The homepage ranks teams for the API's configured season (`YEAR`). Each team
appears once, using the unchanged `totalOPR` stored in public `Stats` for its
most recent event with played qualification matches. Event end date, start
date, and event key determine event order; cache write time does not. An upcoming
event without calculated OPR does not replace a team's previous result. Negative
OPR values and full calculation precision are preserved.

The homepage contains a compact search toolbar and a full-width `SfDataGrid`.
OPR, Auto, and Teleop come directly from the same latest event's public
`totalOPR`, `autoOPR`, and `teleopOPR`; private scouting fusion is never used.
Numeric cells use matte heatmaps on desktop and mobile. Each snapshot includes
global metric ranges, keeping colors stable across search and pagination.
Rank and team identity remain frozen during horizontal scrolling on phones.
The homepage does not show season, team count, update time, or explanatory badges.

`GET /rankings/global` returns at most 50 teams, plus `total`, `matched`,
`next_offset`, `snapshot`, and `updated_at`. Optional `q` searches team numbers
and names across the entire season. Search results retain their global rank.
Subsequent pages send the same `snapshot` so a background update cannot create
duplicates or gaps between pages. Snapshots expire after 30 minutes; HTTP 410
instructs the client to start a fresh snapshot.

The server rebuilds rankings from cached public stats at most once every five
minutes when requested. The homepage refreshes every five minutes, on app resume,
with the refresh button, or by pulling down. Refresh preserves how many pages
were loaded and ignores responses belonging to an older search. The ranking
never reads private `GroupStats` or changes `analysis.py`.

Team names use daily cached bulk team pages from the [TBA API](https://www.thebluealliance.com/apidocs/v3).
The existing team identity endpoint supplies avatars only as rows come into
view. A missing or unavailable avatar uses a snowflake placeholder. The browser
never downloads the entire ranking or requests every team's icon on page load.
Decorative snowflakes respect the device's reduced-motion preference.

Run `python -m unittest discover -s tests` in `API` and
`flutter test test/global_rankings_test.dart` in `APP` for the ranking regression
checks, including pagination, latest-event selection, search, snapshot expiry,
periodic refresh, and mobile/desktop layout.
