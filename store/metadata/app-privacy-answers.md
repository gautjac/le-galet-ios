# App Privacy questionnaire — recommended answers

App Store Connect → your app → **App Privacy**. This is the "nutrition label."

## Tracking
**Do you or your third-party partners use data for tracking?** → **No.**
The app has no analytics, no ads, no third-party SDKs, no IDFA, and never links
data to a user identity across apps/sites.

## Data collection — recommended answer: **"Data Not Collected"**

You can select **Data Not Collected** for the whole app, and here's the honest
reasoning per data path so you're comfortable defending it:

| Data path | Where it goes | Why it's "not collected" |
|---|---|---|
| **Photos** | Stay on device. Only a `localIdentifier` reference is stored locally; image bytes are never uploaded. | Nothing leaves the device. |
| **Calendar & Reminders** | Read live, shown, never stored or transmitted. | Nothing leaves the device. |
| **Photo location → city name** | A photo's saved coordinate is sent to **Apple's** system geocoder to get a city name for the caption. | A system/OS service, not data you collect; result isn't stored or linked. |

The app sends **nothing you add** off the device: no accounts, no analytics, no
third-party SDKs, and no calls to any server of ours. The only network activity
is downloading a small curated quotes feed (a public read; no personal data is
transmitted). **"Data Not Collected"** is the simplest accurate choice — nothing
is stored or identity-linked. The Privacy Policy (below) describes the on-device
geocoding transparently regardless.

## Privacy Policy URL
Required, and **live**: `https://carrousel-app.netlify.app/privacy` (bilingual).
Paste it into both App Privacy and each localization's metadata.
