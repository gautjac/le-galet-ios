# Launch posts — X and LinkedIn (FR + EN)

**App Store:** https://apps.apple.com/app/id6786345170
**Site:** https://carrousel-app.netlify.app

> Which link to use: **App Store on X** (mobile-heavy audience, one tap to
> install), **the site on LinkedIn** (desktop-heavy — an App Store link is a dead
> end on a laptop, the site explains it and links onward).

The through-line on every platform is the same opening move: *every screen in my
house wants something from me, so I built one that doesn't.* It's the honest
reason the thing exists, and it's the only line that makes people stop.

---

## X — English  *(263/280 — X counts any link as 23 chars)*

```
Every screen in my house wants something from me.

So I built one that doesn't.

Carrousel turns your iPad into a calm family display — photos, quotes, your day, one at a time.

No feed. No notifications. Nothing leaves your device.

Free:
https://apps.apple.com/app/id6786345170
```

## X — Français  *(264/280)*

```
Tous mes écrans veulent quelque chose.

J'en ai fait un qui ne demande rien.

Carrousel transforme votre iPad en écran calme : photos, citations, journée, une à la fois.

Aucun fil. Aucune notification. Rien ne quitte l'appareil.

Gratuit :
https://apps.apple.com/app/id6786345170
```

### Optional follow-up thread (post as replies to your own tweet)

**2/** `The rule I set myself: it never crops a face. Most photo displays fill the screen and chop the top off a portrait. This one shows the whole photo on a soft blurred bed — and if you do want it to fill the screen, it uses on-device vision to keep faces safely in frame.`

**3/** `The hardest bug was a layer above where I was looking. Portraits kept losing the top of someone's head, and fixing my layout math never helped — because PHImageManager was pre-cropping every photo to the screen's aspect before my code ever saw it.`

**4/** `I also removed the only AI feature before shipping. It suggested seasonal quotes, but it meant the app depended on a server I pay for. Cutting it made "nothing leaves your device" true instead of almost-true. Not every app needs a model in it.`

**5/** `Free, no ads, no account, no upsell. It's bilingual — French first. Built for my own kitchen counter.` + site link

---

## LinkedIn — English

```
Every screen in my house wants something from me.

Notifications, feeds, badges, a scroll that never ends. I wanted the opposite: a screen that just sits there being pleasant, and asks for nothing.

So I built it.

Carrousel turns an iPad into a calm family display. It drifts slowly through your own photos, a few quotes you've chosen, and the day's calendar events and reminders — one at a time, with a long cross-fade. It brightens at breakfast and dims in the evening. There is nothing to check, no inbox, no streak.

Three decisions I care about:

→ It never crops a face. Most photo displays fill the screen and cut the top off a portrait. This one shows the whole photo.

→ Nothing leaves your device. No account, no analytics, no ads, no third-party SDKs. Your photos stay in your library; the app only holds a reference.

→ I removed the one AI feature before launch. It suggested seasonal quotes, but it meant the app depended on a server — and that wasn't worth breaking the promise for.

It's free, bilingual (French first), and on the App Store today.

https://carrousel-app.netlify.app

If you try it, I'd rather hear where it feels wrong than that it's nice. That's the useful part.

#iPadOS #Swift #IndieDev #ProductDesign
```

## LinkedIn — Français

```
Tous les écrans chez moi veulent quelque chose de moi.

Des notifications, des fils, des pastilles rouges, un défilement sans fin. Je voulais l'inverse : un écran qui reste simplement là, agréable, sans rien demander.

Alors je l'ai fait.

Carrousel transforme un iPad en écran familial calme. Il dérive lentement à travers vos propres photos, quelques citations que vous avez choisies, et les rendez-vous et rappels de la journée — une chose à la fois, avec un long fondu. Il s'illumine au déjeuner et se tamise le soir. Rien à consulter, aucune boîte de réception.

Trois décisions qui me tiennent à cœur :

→ Il ne coupe jamais un visage. La plupart des cadres photo remplissent l'écran et tranchent le haut d'un portrait. Celui-ci montre la photo en entier.

→ Rien ne quitte votre appareil. Aucun compte, aucune analyse, aucune publicité, aucun SDK tiers. Vos photos restent dans votre photothèque ; l'app n'en garde qu'une référence.

→ J'ai retiré la seule fonction d'IA avant le lancement. Elle suggérait des citations de saison, mais elle rendait l'app dépendante d'un serveur — et ça ne valait pas la peine de briser la promesse.

Gratuit, bilingue (le français d'abord), et sur l'App Store dès aujourd'hui.

https://carrousel-app.netlify.app

Si vous l'essayez, dites-moi plutôt où ça cloche que si c'est joli. C'est ça qui est utile.

#iPadOS #Swift #DevIndépendant #Design
```

---

## Posting notes

- **Attach an image.** Both platforms weight posts with media far higher. Use
  `store/launch/product-hunt-gallery/1-01-photo.png` (the photo screen) — or
  better, a short screen recording of the actual drift, which is the one thing
  static images can't convey.
- **LinkedIn cuts at ~140 characters on mobile** before "see more". The first two
  lines above are written to survive that cut and still make someone tap.
- **Put the link in the post, not the first comment.** The old "links in comments
  get more reach" trick is no longer reliable and it costs you the click.
- **Don't post FR and EN as separate posts on LinkedIn** — it splits engagement.
  Pick the language of your primary audience; if you want both, put the second
  language in the first comment.
- On **X**, the FR and EN versions *can* be separate posts (different audiences,
  different times of day) — post them a few hours apart.
- **Reply to everyone** for the first few hours. On both platforms, early replies
  are what decides whether the post keeps travelling.
