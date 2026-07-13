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
    static let back = L(fr: "Retour", en: "Back")
    static let tapToCurate = L(fr: "Toucher pour composer", en: "Tap to compose")

    // Empty / onboarding
    static let emptyTitle = L(fr: "Le carrousel est vide.", en: "The carousel is empty.")
    static let emptyBody = L(fr: "Ajoutez une photo, une pensée ou un rappel — puis laissez l'écran dériver.",
                             en: "Add a photo, a thought, or a reminder — then let the screen drift.")
    static let begin = L(fr: "Commencer", en: "Begin")

    static let ob1Title = L(fr: "Carrousel", en: "Carousel")
    static let ob1Body = L(fr: "Un vieil iPad devient un foyer calme — vos photos, citations, rappels et événements dérivent lentement, un à la fois.",
                           en: "An old iPad becomes a calm hearth — your photos, quotes, reminders and events drift slowly by, one at a time.")
    static let ob2Title = L(fr: "Reliez vos albums et votre agenda.", en: "Connect your albums and calendar.")
    static let ob2Body = L(fr: "Choisissez des photos, écrivez une parole. Carrousel fait dériver vos rappels et vos rendez-vous du jour au bon moment.",
                           en: "Pick photos, write a saying. Carousel drifts your reminders and the day's events in at the right moment.")
    static let ob3Title = L(fr: "Puis posez-le et oubliez-le.", en: "Then prop it up and forget it.")
    static let ob3Body = L(fr: "L'écran s'illumine au déjeuner et se tamise le soir. Aucune notification, aucune décision — juste une chose calme à la fois.",
                           en: "It brightens at breakfast and dims at night. No notifications, no decisions — just one calm thing at a time.")
    static let next = L(fr: "Suivant", en: "Next")
    static let letItDrift = L(fr: "Laisser dériver", en: "Let it drift")
    static let skip = L(fr: "Passer", en: "Skip")
    // Actionable onboarding
    static let obPhotosTitle = L(fr: "Vos photos.", en: "Your photos.")
    static let obPhotosBody = L(fr: "Choisissez quelques photos de famille pour commencer. Vous pourrez ajouter des albums entiers, des citations et plus dans l'atelier.",
                                en: "Pick a few family photos to begin. You can add whole albums, quotes and more in the workshop later.")
    static let obAddPhotos = L(fr: "Choisir des photos", en: "Choose photos")
    static let obPhotosAdded = L(fr: "%d photos prêtes", en: "%d photos ready")
    static let obOnePhotoAdded = L(fr: "1 photo prête", en: "1 photo ready")
    static let obDayTitle = L(fr: "Votre journée, en douceur.", en: "Your day, gently.")
    static let obDayBody = L(fr: "Reliez votre agenda et vos rappels pour les voir dériver au bon moment. C'est optionnel — vous pourrez le faire plus tard.",
                             en: "Connect your calendar and reminders to see them drift in at the right time. Optional — you can do this later.")
    static let obDoneTitle = L(fr: "Posez-le, et laissez-le dériver.", en: "Prop it up, and let it drift.")
    static let obDoneBody = L(fr: "L'écran s'illumine au déjeuner et se tamise le soir. Aucune notification, aucune décision — juste une chose calme à la fois.",
                              en: "It brightens at breakfast and dims at night. No notifications, no decisions — just one calm thing at a time.")
    static let obBegin = L(fr: "Commencer", en: "Begin")
    static let obConnectCalendar = L(fr: "Calendrier", en: "Calendar")
    static let obConnectReminders = L(fr: "Rappels", en: "Reminders")
    // "How it works" step — the two controls
    static let obUseTitle = L(fr: "Vous gardez la main.", en: "You keep control.")
    static let obUseBody = L(fr: "Touchez l'écran à tout moment pour faire apparaître deux boutons :",
                             en: "Tap the display anytime to reveal two buttons:")
    static let obComposeDesc = L(fr: "Le crayon : ajoutez des photos, des citations et des albums, et réglez leur fréquence.",
                                 en: "The pencil: add photos, quotes and albums, and set how often each drifts by.")
    static let obBreathDesc = L(fr: "L'engrenage : réglez le rythme, la taille du texte et la lumière, du jour à la nuit.",
                                en: "The gear: set the pace, the text size, and the light from day to night.")

    // Composer
    static let composerTitle = L(fr: "Composer le carrousel", en: "Compose the carousel")
    static let composerSub = L(fr: "Ce qui suit dérive sur l'écran, un seul à la fois.",
                               en: "These drift across the screen, one at a time.")
    static let addPhoto = L(fr: "Photos", en: "Photos")
    static let addQuote = L(fr: "Citation", en: "Quote")
    static let addReminder = L(fr: "Rappel", en: "Reminder")
    static let importFile = L(fr: "Importer", en: "Import")
    static let importDone = L(fr: "%d citations ajoutées au carrousel.", en: "%d quotes added to the carousel.")
    static let importOne = L(fr: "1 citation ajoutée au carrousel.", en: "1 quote added to the carousel.")
    static let importNone = L(fr: "Aucune nouvelle citation trouvée dans ce fichier.", en: "No new quotes found in that file.")
    static let importFailed = L(fr: "Impossible de lire ce fichier.", en: "Couldn't read that file.")
    static let nothingYet = L(fr: "Rien encore dans le carrousel.", en: "Nothing in the carousel yet.")
    static let itemsCount = L(fr: "%d éléments", en: "%d items")
    static let oneItem = L(fr: "1 élément", en: "1 item")
    static let remove = L(fr: "Retirer", en: "Remove")
    static let hide = L(fr: "Masquer", en: "Hide")
    static let show = L(fr: "Afficher", en: "Show")
    static let edit = L(fr: "Modifier", en: "Edit")
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
        fr: "Pour parcourir vos albums, Carrousel a besoin de l'accès à toutes vos photos (et non à une sélection).",
        en: "To browse your albums, Carousel needs access to all your photos (not a selection).")
    static let openSettings = L(fr: "Ouvrir les Réglages", en: "Open Settings")
    static let photosDenied = L(fr: "Carrousel a besoin d'accéder à vos photos. Activez-le dans Réglages.",
                                en: "Carousel needs access to your photos. Turn it on in Settings.")
    static let frequencyA11y = L(fr: "Fréquence d'apparition", en: "Appearance frequency")
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
    static let reglagesTitle = L(fr: "Le souffle du carrousel", en: "The breath of the carousel")
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
    static let language = L(fr: "Langue", en: "Language")
    static let staysAwake = L(fr: "L'écran reste allumé pendant que le carrousel dérive.",
                              en: "The screen stays awake while the carousel drifts.")

    static let today = L(fr: "Aujourd'hui", en: "Today")
    static let tomorrow = L(fr: "Demain", en: "Tomorrow")
    static let important = L(fr: "Important", en: "Important")

    static let seasonSpring = L(fr: "printemps", en: "spring")
    static let seasonSummer = L(fr: "été", en: "summer")
    static let seasonAutumn = L(fr: "automne", en: "autumn")
    static let seasonWinter = L(fr: "hiver", en: "winter")
}
