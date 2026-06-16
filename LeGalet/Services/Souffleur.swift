import Foundation

struct GreetingCard: Identifiable, Decodable {
    var id = UUID()
    let text: String
    let note: String
    enum CodingKeys: String, CodingKey { case text, note }
}

struct QuoteSuggestion: Identifiable, Decodable {
    var id = UUID()
    let text: String
    let author: String
    let windowLabel: String
    enum CodingKeys: String, CodingKey { case text, author, windowLabel }
}

struct SouffleurResult: Decodable {
    let greetings: [GreetingCard]
    let quotes: [QuoteSuggestion]
}

// Calls the deployed house-stack endpoint so the Claude key stays server-side.
// The Opus call can run 25–45s and streams NDJSON (newline heartbeats, then a
// final {result|error} line); we read the whole body and parse the last line.
enum Souffleur {
    static let endpoint = URL(string: "https://le-galet.netlify.app/api/souffleur")!

    struct Request: Encodable {
        let lang: String
        let season: String
        let dateLabel: String
        let tone: String
        let existing: [String]
    }

    private struct Envelope: Decodable {
        let result: SouffleurResult?
        let error: String?
    }

    static func suggest(lang: Lang, tone: String, existing: [String], now: Date = Date()) async throws -> SouffleurResult {
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 90
        let body = Request(
            lang: lang.rawValue,
            season: TimeOfDay.season(now, lang),
            dateLabel: TimeOfDay.dateLabel(now, lang),
            tone: tone,
            existing: existing
        )
        req.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: req)
        let text = String(decoding: data, as: UTF8.self)
        let lines = text.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        guard let last = lines.last, let lastData = last.data(using: .utf8) else {
            throw err(lang)
        }
        let env = try JSONDecoder().decode(Envelope.self, from: lastData)
        if let e = env.error { throw NSError(domain: "Souffleur", code: 1, userInfo: [NSLocalizedDescriptionKey: e]) }
        guard let result = env.result else {
            if let http = response as? HTTPURLResponse, http.statusCode >= 400 { throw err(lang) }
            throw err(lang)
        }
        return result
    }

    private static func err(_ lang: Lang) -> NSError {
        NSError(domain: "Souffleur", code: 0, userInfo: [NSLocalizedDescriptionKey: S.souffleurError(lang)])
    }
}
