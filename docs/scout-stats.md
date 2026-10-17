# Event scout stats

The event page's **Scouts** tab displays current group members by name with
row numbers, trust ratings, contribution percentages, and submission counts.
Click column headers to sort in either direction.
Names stay frozen on narrow screens. The three requested metrics use a
group-relative red/amber/green scale; equal ranges and missing values are neutral.
Row numbers follow the sort order rather than representing permanent rankings.

These stats include **match scouting for this event**, not pit reports.
Raw entry counts include repeated submissions. Trust and contribution use only
the latest submission per scout/robot/match, ordered by `submitted_at` (last input
record wins when timestamps are missing or tied). Identity uses member IDs and
usernames, so scouts sharing a first name remain separate people.

## Calculations

- **Contribution:** each distinct robot in a completed qualification match with
  a complete valid report earns one coverage credit, split equally among its
  reporting scouts. A scout's percentage is their credits divided by total
  group coverage credits, multiplied by 100. It measures share of covered
  robot/matches, not percentage of the event covered. Repeated submissions
  earn no additional credit. Percentages may differ slightly from 100 in total
  because of rounding.
- **Validity/completeness Q:** average valid-field fraction across the scout's
  unique reports. The four fields are auto fuel (0–300), teleop fuel (0–1000),
  died, and defense. A report must identify a robot actually scheduled in that
  completed qualification match to receive any validity credit.
- **Robot trend T (50% weight):** collapse complete valid reports to one median
  observation per robot/match. For each target report, exclude the entire
  target robot/match, then select up to six nearest appearances of the same
  robot, within five appearances in either direction. At least three other
  appearances are required. Fit auto and teleop separately with a robust local
  line: median pairwise slope and median intercept. This follows gradual robot
  improvements and resists a single outlier. A target with reported defense or
  a breakdown skips the teleop trend check, and those contextual matches are
  excluded from other teleop baselines. These booleans are not independently
  verified. Historical ratings can change as later matches become available.
  For each phase the allowance is
  `max(8 auto / 20 teleop, 0.35 * prediction, 3 * median absolute residual)
  + 0.2 * abs(slope) * distance_to_nearest_sample`.
- **TBA compatibility B (20% weight):** use the cached match's alliance fuel
  `hubScore.autoCount` / `teleopCount`, falling back to the respective phase
  `Points` fields in this 2026 format. Overall scores, tower points, and fouls
  are never compared with individual fuel counts. With all three robots
  covered, compare their summed observations with the alliance total using
  an allowance of `max(10 auto / 30 teleop, 0.25 * official_count)`.
  Teleop may range from the official count to that count plus `uncounted`;
  the latter is a conservative allowance for inactive-hub fuel. Missing
  `uncounted` skips teleop entirely. Full alliance comparisons are shared
  compatibility evidence, not proof of which scout made a mistake. With partial
  coverage, only an individual report exceeding the whole alliance's upper
  bound plus allowance provides evidence; remaining below it earns no credit.
  Missing breakdowns are skipped, not treated as zero.
- **Compatibility scores:** phase errors within their allowance earn 1. Outside
  it, `score = max(0, 1 - max(0, error - allowance) / (2 * allowance))`.
  Available phase scores are averaged into one trend score and one TBA score
  per report. Each channel is moderated separately:
  `(sum(scores) + 2.5) / (number_of_checked_reports + 5)`.
  Five neutral prior reports prevent small samples producing extreme ratings.
- **Trust:** `100 * (0.30 * Q + 0.50 * T + 0.20 * B)`. Missing evidence keeps
  its neutral 50% value; weights are not redistributed to the remaining source.
  Complete valid reports without evidence start at 65/100. A rating is
  provisional until it has at least five distinct checked reports and three
  trend checks. A report checked by both channels counts once in
  `CheckedEntries`. Members with no entries have no rating. Invalid/incomplete
  entries can lower validity but cannot earn contribution or evidence credit.

Duplicate coverage of the same robot/match is **not required**. The robot's
other matches provide trend evidence; scouts covering different alliance robots
can collectively provide TBA evidence. These are heuristic consistency checks,
not verified individual accuracy. A robot can genuinely change performance,
human players can add alliance fuel, and a scout can consistently miscount.
TBA's smaller fixed weight, broad allowances, and provisional markers limit
overconfidence. The existing team fuel-fusion weights are unchanged.

2026 fuel in an active hub is worth one point, while inactive-hub fuel earns no
points; see the [official FIRST scoring rules](https://firstfrc.blob.core.windows.net/frc2026/Manual/HTML/2026GameManual.htm).

## Storage and refresh

`PFDB.GroupStats` retains one document per `group_id` and `event_key`.
The `data` field now contains `Teams` (the existing team rows) and `ScoutStats`
(the scout rows). Scout rows also store `CoverageCredit`, `UniqueEntries`,
`ValidEntries`, `CheckedEntries`, `TrendEntries`, `TBAEntries`, component scores,
`TrustMethod`, and `Provisional` for explaining results. `ComparedEntries` is
retained as a compatibility alias for `CheckedEntries`. These evidence counts
are retained in the backend for future use and are not displayed in the frontend.
Cache version 7 rebuilds older documents automatically. Public/event/team APIs
continue returning team rows in their existing response formats. The group
event stats endpoint returns the full document with the new `data` object.

Stats rebuild on match submissions and the existing background event updates.
The Scouts tab refreshes on opening, every 30 seconds, on app resume, and with
its refresh button. Failures provide retry UI. Account/group changes recreate
the tab's controller so an old account response cannot appear in a new session.
Both the API and Flutter app need rebuilding/deploying to expose this feature.

Checks: `python -m unittest tests.test_scout_stats tests.test_stats_consistency
tests.test_routes tests.test_analysis tests.test_match_scouting_validation` from
`API`, and `flutter test test/scout_stats_grid_test.dart test/stats_api_test.dart`
from `APP`.
