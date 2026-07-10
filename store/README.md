# Carousel / Carrousel — App Store & TestFlight kit

Everything needed to put Carousel on TestFlight and fill out the App Store
Connect listing, in **English and French**. All copy is within Apple's character
limits. This folder is the source of truth; regenerate the screenshots anytime.

```
store/
├── README.md                     ← you are here (the checklist)
├── icon-1024.png                 ← marketing icon (1024², opaque, no alpha)
├── metadata/
│   ├── en.md                     ← App Store fields, English
│   ├── fr.md                     ← App Store fields, French
│   ├── testflight.md             ← beta description, what-to-test, review notes
│   ├── app-privacy-answers.md    ← the App Privacy "nutrition label" answers
│   ├── privacy-policy.en.md      ← host this; URL is required
│   ├── privacy-policy.fr.md
│   ├── support.en.md             ← host this; Support URL is required
│   └── support.fr.md
└── screenshots/
    ├── generate.mjs              ← `node generate.mjs` rebuilds the set
    └── out/                      ← 10 PNGs, 2752×2064 (13-inch iPad)
```

---

## What's already done in the build (no action needed)

- ✅ **Version 1.0.0**, build 1 (`project.yml`).
- ✅ **Encryption-exempt declared** (`ITSAppUsesNonExemptEncryption=false`) — App
  Store Connect won't ask the export-compliance question on upload.
- ✅ **iPad-only** (`UIDeviceFamily = [2]`).
- ✅ **Marketing icon** 1024² opaque (no alpha) — passes icon validation.
- ✅ Localized app name (Carousel / Carrousel) and permission strings.

---

## Step 1 — Marketing / Support / Privacy pages ✅ DONE

The bilingual landing page (`../landing/`) is **live** at
**https://carrousel-app.netlify.app** (Netlify site `carrousel-app`, team
"La shop"). The App Store Connect URLs are ready to paste:

- **Marketing:** `https://carrousel-app.netlify.app`
- **Privacy Policy:** `https://carrousel-app.netlify.app/privacy`
- **Support:** `https://carrousel-app.netlify.app/support`

To redeploy after editing `../landing/`:
`netlify deploy --dir ../landing --prod --site carrousel-app`

## Step 2 — Create the app record in App Store Connect

1. **My Apps → ➕ → New App.** Platform: iOS. Name: **Carousel** (see the name
   note in `metadata/en.md` — it must be globally unique; have a fallback ready).
   Primary language: **French (Canada)**. Bundle ID: **com.jac.LeGalet**. SKU:
   anything, e.g. `carousel-ios`.
2. **App Information:** Primary category **Lifestyle**, secondary **Photo &
   Video**. Set the Privacy Policy URL.
3. **Pricing:** Free.
4. **App Privacy:** follow `metadata/app-privacy-answers.md` (Tracking → No;
   recommend **Data Not Collected**).
5. **Age rating:** answer "None" to everything → **4+**. Not Made for Kids.

## Step 3 — Fill the two localizations

Add **English (U.S.)** and **French** localizations, then paste from
`metadata/en.md` and `metadata/fr.md`:

| App Store Connect field | File section |
|---|---|
| Name | "App Name" |
| Subtitle | "Subtitle" |
| Promotional Text | "Promotional Text" |
| Description | "Description" |
| Keywords | "Keywords" |
| What's New | "What's New in This Version" |
| Support / Marketing URL | "URLs" |
| Screenshots (13-inch iPad) | `screenshots/out/*-en.png` / `*-fr.png` |

Upload the five `*-en.png` to the English localization and the five `*-fr.png`
to the French one (drag in numeric order 01–05).

## Step 4 — Archive & upload the build (needs Xcode + your Apple ID)

This part can't be done headlessly — it needs your signing identity.

1. In Xcode: open `LeGalet.xcodeproj`, select **Any iOS Device (arm64)** as the
   destination.
2. Make sure Signing is **Automatic** with your team (9WZ66DZ69J) and a
   Distribution profile (Xcode handles this on first archive).
3. **Product → Archive.**
4. In the Organizer: **Distribute App → TestFlight & App Store → Upload.**
5. Wait for processing (a few minutes), then the build appears under TestFlight.

> CLI alternative (still needs your credentials): `xcodebuild -scheme LeGalet
> -archivePath build/Carousel.xcarchive archive` then `xcodebuild
> -exportArchive …` with an App Store export options plist, or upload the `.ipa`
> with `xcrun altool`/Transporter.

## Step 5 — TestFlight

1. **TestFlight tab → Test Information:** paste Beta App Description, feedback
   email, marketing/privacy URLs from `metadata/testflight.md`.
2. For the build, paste **What to Test** and the **Beta App Review notes**
   (also in `testflight.md`).
3. **Internal testers** (your team) get it immediately — fastest first taste.
4. **External testers:** create a group, add emails or enable the **public
   link**, submit for **Beta App Review** (uses the notes above; usually approved
   within a day). Then share the link.

## Step 6 — (Later) Submit for App Store review

When you're ready to leave beta: attach the build to the **1.0** version, make
sure all localizations + screenshots are set, and **Submit for Review**. The
same metadata here applies.

---

### Regenerating screenshots
```
cd store/screenshots && node generate.mjs
```
Edit the `COPY` object in `generate.mjs` to tweak headlines or sample content;
re-run to rebuild all 10 at the exact required size.
