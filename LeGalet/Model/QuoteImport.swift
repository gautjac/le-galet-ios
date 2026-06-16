import Foundation

// Pulls quotes out of a file the household drops in. Forgiving by design — people
// bring plain lists, paragraph-per-quote notes, CSVs, or JSON exports. We try, in
// order: JSON (array of strings, or objects with text/quote + author), CSV
// (text[,author]), then plain text (paragraph blocks, else one quote per line),
// lifting a trailing "— Author" attribution wherever it appears.
enum QuoteImport {
    struct Quote { let text: String; let author: String }

    static func parse(data: Data, filename: String) -> [Quote] {
        let name = filename.lowercased()
        if name.hasSuffix(".json"), let j = parseJSON(data) { return j }
        let raw = String(data: data, encoding: .utf8)
            ?? String(data: data, encoding: .isoLatin1) ?? ""
        if raw.trimmed.isEmpty { return [] }
        if name.hasSuffix(".csv") { return parseCSV(raw) }
        if let j = parseJSON(data) { return j }   // a .json without the extension
        return parseText(raw)
    }

    // MARK: JSON
    private static func parseJSON(_ data: Data) -> [Quote]? {
        guard let obj = try? JSONSerialization.jsonObject(with: data) else { return nil }
        let array: [Any]
        if let a = obj as? [Any] { array = a }
        else if let d = obj as? [String: Any],
                let a = (d["quotes"] ?? d["items"] ?? d["data"]) as? [Any] { array = a }
        else { return nil }

        var out: [Quote] = []
        for el in array {
            if let s = el as? String {
                out.append(splitAuthor(s))
            } else if let d = el as? [String: Any] {
                let text = firstString(d, ["text", "quote", "q", "body", "content"])
                let author = firstString(d, ["author", "by", "attribution", "source", "who"])
                if !text.isEmpty { out.append(Quote(text: dequote(text), author: author)) }
            }
        }
        return out.isEmpty ? nil : out
    }

    private static func firstString(_ d: [String: Any], _ keys: [String]) -> String {
        for k in keys { if let v = d[k] as? String { return v.trimmed } }
        return ""
    }

    // MARK: CSV
    private static func parseCSV(_ raw: String) -> [Quote] {
        var out: [Quote] = []
        for (i, cols) in csvRows(raw).enumerated() {
            guard let first = cols.first?.trimmed, !first.isEmpty else { continue }
            if i == 0, ["text", "quote", "citation"].contains(first.lowercased()) { continue } // header
            let author = cols.count > 1 ? cols[1].trimmed : ""
            out.append(Quote(text: dequote(first), author: author))
        }
        return out
    }

    // Minimal RFC-ish CSV: double-quoted fields, "" escape, newlines inside quotes.
    private static func csvRows(_ raw: String) -> [[String]] {
        var rows: [[String]] = [], row: [String] = []
        var field = "", inQuotes = false
        let chars = Array(raw)
        var i = 0
        while i < chars.count {
            let c = chars[i]
            if inQuotes {
                if c == "\"" {
                    if i + 1 < chars.count, chars[i + 1] == "\"" { field.append("\""); i += 1 }
                    else { inQuotes = false }
                } else { field.append(c) }
            } else {
                switch c {
                case "\"": inQuotes = true
                case ",": row.append(field); field = ""
                case "\n", "\r":
                    if c == "\r", i + 1 < chars.count, chars[i + 1] == "\n" { i += 1 }
                    row.append(field); rows.append(row); row = []; field = ""
                default: field.append(c)
                }
            }
            i += 1
        }
        if !field.isEmpty || !row.isEmpty { row.append(field); rows.append(row) }
        return rows
    }

    // MARK: Plain text / Markdown
    private static func parseText(_ raw: String) -> [Quote] {
        let norm = raw.replacingOccurrences(of: "\r\n", with: "\n")
                      .replacingOccurrences(of: "\r", with: "\n")
        if norm.contains("\n\n") {
            // Paragraph per quote: an author may sit on its own dash-led last line.
            var out: [Quote] = []
            for block in norm.components(separatedBy: "\n\n") {
                let lines = block.split(separator: "\n").map { String($0).trimmed }
                    .filter { !$0.isEmpty && !$0.hasPrefix("#") }
                guard !lines.isEmpty else { continue }
                if lines.count >= 2, let last = lines.last, isDashLine(last) {
                    out.append(Quote(text: dequote(lines.dropLast().joined(separator: " ")),
                                     author: stripDash(last)))
                } else {
                    out.append(splitAuthor(lines.joined(separator: " ")))
                }
            }
            return out
        }
        // One quote per line.
        return norm.split(separator: "\n").map { String($0).trimmed }
            .filter { !$0.isEmpty && !$0.hasPrefix("#") }
            .map { splitAuthor($0) }
    }

    // MARK: Attribution + cleanup
    private static func splitAuthor(_ s: String) -> Quote {
        let str = s.trimmed
        // Spaced separators first (safest), then bare em/en dashes.
        for sep in [" — ", " – ", " -- ", " - ", "—", "–"] {
            if let r = str.range(of: sep, options: .backwards) {
                let text = String(str[..<r.lowerBound]).trimmed
                let author = String(str[r.upperBound...]).trimmed
                if !text.isEmpty, !author.isEmpty, author.count <= 80 {
                    return Quote(text: dequote(text), author: author)
                }
            }
        }
        return Quote(text: dequote(str), author: "")
    }

    private static func isDashLine(_ s: String) -> Bool {
        guard let f = s.first else { return false }
        return "—–-•*~".contains(f)
    }
    private static func stripDash(_ s: String) -> String {
        var t = Substring(s)
        while let f = t.first, "—–-•*~ ".contains(f) { t = t.dropFirst() }
        return String(t).trimmed
    }
    private static func dequote(_ s: String) -> String {
        var t = s.trimmed
        for (l, r) in [("\"", "\""), ("'", "'"), ("«", "»"), ("\u{201C}", "\u{201D}"), ("\u{2018}", "\u{2019}")] {
            if t.count >= 2, t.hasPrefix(l), t.hasSuffix(r) {
                t = String(t.dropFirst(l.count).dropLast(r.count)).trimmed
                break
            }
        }
        return t
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
