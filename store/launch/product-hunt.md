# Product Hunt launch kit — Carousel

**App Store:** https://apps.apple.com/app/id6786345170
**Website:** https://carrousel-app.netlify.app
**Price:** Free · **Platform:** iPad (iPadOS 26+)

---

## Name
```
Carousel
```

## Tagline  *(max 60 chars)*
```
Turn your iPad into a calm family display
```
*(40 chars)* — alternates, all under 60:
- `A calm family display. No feed, no notifications.` (48)
- `The calm display for the iPad you already have` (46)
- `Your photos, your day — one calm thing at a time` (48)

## Description  *(max 260 chars)*
```
Carousel turns your iPad into a calm family hearth. Your own photos, hand-picked quotes, and the day's calendar and reminders drift past one at a time, with a slow cross-fade. No feed, no notifications, no accounts. Nothing leaves your device. Free.
```

## Topics
`iPad` · `Photography` · `Home` · `Productivity` · `Design`

## Links
- Website → `https://carrousel-app.netlify.app`
- App Store → `https://apps.apple.com/app/id6786345170`

---

## Maker's first comment  *(the most important asset — post it immediately)*

```
Hi Product Hunt 👋

I'm Jac, a filmmaker who builds small software in the evenings.

Carousel came from a simple frustration: every screen in my house wants
something from me. Notifications, feeds, badges, a scroll that never ends. I
wanted the opposite — a screen that just sits there being pleasant, and asks
for nothing.

So Carousel takes the iPad you already have, and slowly drifts through the
things that actually matter in a household: your own family photos, a few
quotes you've chosen, and the day's calendar events and reminders. One thing
at a time, with a long cross-fade. It brightens at breakfast and dims in the
evening. There is nothing to check, no inbox, no streak.

A few decisions I care about:

• It never crops a face. Most photo displays fill the screen and chop the top
  off a portrait. Carousel shows the whole photo on a soft blurred bed by
  default. (If you'd rather it fill the screen, an optional mode uses on-device
  vision to keep faces and subjects safely in frame.)

• Nothing leaves your device. No account, no sign-up, no analytics, no ads, no
  third-party SDKs. Your photos stay in your photo library — the app only holds
  a reference. Calendar events are read live and never stored.

• I actually removed a feature to keep that true. There was an AI helper that
  suggested seasonal quotes; I cut it before launch. It was a nice flourish,
  but it meant the app talked to a server, and that wasn't worth it.

• Bilingual throughout — French and English.

It's free, iPad-only, and there's no upsell — I built it for my own kitchen.

I'd genuinely love to know: what would you put on a screen that never asks for
your attention? And if you try it, tell me where it feels wrong. I'm here all
day.
```

---

## Gallery assets

PH gallery images are **1270×760** (first image is the one that matters most).
Thumbnail is **240×240** — use the app icon (`store/icon-1024.png`).

Suggested order:
1. The photo screen (whole photo + date/place caption + resting clock)
2. The day's calendar card (teal)
3. A quote
4. The curation screen (what drifts, and how often)
5. Settings (day→night warmth, pace, text size)

Source screens live in `store/screenshots/out-clean/` (2752×2064, text-free).
Run `node store/screenshots/generate.mjs` to regenerate.

---

## Launch-day notes

- **Post at 12:01am PT** — PH days run midnight-to-midnight Pacific; posting
  later costs you hours of ranking.
- **Post the maker's comment immediately**, before any traffic arrives.
- **Don't ask for upvotes anywhere** (PH penalises it). Ask people to "take a
  look" instead.
- **Answer every comment**, especially critical ones. Engagement is the ranking
  signal that you actually control.
- Have the **App Store link ready** — most PH traffic is desktop, so also give
  people the website, which explains it without needing an iPad in hand.

## Likely questions — prepared answers

**"How is this different from the built-in photo slideshow / Photo Shuffle?"**
> Three things: it mixes in your calendar, reminders and quotes rather than only
> photos; it never crops a face; and you control the mix — how often each kind of
> thing appears. It's also deliberately slower than a slideshow. A photo can sit
> for minutes.

**"Why iPad only?"**
> It's designed to be propped up and looked *at*, from across a room — a shelf or
> a kitchen counter. On a phone it'd be a widget, which is a different product. An
> older iPad you're not using anymore is the perfect device for it.

**"Is it really free? What's the catch?"**
> No catch, no ads, no accounts, no data collection. I built it for my own
> kitchen and it costs me nothing to run, because it doesn't talk to any server.

**"Android / Mac / Apple TV?"**
> Not yet. If enough people ask I'll look at it — but I'd rather make this one
> genuinely good first.
