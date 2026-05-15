import Foundation
import Security

enum Keychain {
    private static let service = "com.montysharma.cbti.whoop"

    /// Writes or removes a value. Stored items are marked `kSecAttrSynchronizable = true`
    /// so they replicate to the user's other Apple devices via iCloud Keychain.
    /// The pre-write delete uses `kSecAttrSynchronizableAny` so we replace both
    /// previously-synced and previously-local copies cleanly.
    static func set(_ value: String?, for account: String) {
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny,
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        guard let value, let data = value.data(using: .utf8) else { return }

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrSynchronizable as String: true,
            kSecValueData as String: data,
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    /// Reads a value, matching both synced and local copies (kSecAttrSynchronizableAny).
    static func get(_ account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func clear() {
        for account in ["client_id", "client_secret", "access_token", "refresh_token", "token_expiry"] {
            set(nil, for: account)
        }
    }

    /// One-time upgrade for a single account from the pre-Phase 5 (local-only) state.
    /// Reads the current value (which matches both states via kSecAttrSynchronizableAny),
    /// then writes it back — set() will replace the local item with a synced one.
    static func upgradeToSyncable(_ account: String) {
        guard let value = get(account) else { return }
        set(value, for: account)
    }
}
