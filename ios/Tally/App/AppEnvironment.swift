import Foundation

struct AppEnvironment {
    let apiBaseURL: URL?
    let isDemo: Bool

    static let demo = AppEnvironment(apiBaseURL: nil, isDemo: true)

    static var current: AppEnvironment {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "TALLYAPIBaseURL") as? String,
              !value.isEmpty,
              let url = URL(string: value) else { return .demo }
        return AppEnvironment(apiBaseURL: url, isDemo: false)
    }
}
