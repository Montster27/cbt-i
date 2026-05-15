import Foundation

enum WhoopAPIError: LocalizedError {
    case notAuthenticated
    case requestFailed(Int, String)
    case decodeFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "Not connected to Whoop. Open Settings to connect."
        case .requestFailed(let code, let body): return "Whoop API error \(code): \(body)"
        case .decodeFailed(let msg): return "Failed to read Whoop response: \(msg)"
        }
    }
}

struct WhoopAPI {
    let accessToken: String

    private static let base = URL(string: "https://api.prod.whoop.com/developer")!

    /// Fetch the most recent non-nap sleep activity. Returns nil if none in the lookback window.
    func fetchLatestSleep(lookbackHours: Int = 36) async throws -> WhoopSleep? {
        let now = Date()
        let start = now.addingTimeInterval(-TimeInterval(lookbackHours) * 3600)

        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]

        var comps = URLComponents(url: Self.base.appendingPathComponent("v2/activity/sleep"), resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            URLQueryItem(name: "limit", value: "10"),
            URLQueryItem(name: "start", value: f.string(from: start)),
            URLQueryItem(name: "end", value: f.string(from: now)),
        ]

        let page: WhoopSleepPage = try await getJSON(url: comps.url!)
        return page.records
            .filter { !$0.nap }
            .sorted { $0.end > $1.end }
            .first
    }

    /// Fetch the cycle (day's strain summary) by ID.
    /// Returns nil for 404 (cycle not found).
    func fetchCycle(id: Int) async throws -> WhoopCycle? {
        let url = Self.base.appendingPathComponent("v2/cycle/\(id)")
        return try await getJSONOptional(url: url)
    }

    /// Fetch the recovery score tied to a cycle. Returns nil if not yet computed (404).
    func fetchRecovery(cycleID: Int) async throws -> WhoopRecovery? {
        let url = Self.base.appendingPathComponent("v2/cycle/\(cycleID)/recovery")
        return try await getJSONOptional(url: url)
    }

    // MARK: - request helpers

    private func getJSON<T: Decodable>(url: URL) async throws -> T {
        var req = URLRequest(url: url)
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw WhoopAPIError.requestFailed(0, "no HTTP response")
        }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "<unreadable>"
            throw WhoopAPIError.requestFailed(http.statusCode, body)
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            let body = String(data: data, encoding: .utf8) ?? "<unreadable>"
            throw WhoopAPIError.decodeFailed("\(error.localizedDescription) — body: \(body.prefix(500))")
        }
    }

    private func getJSONOptional<T: Decodable>(url: URL) async throws -> T? {
        do {
            return try await getJSON(url: url) as T
        } catch WhoopAPIError.requestFailed(404, _) {
            return nil
        }
    }
}
