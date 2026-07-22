# Hacker News launch kit — Carousel (Show HN)

**App Store:** https://apps.apple.com/app/id6786345170
**Website:** https://carrousel-app.netlify.app

> HN is not Product Hunt. No adjectives, no "excited to share", no emoji. State
> what it is, show the interesting engineering, name the limitations before
> anyone else does, and stay in the thread. The tone that works is *a competent
> person explaining a thing they made, plainly.*

---

## Title  *(max 80 chars)*

Recommended:
```
Show HN: Carousel – a calm iPad display for photos, quotes and your day
```
*(71 chars)*

Alternates:
- `Show HN: Carousel – an iPad family display that talks to no servers` (67) — leads with the privacy angle, which HN engages with hardest, but invites "prove it" scrutiny. Fine, because it's true.
- `Show HN: A calm iPad display that never asks for your attention` (63)

**Note the dash:** HN convention is an en dash `–`, not a hyphen.

## Which URL to submit

Submit **https://carrousel-app.netlify.app** (the website), not the App Store.
HN readers are mostly on desktop; an App Store link is a dead end for them,
while the site explains it and shows the screens. Put the App Store link in the
text so people on an iPad can go straight there.

---

## Post text

```
Carousel turns an iPad into a calm family display. It slowly cross-fades
through your own photos, a few quotes you've added, and the day's calendar
events and reminders — one at a time, with a long dissolve. It brightens during
the day and dims in the evening. There's nothing to check and no inbox.

I built it because every screen in my house wants something from me, and I
wanted one that doesn't.

Things that might be technically interesting:

- It talks to no servers. No account, no analytics, no third-party SDKs. Photos
  stay in the photo library — the app stores only a local identifier, never a
  copy. Calendar events and reminders are read live through EventKit and never
  persisted. The one remaining network call is optional: Apple's geocoder,
  turning a photo's saved coordinate into a city name for the caption.

- The worst bug was a layer above where I was looking. Portrait photos kept
  losing the top of someone's head on a landscape screen, and no amount of
  fixing my framing math helped — because PHImageManager was loading every
  image with .aspectFill against a landscape target, pre-cropping it before my
  layout code ever saw it. Requesting .aspectFit against a square max-edge
  target fixed it. The default is now to show the whole photo on a soft blurred
  bed and never crop a face; an opt-in fill mode uses Vision (faces, bodies,
  pets, saliency) to keep the subject in frame when it does have to crop.

- The shuffle is deterministic: a seeded RNG keyed to a time bucket, so the
  deck stays stable while you're watching instead of re-randomising on every
  redraw.

- I removed the only AI feature before shipping. It suggested seasonal quotes
  through an API, but it meant the app depended on a server I pay for, with no
  auth in front of it, and it broke the "sends nothing anywhere" property.
  Cutting it made the privacy claim absolute rather than almost-true.

Limitations, up front: iPad only (iPadOS 26+); everything is local, so there's
no sync between devices; and it's a display, not a photo manager. It's free,
with no ads, no accounts and no upsell — it costs me nothing to run because
there's no backend.

App Store: https://apps.apple.com/app/id6786345170

I'd like the criticism, particularly on the framing behaviour and on anything
that feels like it's asking for attention when it shouldn't.
```

---

## Timing & conduct

- **Post Tue–Thu, ~8–10am ET** (front-page competition is thinnest in the US
  morning). Avoid weekends and Monday.
- **Never ask for upvotes**, anywhere, including private channels. It's the one
  thing that reliably gets a submission buried.
- **Answer every comment**, including the dismissive ones, without defensiveness.
  A good-faith reply to a harsh comment usually wins the thread.
- **Don't edit the title after posting** to chase attention.
- If it doesn't get traction, **do not repost the same day**. HN allows a second
  attempt later; a rapid repost looks like gaming.

## Likely HN objections — prepared answers

**"This is a slideshow. Photos.app does this for free."**
> Fair. Three differences: it mixes calendar, reminders and quotes into the same
> rotation, not only photos; it never crops a face by default, which the built-in
> one does; and you control the mix — how often each kind of thing appears. It's
> also much slower than a slideshow by design.

**"'No servers' — how do I verify that?"**
> You can't take my word for it, and you shouldn't. Two checks: the app declares
> no background networking and works fully in airplane mode (the only thing you
> lose is the optional city-name caption), and Apple's privacy label reports no
> data collection. There's no account to create, which is the part that's hardest
> to fake.

**"Why iPadOS 26? That cuts out most old iPads."**
> Honest answer: it's built on SwiftData and current SwiftUI, and I optimised for
> writing it well as one person rather than for maximum reach. Lowering the target
> is the most likely thing I'd change if people want it.

**"Why is an app like this closed source?"**
> No principled reason. It's a personal project I shipped; I'm not opposed to
> opening parts of it, particularly the photo-framing code, which is the part
> that took the longest to get right.

**"Why French first?"**
> I write in French before English, so the French is the original and the English
> is a real translation rather than a machine one. Both are complete — the app
> switches on device language, and every string, screenshot and caption exists in
> both.
