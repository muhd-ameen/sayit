import Security
import Foundation

enum KeychainService {
    private static let service = "xyz.avocadonation.sayit"
    private static let account = "anthropic-api-key"

    /// Removes any personal Anthropic key left by an older version that asked
    /// users to bring their own. The app now refines through a server-side proxy.
    static func deleteAPIKey() {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
