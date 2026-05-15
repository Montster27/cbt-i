import Foundation
import SwiftUI

enum WhoopConnectionStatus: Equatable {
    case disconnected
    case connecting
    case connected
}

@MainActor
final class WhoopStore: ObservableObject {

    @Published private(set) var status: WhoopConnectionStatus = .disconnected
    @Published var lastError: String? = nil

    private var accessToken: String?
    private var refreshToken: String?
    private var tokenExpiry: Date?

    private static let keychainSyncedFlagKey = "cbti.keychain.synced.v1"

    init() {
        // One-time cleanup of legacy credentials that used to live on-device.
        // The backend proxy holds them now; the keychain entries are dead bytes.
        Keychain.set(nil, for: "client_id")
        Keychain.set(nil, for: "client_secret")

        // One-time upgrade: rewrite pre-Phase-5 local-only tokens as iCloud-synced
        // so subsequent installs on iPad/iPhone pick up the same connection.
        let defaults = UserDefaults.standard
        if !defaults.bool(forKey: Self.keychainSyncedFlagKey) {
            Keychain.upgradeToSyncable("access_token")
            Keychain.upgradeToSyncable("refresh_token")
            Keychain.upgradeToSyncable("token_expiry")
            defaults.set(true, forKey: Self.keychainSyncedFlagKey)
        }

        accessToken = Keychain.get("access_token")
        refreshToken = Keychain.get("refresh_token")
        if let expiryStr = Keychain.get("token_expiry"),
           let secs = Double(expiryStr) {
            tokenExpiry = Date(timeIntervalSince1970: secs)
        }
        status = accessToken != nil ? .connected : .disconnected
    }

    func connect() async {
        status = .connecting
        lastError = nil
        do {
            let tokens = try await WhoopOAuth.authorize()
            persist(tokens: tokens)
            status = .connected
        } catch {
            status = .disconnected
            lastError = error.localizedDescription
        }
    }

    func disconnect() {
        Keychain.set(nil, for: "access_token")
        Keychain.set(nil, for: "refresh_token")
        Keychain.set(nil, for: "token_expiry")
        accessToken = nil
        refreshToken = nil
        tokenExpiry = nil
        status = .disconnected
    }

    /// Returns a draft filled from the most recent non-nap sleep, enriched with
    /// the cycle's strain and the morning's recovery score when available.
    /// Cycle/recovery fetches are best-effort — a missing one degrades to nil fields, not an error.
    func importLatestSleep() async throws -> SleepLogDraft? {
        do {
            return try await fetchAndAssemble()
        } catch WhoopAPIError.requestFailed(401, _) {
            try await forceRefresh()
            return try await fetchAndAssemble()
        }
    }

    private func fetchAndAssemble() async throws -> SleepLogDraft? {
        let token = try await ensureValidAccessToken()
        let api = WhoopAPI(accessToken: token)

        guard let sleep = try await api.fetchLatestSleep() else { return nil }

        var cycle: WhoopCycle? = nil
        var recovery: WhoopRecovery? = nil
        if let cid = sleep.cycle_id {
            cycle    = (try? await api.fetchCycle(id: cid)) ?? nil
            recovery = (try? await api.fetchRecovery(cycleID: cid)) ?? nil
        }
        return sleep.toDraft(cycle: cycle, recovery: recovery)
    }

    // MARK: - token plumbing

    private func persist(tokens: WhoopTokenResponse) {
        accessToken = tokens.access_token
        refreshToken = tokens.refresh_token ?? refreshToken
        tokenExpiry = Date().addingTimeInterval(TimeInterval(tokens.expires_in))
        Keychain.set(accessToken, for: "access_token")
        if let rt = tokens.refresh_token { Keychain.set(rt, for: "refresh_token") }
        if let exp = tokenExpiry { Keychain.set(String(exp.timeIntervalSince1970), for: "token_expiry") }
    }

    private func ensureValidAccessToken() async throws -> String {
        guard let token = accessToken else {
            throw WhoopAPIError.notAuthenticated
        }
        if let expiry = tokenExpiry, expiry.timeIntervalSinceNow < 60 {
            try await forceRefresh()
            guard let newToken = accessToken else {
                throw WhoopAPIError.notAuthenticated
            }
            return newToken
        }
        return token
    }

    private func forceRefresh() async throws {
        guard let rt = refreshToken else {
            disconnect()
            throw WhoopAPIError.notAuthenticated
        }
        do {
            let tokens = try await WhoopOAuth.refresh(refreshToken: rt)
            persist(tokens: tokens)
        } catch {
            disconnect()
            throw error
        }
    }
}
