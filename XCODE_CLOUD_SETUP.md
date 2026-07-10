# Xcode Cloud — one-time setup (the GA-macOS build path)

**Why this exists:** this Mac runs **macOS 27 beta**, and during the pre-release
window Apple's App Store validator rejects builds made on a beta macOS with
**ITMS-90111** ("Unsupported SDK…") — even though the SDK (iOS 26.5 / Xcode 26.6)
is correct. Xcode Cloud builds on Apple's **GA-macOS runners**, which sidesteps
that entirely. Use this until this Mac is back on a released macOS.

Everything below is a **one-time** setup. After it, a push to `main` produces a
TestFlight build automatically.

## Already done for you
- ✅ Souffleur-free code + build number **3** committed and pushed to
  `github.com/gautjac/le-galet-ios` (`main`). Build 3 is > the uploaded build 2.
- ✅ The `.xcodeproj` and its **shared `LeGalet` scheme** are committed, so the
  runner needs no `xcodegen`. No external packages → **no `ci_scripts` needed.**
- ✅ `dist/` (local ship artifacts) added to `.gitignore`.

## What you do in Xcode (≈5 min, needs your Apple ID)

1. Open **`LeGalet.xcodeproj`** in Xcode (either Xcode version is fine for setup).
2. Menu **Integrate → Create Workflow…** (or the cloud icon in the Report
   navigator). Pick the **LeGalet** app.
3. **Grant access** when prompted: sign in with your Apple ID (Account Holder /
   Admin), and authorize Xcode Cloud for the **GitHub** repo
   `gautjac/le-galet-ios`.
4. Configure the workflow:
   - **Name:** `TestFlight Release`
   - **Start Conditions:** Branch Changes → `main` (or set to **Manual** if you'd
     rather trigger each build yourself).
   - **Environment → Xcode:** choose **Xcode 26.6 (Latest Release)**.
     ⚠️ **Do NOT choose Xcode 27 beta** — there's no RC yet, and beta-built
     binaries get rejected too. The released Xcode on a GA-macOS runner is the fix.
   - **Actions:** keep **Archive** (iOS). Set **Deployment Preparation** to
     **TestFlight & App Store**.
   - **Post-Actions:** add **TestFlight Internal Testing** (your team gets it
     immediately) — optional but handy.
5. When prompted, **grant App Store Connect access** (Xcode Cloud manages signing
   for you — no certs to wrangle).
6. **Save.** Xcode Cloud starts the first build automatically (or hit **Start
   Build**). ~10–15 min; it uploads **build 3** to App Store Connect.

## After the first cloud build lands
1. App Store Connect → **Carousel** → your **1.0** version → **Build** → select
   **build 3** (from Xcode Cloud).
2. Everything else on the 1.0 record is already set (metadata, screenshots,
   contact, categories, privacy). Finish the **Age Rating** questionnaire if you
   haven't, then **Submit for Review**.

## Build numbers on later runs
Each App Store build needs a unique, higher build number. Either:
- In the workflow's **Archive** action, enable **"Automatically manage build
  number"** (Xcode Cloud increments per build — recommended), **or**
- Bump `CURRENT_PROJECT_VERSION` in `project.yml`, run `xcodegen generate`,
  commit, and push.

## Notes
- Xcode Cloud's free tier is 25 compute-hours/month — ample for this app.
- The local `_outillage/ship-ios.sh` still works and is faster **once this Mac is
  on a released macOS again** — at that point you can drop Xcode Cloud if you like.
