import Foundation

enum Lang: String, CaseIterable { case fr, en }

// A bilingual string. Le Galet is French-first (Québécois); English where natural.
struct L {
    let fr: String
    let en: String
    func callAsFunction(_ lang: Lang) -> String { lang == .fr ? fr : en }
    func s(_ lang: Lang) -> String { lang == .fr ? fr : en }
}

enum S {
    static let tagline = L(fr: "un foyer calme", en: "a calm hearth")

    // Chrome / nav
    static let compose = L(fr: "Composer", en: "Compose")
    static let settings = L(fr: "Réglages", en: "Settings")
    static let souffleur = L(fr: "Souffleur", en: "Souffleur")
    static let back = L(fr: "Retour", en: "Back")
    static let tapToCurate = L(fr: "Toucher pour composer", en: "Tap to compose")

    // Empty / onboarding
    static let emptyTitle = L(fr: "Le galet est lisse et vide.", en: "The pebble is smooth and empty.")
    static let emptyBody = L(fr: "Ajoutez une photo, une pensée ou un rappel — puis laissez l'écran dériver.",
                             en: "Add a photo, a thought, or a reminder — then let the screen drift.")
    static let begin = L(fr: "Commencer", en: "Begin")

    static let ob1Title = L(fr: "Voici Le Galet.", en: "Meet Le Galet.")
    static let ob1Body = L(fr: "Une vieille tablette devient un foyer calme — vos photos, vos pensées, vos rendez-vous et vos rappels dérivent lentement, un seul à la fois.",
                           en: "An old tablet becomes a calm hearth — your photos, thoughts, events, and reminders drift slowly, one at a time.")
    static let ob2Title = L(fr: "Reliez vos albums et votre agenda.", en: "Connect your albums and calendar.")
    static let ob2Body = L(fr: "Choisissez des photos, écrivez une parole. Le Galet fait dériver vos rappels et vos rendez-vous du jour au bon moment.",
                           en: "Pick photos, write a saying. Le Galet drifts your reminders and the day's events in at the right moment.")
    static let ob3Title = L(fr: "Puis posez-le et oubliez-le.", en: "Then prop it up and forget it.")
    static let ob3Body = L(fr: "L'écran s'illumine au déjeuner et se tamise le soir. Aucune notification, aucune décision — juste une chose calme à la fois.",
                           en: "It brightens at breakfast and dims at night. No notifications, no decisions — just one calm thing at a time.")
    static let next = L(fr: "Suivant", en: "Next")
    static let letItDrift = L(fr: "Laisser dériver", en: "Let it drift")
    static let skip = L(fr: "Passer", en: "Skip")

