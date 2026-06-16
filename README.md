# Le Galet — iOS

> Une vieille tablette devient un foyer calme. Vos photos, vos pensées, vos
> rendez-vous et vos rappels dérivent lentement sur l'écran, un seul à la fois.

A native SwiftUI iPad app that turns an idle kitchen tablet into a calm, always-on
family display. The companion to the web PWA (`~/Claude/apps/le-galet`), rebuilt
native so it can reach into the household's own albums, calendar, and reminders.

## The pebble engine (signature)

Each item dwells, then cross-dissolves into the next over several seconds, with a
gentle Ken Burns drift on photos. A time-aware wash eases the whole display
darker and shifts its single accent from warm **amber** (day) to cool **slate**
(night) across a soft threshold, over a subtle vignette, with a faint resting
clock — the mood of a candle-lit shelf. The screen is held awake while it drifts
(`isIdleTimerDisabled`).

## What native unlocks

- **Photos (PhotoKit):** pick straight from the family album. Only the
  `localIdentifier` is stored — the bytes never leave the library; images are
  loaded and downscaled on demand.
- **Calendar (EventKit):** the day's events — including all-day birthdays and
  anniversaries — drift in as gentle pebbles ("Aujourd'hui · l'anniversaire de
  Mamie"), never stored, always reflecting the real day.
- **Reminders (EventKit):** incomplete reminders surface around their due time.
- Curate quotes and manual time-windowed reminders by hand; weight, reorder,
  hide. Tune fade, dwell, day/night schedule, dimming, and shuffle in Réglages.

## Le Souffleur (AI)

A gentle AI host that suggests seasonal greetings and resonant quotes. It calls
the deployed house-stack endpoint (`le-galet.netlify.app/api/souffleur`, Opus +
forced tool-use, NDJSON-streamed) so the Claude key stays server-side and the
app ships with no secret.

## Stack

SwiftUI · SwiftData (local) · PhotoKit · EventKit · iOS 26 · xcodegen. Dark,
French-first (Québécois) with English. Everything you add stays on the device.

## Build

```
xcodegen generate
open LeGalet.xcodeproj   # or:
xcodebuild -scheme LeGalet -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' build
```
