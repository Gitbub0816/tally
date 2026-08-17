import SwiftUI

@main
struct TallyApp: App {
    @UIApplicationDelegateAdaptor(NotificationDelegate.self) private var notificationDelegate
    @StateObject private var store = TallyStore(environment: .current)
    @AppStorage("tally.appearance") private var appearance = "system"

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(colorScheme)
                .onReceive(NotificationCenter.default.publisher(for: .tallyDeviceTokenReady)) { _ in
                    Task { await store.registerDeviceIfAvailable() }
                }
        }
    }

    private var colorScheme: ColorScheme? {
        switch appearance {
        case "light": .light
        case "dark": .dark
        default: nil
        }
    }
}
