import Foundation
import EventKit
import Combine

// Pulls the household's own Reminders and Calendar events into the rotation as
// live pebbles — never stored, always reflecting the real day. Reminders surface
// near their due time; calendar events drift in across the day they happen.
@MainActor
final class EventBridge: ObservableObject {
    private let store = EKEventStore()
    private var changeObserver: NSObjectProtocol?

    @Published private(set) var reminderPebbles: [Pebble] = []
    @Published private(set) var eventPebbles: [Pebble] = []

    init() {
        // Editing an event/reminder (e.g. adding notes) posts this — re-pull so the
        // new details appear on the display without waiting for a relaunch.
        changeObserver = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged, object: store, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in await self?.refresh() }
        }
    }

    @Published var calendarStatus: EKAuthorizationStatus = EKEventStore.authorizationStatus(for: .event)
    @Published var reminderStatus: EKAuthorizationStatus = EKEventStore.authorizationStatus(for: .reminder)

    // Set from the display language so event subtitles read naturally.
    var lang: Lang = .fr

    // Which calendars / reminder lists to draw from (EKCalendar identifiers).
    // Empty = all. Kept in sync with GaletSettings by RootView.
    var selectedCalendarIDs: [String] = []
    var selectedReminderListIDs: [String] = []

    var calendarGranted: Bool { calendarStatus == .fullAccess }
    var reminderGranted: Bool { reminderStatus == .fullAccess }

    // The calendars / reminder lists the user could choose from, for the picker.
    func eventCalendars() -> [EKCalendar] {
        calendarGranted ? store.calendars(for: .event) : []
    }
    func reminderLists() -> [EKCalendar] {
        reminderGranted ? store.calendars(for: .reminder) : []
    }

    // Resolve a stored ID set to concrete calendars; nil means "all" (also the
    // forgiving fallback when a saved selection no longer matches anything).
    private func chosen(_ ids: [String], _ entity: EKEntityType) -> [EKCalendar]? {
        let all = store.calendars(for: entity)
        guard !ids.isEmpty else { return nil }
        let picked = all.filter { ids.contains($0.calendarIdentifier) }
        return picked.isEmpty ? nil : picked
    }

    // Pebbles to merge into the playlist, honouring the household's toggles.
    func livePebbles(useCalendar: Bool, useReminders: Bool) -> [Pebble] {
        var out: [Pebble] = []
        if useCalendar && calendarGranted { out += eventPebbles }
        if useReminders && reminderGranted { out += reminderPebbles }
        return out
    }

    func requestCalendar() async {
        do {
            _ = try await store.requestFullAccessToEvents()
        } catch { /* denial is fine; status reflects it */ }
        calendarStatus = EKEventStore.authorizationStatus(for: .event)
        await refresh()
    }

    func requestReminders() async {
        do {
            _ = try await store.requestFullAccessToReminders()
        } catch { /* denial is fine */ }
        reminderStatus = EKEventStore.authorizationStatus(for: .reminder)
        await refresh()
    }

    func refresh() async {
        calendarStatus = EKEventStore.authorizationStatus(for: .event)
        reminderStatus = EKEventStore.authorizationStatus(for: .reminder)
        if calendarGranted { loadEvents() }
        if reminderGranted { await loadReminders() }
    }

    // ── Calendar: today's and tomorrow's events as gentle pebbles. All-day
    // events (birthdays, anniversaries — exactly what a family hearth wants to
    // surface) are kept, shown with a day label instead of a time. ──────────────
    private func loadEvents() {
        let cal = Calendar.current
        let now = Date()
        let start = cal.startOfDay(for: now)
        let end = cal.date(byAdding: .day, value: 2, to: start) ?? now
        let predicate = store.predicateForEvents(withStart: start, end: end,
                                                 calendars: chosen(selectedCalendarIDs, .event))
        let events = store.events(matching: predicate)

        let timeFmt = DateFormatter()
        timeFmt.locale = Locale.current
        timeFmt.dateFormat = "HH'h'mm"
        let dayFmt = DateFormatter()
        dayFmt.locale = Locale.current
        dayFmt.setLocalizedDateFormatFromTemplate("EEEE")

        func dayLabel(_ d: Date) -> String {
            cal.isDateInToday(d) ? S.today(lang) : dayFmt.string(from: d).capitalized
        }

        eventPebbles = events
            .filter { ($0.endDate ?? $0.startDate) >= now } // skip what's already done
            .prefix(12)
            .map { ev in
                // Time line: a start–end range for timed events, a day for all-day.
                var sub: String
                if ev.isAllDay {
                    sub = dayLabel(ev.startDate)
                } else {
                    var range = timeFmt.string(from: ev.startDate)
                    if let end = ev.endDate, end > ev.startDate {
                        range += " – \(timeFmt.string(from: end))"
                    }
                    sub = cal.isDateInToday(ev.startDate) ? range : "\(dayLabel(ev.startDate)) · \(range)"
                }
                if let loc = ev.location, !loc.isEmpty { sub += " · \(loc)" }
                return Pebble(
                    id: "evt-\(ev.eventIdentifier ?? UUID().uuidString)",
                    kind: .event,
                    text: ev.title ?? "—",
                    subtitle: sub,
                    notes: Self.detail(notes: ev.notes, url: ev.url),
                    weight: 1
                )
            }
    }

    // The free-text details the household added: the notes field, plus a URL if
    // one was attached. Trimmed and clipped so the card never grows unbounded.
    private static func detail(notes: String?, url: URL?) -> String {
        var parts: [String] = []
        if let n = notes?.trimmingCharacters(in: .whitespacesAndNewlines), !n.isEmpty {
            parts.append(String(n.prefix(600)))
        }
        if let u = url?.absoluteString, !u.isEmpty { parts.append(u) }
        return parts.joined(separator: "\n")
    }

    // ── Reminders: incomplete, due today or overdue within the last day. ────────
    private func loadReminders() async {
        let predicate = store.predicateForIncompleteReminders(
            withDueDateStarting: nil, ending: nil,
            calendars: chosen(selectedReminderListIDs, .reminder))
        let reminders: [EKReminder] = await withCheckedContinuation { cont in
            store.fetchReminders(matching: predicate) { cont.resume(returning: $0 ?? []) }
        }

        let cal = Calendar.current
        let now = Date()
        let timeFmt = DateFormatter()
        timeFmt.locale = Locale.current
        timeFmt.dateFormat = "HH'h'mm"

        reminderPebbles = reminders.compactMap { r -> Pebble? in
            guard let title = r.title, !title.isEmpty else { return nil }
            // Keep undated reminders plus those due from yesterday through today.
            var subtitle = ""
            if let comps = r.dueDateComponents, let due = cal.date(from: comps) {
                let dayDiff = cal.dateComponents([.day], from: cal.startOfDay(for: now),
                                                 to: cal.startOfDay(for: due)).day ?? 0
                if dayDiff > 0 { return nil }            // only today / overdue
                if dayDiff < -1 { return nil }           // not stale beyond yesterday
                if comps.hour != nil { subtitle = timeFmt.string(from: due) }
            }
            return Pebble(
                id: "rem-\(r.calendarItemIdentifier)",
                kind: .reminder,
                text: title,
                subtitle: subtitle,
                notes: Self.detail(notes: r.notes, url: r.url),
                weight: 1
            )
        }
        .prefix(12)
        .map { $0 }
    }
}
