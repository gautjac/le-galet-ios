# TestFlight — beta testing setup

App Store Connect → your app → **TestFlight** tab.

There are two kinds of testers:

- **Internal testers** (up to 100, must be on your team / have an ASC role) —
  builds reach them in minutes, **no App Review needed**. Fastest way to start.
- **External testers** (up to 10,000, anyone by email or a public link) —
  the **first build of each version needs a quick Beta App Review**. The fields
  below are what that review asks for.

You only fill the "Test Information" once; it applies to external testers.

---

## Test Information (External testing → "Test Details")

### Beta App Description  *(shown to testers)*

**English**
```
Carousel turns an old iPad into a calm family hearth — it slowly drifts through your own photos, a few quotes, and the day's reminders and calendar events, one at a time, with a gentle cross-fade. No feeds, no notifications.

In this beta I'd love your read on: does it feel calm and effortless to set up? Do your photos look good (including portrait photos and whole albums)? Do calendar events and reminders show up correctly? Anything that feels confusing, cramped, or off.

No account is needed. When prompted, allow access to Photos, Calendar, and Reminders to see the full experience — but it works without them too.
```

**Français**
```
Carrousel transforme un vieil iPad en foyer familial calme — il dérive doucement à travers vos propres photos, quelques citations, et les rappels et rendez-vous du jour, un à la fois, avec un fondu tout en douceur. Aucun fil, aucune notification.

Dans cette bêta, j'aimerais votre avis sur : est-ce que c'est calme et simple à configurer ? Est-ce que vos photos sont belles (y compris les portraits et les albums entiers) ? Est-ce que les rendez-vous et les rappels s'affichent correctement ? Tout ce qui semble confus, à l'étroit ou bancal.

Aucun compte requis. Quand on vous le demande, autorisez l'accès aux Photos, au Calendrier et aux Rappels pour voir l'expérience complète — mais l'app fonctionne aussi sans.
```

### What to Test  *(per-build notes — "What's New for testers")*
```
First TestFlight build (1.0.0).

Please try:
• First run: add a few photos and connect Calendar / Reminders from the welcome flow.
• Add a whole album, not just single photos.
• Let it sit and drift for a while — does the pace feel calm? Try the day/night dimming.
• Open Settings (gear): change the text size, the pace, and which calendars/lists feed the display.
• Rotate the iPad — photos should reframe without cropping heads.

Tell me anything that feels confusing, slow, cramped, or wrong. Thank you!
```

### Feedback email
```
jac@jacgautreau.com
```

### Marketing URL (optional) / Privacy Policy URL (required for external)
```
Marketing: https://carrousel-app.netlify.app
Privacy:   https://carrousel-app.netlify.app/privacy
```

---

## Beta App Review — "Sign-In / Review Notes"

```
No account or sign-in is required; the app opens straight into a guided first-run.

To see the full experience, allow access when prompted:
• Photos — to display the user's own photos (read-only; only a reference is kept, images never leave the device).
• Calendar & Reminders — to drift the day's events and to-dos onto the display (read-only; never stored or transmitted).

Notes for the reviewer:
• The app is iPad-only and designed for landscape or portrait on a stand.
• Photo captions may show a city name; this is produced on-device from a photo's saved coordinates via Apple's geocoder, and needs no location permission.
• Nothing the user adds is ever sent to a server — no accounts, no analytics, no tracking, no third-party SDKs. The app is fully on-device.
```

---

## Export Compliance

Already handled in the build: `ITSAppUsesNonExemptEncryption = false` is set in
Info.plist, so App Store Connect will **not** ask the encryption question on each
upload. (The app only uses standard HTTPS — exempt.)

If ASC ever asks anyway: the app **does** use encryption, but only standard
encryption (HTTPS), so it is **exempt** and needs no CCATS/year-end report.
