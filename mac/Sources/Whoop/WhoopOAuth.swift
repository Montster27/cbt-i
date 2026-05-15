#if os(macOS)
import AppKit
#else
import UIKit
#endif
import AuthenticationServices
import Foundation

enum WhoopOAuthError: LocalizedError {
    case configUnavailable
    case userCancelled
    case stateMismatch
    case noCode
    case proxyFailed(Int, String)
    case underlying(Error)

    var errorDescription: String? {
        switch self {
        case .configUnavailable: return "Couldn't fetch OAuth configuration from the backend. Check connectivity."
        case .userCancelled: return "Sign-in was cancelled."
        case .stateMismatch: return "OAuth state mismatch — possible tampering. Try again."
        case .noCode: return "Whoop did not return an authorization code."
        case .proxyFailed(let code, let msg): return "Proxy returned \(code): \(msg)"
        case .underlying(let err): return err.localizedDescription
        }
    }
}

enum WhoopOAuth {
    static let authURL = URL(string: "https://api.prod.whoop.com/oauth/oauth2/auth")!
    static let backendBase = URL(string: "https://cbt-i.vercel.app")!
    static let callbackScheme = "cbti"

    // MARK: - Config (fetched from backend)

    struct Config: Decodable {
        let client_id: String
        let redirect_uri: String
        let scopes: String
    }

    static func fetchConfig() async throws -> Config {
        let url = backendBase.appendingPathComponent("api/whoop/config")
        var req = URLRequest(url: url)
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw WhoopOAuthError.configUnavailable
        }
        do {
            return try JSONDecoder().decode(Config.self, from: data)
        } catch {
            throw WhoopOAuthError.configUnavailable
        }
    }

    // MARK: - Authorization flow

    /// Runs the full authorize-then-exchange flow against the backend proxy.
    /// The client secret never touches the device.
    static func authorize() async throws -> WhoopTokenResponse {
        let config = try await fetchConfig()
        let state = randomState()

        var comps = URLComponents(url: authURL, resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: config.client_id),
            URLQueryItem(name: "redirect_uri", value: config.redirect_uri),
            URLQueryItem(name: "scope", value: config.scopes),
            URLQueryItem(name: "state", value: state),
        ]
        let authorizeURL = comps.url!

        let callbackURL = try await runWebAuthSession(url: authorizeURL)
        let (code, returnedState) = parseCallback(callbackURL)
        guard let code else { throw WhoopOAuthError.noCode }
        guard returnedState == state else { throw WhoopOAuthError.stateMismatch }

        return try await postToProxy(path: "api/whoop/exchange", body: ["code": code])
    }

    static func refresh(refreshToken: String) async throws -> WhoopTokenResponse {
        return try await postToProxy(path: "api/whoop/refresh", body: ["refresh_token": refreshToken])
    }

    // MARK: - private

    @MainActor
    private static func runWebAuthSession(url: URL) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: callbackScheme
            ) { callbackURL, error in
                if let error {
                    if let asError = error as? ASWebAuthenticationSessionError, asError.code == .canceledLogin {
                        continuation.resume(throwing: WhoopOAuthError.userCancelled)
                    } else {
                        continuation.resume(throwing: WhoopOAuthError.underlying(error))
                    }
                    return
                }
                guard let callbackURL else {
                    continuation.resume(throwing: WhoopOAuthError.noCode)
                    return
                }
                continuation.resume(returning: callbackURL)
            }
            session.presentationContextProvider = PresentationProvider.shared
            session.prefersEphemeralWebBrowserSession = false
            session.start()
        }
    }

    private static func parseCallback(_ url: URL) -> (code: String?, state: String?) {
        let comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let items = comps?.queryItems ?? []
        let code = items.first(where: { $0.name == "code" })?.value
        let state = items.first(where: { $0.name == "state" })?.value
        return (code, state)
    }

    private static func postToProxy(path: String, body: [String: String]) async throws -> WhoopTokenResponse {
        let url = backendBase.appendingPathComponent(path)
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw WhoopOAuthError.proxyFailed(0, "no HTTP response")
        }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "<unreadable>"
            throw WhoopOAuthError.proxyFailed(http.statusCode, body)
        }
        do {
            return try JSONDecoder().decode(WhoopTokenResponse.self, from: data)
        } catch {
            let body = String(data: data, encoding: .utf8) ?? "<unreadable>"
            throw WhoopOAuthError.proxyFailed(200, "decode failed — body: \(body)")
        }
    }

    private static func randomState() -> String {
        var bytes = [UInt8](repeating: 0, count: 16)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

@MainActor
private final class PresentationProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = PresentationProvider()
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        #if os(macOS)
        return NSApplication.shared.keyWindow ?? ASPresentationAnchor()
        #else
        // Find the first foreground active window across connected scenes.
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
        return scenes.flatMap { $0.windows }.first(where: { $0.isKeyWindow }) ?? ASPresentationAnchor()
        #endif
    }
}