    // Composer
    static let composerTitle = L(fr: "Composer le galet", en: "Compose the pebble")
    static let composerSub = L(fr: "Ce qui suit dérive sur l'écran, un seul à la fois.",
                               en: "These drift across the screen, one at a time.")
    static let addPhoto = L(fr: "Photos", en: "Photos")
    static let addQuote = L(fr: "Citation", en: "Quote")
    static let addReminder = L(fr: "Rappel", en: "Reminder")
    static let importFile = L(fr: "Importer", en: "Import")
    static let importDone = L(fr: "%d citations ajoutées au galet.", en: "%d quotes added to the pebble.")
    static let importOne = L(fr: "1 citation ajoutée au galet.", en: "1 quote added to the pebble.")
    static let importNone = L(fr: "Aucune nouvelle citation trouvée dans ce fichier.", en: "No new quotes found in that file.")
    static let importFailed = L(fr: "Impossible de lire ce fichier.", en: "Couldn't read that file.")
    static let nothingYet = L(fr: "Rien encore dans le galet.", en: "Nothing in the pebble yet.")
    static let itemsCount = L(fr: "%d éléments", en: "%d items")
    static let oneItem = L(fr: "1 élément", en: "1 item")
    static let remove = L(fr: "Retirer", en: "Remove")
    static let hide = L(fr: "Masquer", en: "Hide")
    static let show = L(fr: "Afficher", en: "Show")
    static let edit = L(fr: "Modifier", en: "Edit")
    static let bySouffleur = L(fr: "soufflé", en: "by souffleur")
    static let live = L(fr: "en direct", en: "live")
    static let liveSources = L(fr: "Sources vivantes", en: "Live sources")
    static let calendarToggle = L(fr: "Faire dériver les rendez-vous du jour", en: "Drift in the day's events")
    static let remindersToggle = L(fr: "Faire dériver les rappels", en: "Drift in reminders")
    static let connect = L(fr: "Relier", en: "Connect")
    static let connected = L(fr: "Relié", en: "Connected")
    static let denied = L(fr: "Refusé — voir Réglages iOS", en: "Denied — see iOS Settings")
    static let whichCalendars = L(fr: "Quels agendas ?", en: "Which calendars?")
    static let whichReminders = L(fr: "Quelles listes ?", en: "Which lists?")
    static let allCalendars = L(fr: "Tous les agendas", en: "All calendars")
    static let allReminders = L(fr: "Toutes les listes", en: "All lists")
    static let someCalendars = L(fr: "%d agendas", en: "%d calendars")
    static let someReminders = L(fr: "%d listes", en: "%d lists")
    static let oneCalendar = L(fr: "1 agenda", en: "1 calendar")
    static let oneReminderList = L(fr: "1 liste", en: "1 list")
    static let sourcePickerHint = L(fr: "Cochez les sources à faire dériver dans l'écran.",
                                    en: "Check the sources to drift into the display.")
    static let noCalendars = L(fr: "Aucun agenda trouvé.", en: "No calendars found.")
    static let noReminderLists = L(fr: "Aucune liste trouvée.", en: "No lists found.")
    static let done = L(fr: "Terminé", en: "Done")
    static let addAlbum = L(fr: "Album", en: "Album")
    static let chooseAlbums = L(fr: "Vos albums", en: "Your albums")
    static let albumTag = L(fr: "Album", en: "Album")
    static let albumPickerHint = L(fr: "Les photos de l'album dérivent dans l'écran et se renouvellent quand vous en ajoutez.",
                                   en: "An album's photos drift into the display and refresh as you add to it.")
    static let noAlbums = L(fr: "Aucun album trouvé. Créez-en un dans l'app Photos.",
                            en: "No albums found. Create one in the Photos app.")
    static let albumsNeedFullAccess = L(
        fr: "Pour parcourir vos albums, Le Galet a besoin de l'accès à toutes vos photos (et non à une sélection).",
        en: "To browse your albums, Le Galet needs access to all your photos (not a selection).")
    static let openSettings = L(fr: "Ouvrir les Réglages", en: "Open Settings")
    static let photoCount = L(fr: "%d photos", en: "%d photos")
    static let onePhoto = L(fr: "1 photo", en: "1 photo")
    static let noPhotos = L(fr: "Vide", en: "Empty")
    static let liveFrequency = L(fr: "Fréquence d'apparition", en: "How often they appear")
    static let liveFrequencyHint = L(fr: "À quelle fréquence les rendez-vous et rappels apparaissent, par rapport aux photos et citations.",
                                     en: "How often events and reminders surface, next to the photos and quotes.")

    // Editor
    static let quoteTitle = L(fr: "Une pensée, une parole", en: "A thought, a saying")
    static let quotePlaceholder = L(fr: "Écrivez ici…", en: "Write here…")
    static let authorPlaceholder = L(fr: "— à qui ? (facultatif)", en: "— by whom? (optional)")
    static let reminderTitle = L(fr: "Un petit rappel", en: "A small reminder")
    static let reminderPlaceholder = L(fr: "Arroser les plantes…", en: "Water the plants…")
    static let whenWindow = L(fr: "Quand l'afficher", en: "When to show it")
    static let always = L(fr: "Toujours", en: "Always")
    static let fromDate = L(fr: "Du", en: "From")
    static let toDate = L(fr: "au", en: "to")
    static let recurrence = L(fr: "Répétition", en: "Repeat")
    static let recOnce = L(fr: "Une fois", en: "Once")
    static let recDaily = L(fr: "Chaque jour", en: "Daily")
    static let recWeekly = L(fr: "Chaque semaine", en: "Weekly")
    static let recYearly = L(fr: "Chaque année", en: "Yearly")
    static let save = L(fr: "Garder", en: "Keep")
    static let cancel = L(fr: "Annuler", en: "Cancel")

