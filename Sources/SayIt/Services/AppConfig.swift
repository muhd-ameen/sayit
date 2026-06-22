import Foundation

/// App-wide configuration resolved at runtime.
enum AppConfig {
    /// URL of the refine proxy that holds the Anthropic key server-side.
    static let refineURL = URL(string: "https://sayit.avocadonation.xyz/api/refine")!

    /// Token identifying this app to the proxy. Injected into the bundle's
    /// Info.plist at build time (see Makefile); falls back to the environment
    /// for `swift run` development. Not a real secret — it is rate-limited and
    /// rotatable server-side, never the raw Anthropic key.
    static let appToken: String = {
        if let token = Bundle.main.object(forInfoDictionaryKey: "SayItAppToken") as? String,
           !token.isEmpty {
            return token
        }
        return ProcessInfo.processInfo.environment["SAYIT_APP_TOKEN"] ?? ""
    }()
}
