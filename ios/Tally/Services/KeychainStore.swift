import Foundation
import Security

enum KeychainStore {
    private static let service = "app.tally.ios"
    private static let account = "session-token"
    static var sessionToken: String? {
        get {
            let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: account, kSecReturnData as String: true]
            var result: CFTypeRef?
            guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess, let data = result as? Data else { return nil }
            return String(data: data, encoding: .utf8)
        }
        set {
            let base: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: account]
            SecItemDelete(base as CFDictionary)
            guard let newValue, let data = newValue.data(using: .utf8) else { return }
            var item = base; item[kSecValueData as String] = data; SecItemAdd(item as CFDictionary, nil)
        }
    }
}