    // Réglages
    static let reglagesTitle = L(fr: "Le souffle du galet", en: "The breath of the pebble")
    static let pace = L(fr: "Le rythme", en: "Pace")
    static let fade = L(fr: "Durée du fondu", en: "Fade duration")
    static let dwell = L(fr: "Temps de repos", en: "Dwell time")
    static let textSize = L(fr: "Taille du texte", en: "Text size")
    static let order = L(fr: "L'ordre", en: "Order")
    static let shuffleOn = L(fr: "Aléatoire (selon la fréquence)", en: "Shuffle (by frequency)")
    static let nightDayTitle = L(fr: "Le jour et la nuit", en: "Day & night")
    static let dayStart = L(fr: "Réveil de l'écran", en: "Screen wakes")
    static let nightStart = L(fr: "L'écran se tamise", en: "Screen dims")
    static let nightDim = L(fr: "Pénombre de nuit", en: "Night dimness")
    static let quoteTypeface = L(fr: "La voix des citations", en: "Voice of the quotes")
    static let texture = L(fr: "La texture", en: "Texture")
    static let kenBurns = L(fr: "Lente dérive sur les photos", en: "Slow drift on photos")
    static let showClock = L(fr: "Heure discrète", en: "Quiet clock")
    static let photoMeta = L(fr: "Date et lieu des photos", en: "Photo date & place")
    static let photoMetaHelp = L(
        fr: "Affiche discrètement, sous chaque photo, la date et le lieu enregistrés par l'appareil — quand l'information existe.",
        en: "Subtly shows each photo's captured date and place beneath it — when that information exists.")
    static let fillScreen = L(fr: "Remplir l'écran", en: "Fill the screen")
    static let fillScreenHelp = L(
        fr: "Désactivé, la photo entière s'affiche — jamais de tête coupée. Activé, les photos remplissent l'écran avec un léger recadrage.",
        en: "Off, the whole photo is shown — no cut-off heads. On, photos fill the screen with a slight crop.")
    static let smartCrop = L(fr: "Recadrage intelligent", en: "Smart crop")
    static let smartCropHelp = L(
        fr: "En mode paysage, recadre intelligemment une photo portrait pour remplir l'écran — le sujet (visage, animal) reste au centre — au lieu d'afficher des bandes floues. Et l'inverse en mode portrait.",
        en: "In landscape, intelligently crops a portrait photo to fill the screen — keeping the subject (a face, a pet) centred — instead of showing blurred bars. And the reverse in portrait.")
    static let household = L(fr: "Le foyer", en: "Household")
    static let toneLabel = L(fr: "L'air de la maison", en: "The mood of the home")
    static let tonePlaceholder = L(fr: "p. ex. une famille calme, deux enfants, on aime les mots doux et la mer…",
                                   en: "e.g. a calm family, two kids, fond of gentle words and the sea…")
    static let toneHelp = L(fr: "Le Souffleur s'en sert pour proposer des mots qui vous ressemblent.",
                            en: "The Souffleur uses this to suggest words that feel like you.")
    static let language = L(fr: "Langue", en: "Language")
    static let staysAwake = L(fr: "L'écran reste allumé pendant que le galet dérive.",
                              en: "The screen stays awake while the pebble drifts.")

    // Souffleur
    static let souffleurSub = L(fr: "Une voix discrète qui souffle un mot de saison et quelques citations qui résonnent avec le jour. Vous choisissez ce qui reste.",
                                en: "A quiet voice offering a seasonal greeting and a few quotes that resonate with the day. You choose what stays.")
    static let conjure = L(fr: "Souffler des idées", en: "Offer suggestions")
    static let conjuring = L(fr: "Le souffleur réfléchit…", en: "The souffleur is thinking…")
    static let again = L(fr: "Encore", en: "Again")
    static let greetings = L(fr: "Salutations de saison", en: "Seasonal greetings")
    static let quotes = L(fr: "Citations qui résonnent", en: "Resonant quotes")
    static let add = L(fr: "Ajouter", en: "Add")
    static let added = L(fr: "Ajouté", en: "Added")
    static let suggestedWindow = L(fr: "fenêtre suggérée", en: "suggested window")
    static let souffleurError = L(fr: "Le souffleur s'est tu un instant. Réessayez.",
                                  en: "The souffleur went quiet for a moment. Try again.")

    static let today = L(fr: "Aujourd'hui", en: "Today")

    static let seasonSpring = L(fr: "printemps", en: "spring")
    static let seasonSummer = L(fr: "été", en: "summer")
    static let seasonAutumn = L(fr: "automne", en: "autumn")
    static let seasonWinter = L(fr: "hiver", en: "winter")
}
