import Foundation

enum TimeOfDay {
    static func minutes(_ date: Date) -> Int {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }

    static func isNight(_ now: Date, _ s: GaletSettings) -> Bool {
        let m = minutes(now)
        if s.nightStartMinutes > s.dayStartMinutes {
            return m >= s.nightStartMinutes || m < s.dayStartMinutes
        }
        return m >= s.nightStartMinutes && m < s.dayStartMinutes
    }

    // 0 = full day brightness, 1 = deepest night. Eased over a soft ramp on
    // either side of each threshold so crossing it is a fade, not a cut.
    static func nightFactor(_ now: Date, _ s: GaletSettings) -> Double {
        let ramp = 30.0
        let m = Double(minutes(now))
        func dist(_ target: Int) -> Double {
            var d = abs(m - Double(target))
            d = min(d, 1440 - d)
            return d
        }
        let edge = min(dist(s.dayStartMinutes), dist(s.nightStartMinutes))
        let t = min(1, edge / ramp)
        return isNight(now, s) ? t : 0
    }

    static func clockLabel(_ now: Date, _ lang: Lang) -> String {
        let c = Calendar.current.dateComponents([.hour, .minute], from: now)
        let h = c.hour ?? 0, m = c.minute ?? 0
        let mm = String(format: "%02d", m)
        if lang == .en {
            let h12 = (h + 11) % 12 + 1
            return "\(h12):\(mm) \(h < 12 ? "am" : "pm")"
        }
        return "\(String(format: "%02d", h)) h \(mm)"
    }

    static func season(_ now: Date, _ lang: Lang) -> String {
        let mo = Calendar.current.component(.month, from: now)
        switch mo {
        case 12, 1, 2: return S.seasonWinter(lang)
        case 3, 4, 5: return S.seasonSpring(lang)
        case 6, 7, 8: return S.seasonSummer(lang)
        default: return S.seasonAutumn(lang)
        }
    }

    static func dateLabel(_ now: Date, _ lang: Lang) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: lang == .fr ? "fr_CA" : "en_CA")
        f.dateFormat = "EEEE d MMMM"
        return f.string(from: now)
    }

    // Does a stored reminder belong in the rotation at `now`?
    static func reminderActive(_ item: GaletItem, _ now: Date) -> Bool {
        guard item.kind == .reminder else { return true }
        guard item.startAt != nil || item.endAt != nil else { return true }
        let cal = Calendar.current

        if item.recurrence == .once {
            if let s = item.startAt, now < s { return false }
            if let e = item.endAt, now > e { return false }
            return true
        }
        switch item.recurrence {
        case .daily:
            let ms = item.startAt.map { minutes($0) } ?? 0
            let me = item.endAt.map { minutes($0) } ?? 1440
            let m = minutes(now)
            return m >= min(ms, me) && m <= max(ms, me)
        case .weekly:
            let day = cal.component(.weekday, from: now)
            let sd = item.startAt.map { cal.component(.weekday, from: $0) } ?? day
            let ed = item.endAt.map { cal.component(.weekday, from: $0) } ?? sd
            return day >= min(sd, ed) && day <= max(sd, ed)
        case .yearly:
            let doy = cal.ordinality(of: .day, in: .year, for: now) ?? 0
            let sd = item.startAt.flatMap { cal.ordinality(of: .day, in: .year, for: $0) } ?? doy
            let ed = item.endAt.flatMap { cal.ordinality(of: .day, in: .year, for: $0) } ?? sd
            return doy >= min(sd, ed) && doy <= max(sd, ed)
        case .once:
            return true
        }
    }
}
