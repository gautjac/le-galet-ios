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
| **Souffleur (optional)** | Season, date, a short tone description you type, and existing quote text are sent to your own server (→ Anthropic) only when you invoke it. | Ephemeral: used solely to generate the suggestion, not stored, not linked to identity, not used for tracking. Qualifies for Apple's optional-disclosure exception. |

### If you'd rather be maximally conservative
If you prefer to disclose the Souffleur path instead of relying on the
ephemeral-data exception, declare exactly one item:
- **Data type:** *User Content* (the tone text / quotes you type)
- **Used for:** *App Functionality* only
- **Linked to identity:** **No**
- **Used for tracking:** **No**

Either answer is defensible. "Data Not Collected" is the simplest accurate
choice given nothing is stored or identity-linked. The Privacy Policy (below)
describes both the geocoding and the Souffleur transparently regardless.

## Privacy Policy URL
Required. Host `privacy-policy.en.md` (and the FR version) and paste the URL
into both App Privacy and each localization's metadata.
