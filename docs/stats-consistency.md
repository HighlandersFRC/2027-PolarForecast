# Troubleshooting different team stats

## What was broken

Three code paths could leave devices showing different numbers:

1. The event table requested `/{event}/stats?username=...`, which can use
   scouting-adjusted `GroupStats`. The team detail page omitted the username
   and read public `Stats` directly. Opening the same team through different
   pages could therefore show different OPR and scoring components.
2. The team page fetched once when it opened. The event page refreshed only
   after `/cache/status` changed its global `last_completed_at`. Stats saved
   during an ongoing cycle, group scouting submissions, a failed global cycle,
   and a first completion after an initially empty status could leave an older
   page behind a freshly opened page.
3. The web deployment had no explicit cache policy and used Flutter's default
   offline-first service worker. Devices could retain different frontend builds.
   API responses also had no explicit policy preventing browser/proxy caching.

These are verified code defects and caching risks. Without the original
devices' requests, we cannot say which one caused a particular reported mismatch.

## How the fix works

- Event and team endpoints use `get_stats_from_db` with the same username.
  The team route also responds to session/account changes while it is open.
- Both pages use `APP/lib/services/live_data_controller.dart` to read current
  server stats every 30 seconds and on app resume. They do not wait for the
  global cache job. Pending requests are shared, requests time out after 20
  seconds, obsolete account responses are ignored, and refresh failures show
  an error rather than silently presenting old numbers as current.
- Successful refreshes keep the existing view in place while loading. The
  event page preserves an active match-scouting draft during stats refreshes.
- API responses use `Cache-Control: no-store`. Nginx uses `no-cache`, which
  makes browsers revalidate frontend files. Docker builds disable the generated
  offline-first worker and serve a retirement worker at the old URL.

Polling reads the existing MongoDB cache; it does not recalculate OPR or contact
TBA on every device request. New TBA results still depend on backend updates.
Two requests made on opposite sides of a server update may briefly differ;
healthy connected pages converge on their next successful refresh.

Different groups, and signed-in versus signed-out users, can intentionally have
different stats. Group stats include that group's scouting data. Public stats
use TBA data. A user without an applicable group cache falls back to public
stats. Compare the same event/year and account when checking consistency.

## Deploying this fix

From the deployment checkout, rebuild both services:

```sh
docker compose up -d --build api app
```

The frontend is compiled into the image. Restarting its existing container does
not rebuild it. Keep `APP_API_BASE_URL` pointed at the intended API for all
devices; Docker embeds this setting at build time.

If a host proxy or CDN overrides caching headers, apply the same policies there:
`no-store` for the API, `no-cache` for frontend files. Purge any previously
cached API responses and app entry files once when deploying this change.
The retirement worker only removes the three named Flutter asset caches; it
does not clear login storage. An already open page still runs its loaded code
until reloaded. Finish or save any scouting draft, then reload that page.

For deployments outside Docker, build with `flutter build web --release
--pwa-strategy=none` plus your usual `--dart-define` settings, then copy
`APP/flutter_service_worker.js` over `build/web/flutter_service_worker.js`.
Keep that migration URL available for older browser registrations.

## If it happens again

1. Record the event key including year, team number, page URL, account/group,
   differing values, and approximate time on both devices. Refresh both pages.
   Allow one 30-second polling interval after the latest server update.
2. In browser DevTools > Network, inspect the actual API host and username
   query parameter. Compare `/{event}/stats?username=...` with
   `/{event}/event/{team}/team?username=...`; the team's row should match.
   Omit `username` on both requests when testing public stats. Confirm response
   headers include `Cache-Control: no-store` and responses aren't served from
   a browser or proxy cache.
3. If API values match but displayed values differ, check for an old frontend
   build/service worker. After saving drafts, use a hard reload. If necessary,
   unregister the site's old Flutter worker in DevTools > Application > Service
   Workers and clear its asset caches, then reload. Check the deployed
   `main.dart.js`, `flutter_bootstrap.js`, and page response for `no-cache`.
4. If both APIs agree but are stale, inspect `/cache/status?year=2026` (use the
   actual year) and `docker compose logs --tail=200 api`. Check `status`,
   `error`, and `last_completed_at`. A cycle's completion timestamp describes
   the whole updater, not the specific event. In MongoDB inspect
   `PFDB.Stats` by `event_key`, or `PFDB.GroupStats` by `event_key` and `group_id`,
   including `updated_at` and `cache_version`. Investigate TBA request failures
   and any `Skipping GroupStats rebuild` log entries before restarting.
5. If identical uncached API requests keep returning different numbers without
   updates, check that every proxy/upstream instance uses the same API release
   and `MONGO_URI` database. Do not delete database volumes to reset a cache.

When changing calculation logic later, bump `STATS_CACHE_VERSION`,
`GROUP_STATS_CACHE_VERSION`, and/or `PREDICTION_CACHE_VERSION` in `API/api.py`
for the affected outputs, and ensure those caches are rebuilt. Existing event
cache checks use the stats/prediction versions to force recalculation even if
TBA returns HTTP 304. Group stats are rebuilt separately by the updater.

## Regression checks

From `API`:

```sh
python -m unittest tests.test_stats_consistency tests.test_routes tests.test_linreg tests.test_tba_client -v
```

From `APP`:

```sh
flutter test test/live_data_controller_test.dart test/stats_api_test.dart
flutter build web --release --pwa-strategy=none
```

The regression tests cover public/group/fallback consistency, cache headers,
devices opened at different times, account-switch races, resume, timeout/error
recovery, and stopping refreshes when a view is disposed.

Cache references: [Flutter web caching guidance](https://docs.flutter.dev/platform-integration/web/faq)
and [HTTP Cache-Control semantics](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Cache-Control).
