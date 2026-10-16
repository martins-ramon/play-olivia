import SwiftUI

@main
struct OliviaPlayApp: App {
    @StateObject private var app = AppModel()
    @StateObject private var launch = AppLaunchState()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            AppRootView(launch: launch)
                .environmentObject(app)
                .preferredColorScheme(.light)
                .onChange(of: scenePhase) { phase in
                    if phase != .active { app.stopSpeaking() }
                }
        }
        #if os(macOS)
        .defaultSize(width: 1080, height: 810)
        #endif
    }
}
