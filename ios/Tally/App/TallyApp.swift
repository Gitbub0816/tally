import SwiftUI

@main
struct TallyApp: App {
    @UIApplicationDelegateAdaptor(NotificationDelegate.self) private var notificationDelegate
    @StateObject private var store = TallyStore(environment: .current)

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
                .onReceive(NotificationCenter.default.publisher(for: .tallyDeviceTokenReady)) { _ in
                    Task { await store.registerDeviceIfAvailable() }
                }
        }
    }
}
