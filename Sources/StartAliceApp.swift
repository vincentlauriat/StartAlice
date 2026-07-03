import SwiftUI

@main
struct StartAliceApp: App {
    var body: some Scene {
        WindowGroup("StartAlice") {
            ContentView()
        }
        .windowResizability(.contentSize)
        .commands {
            // Retire le menu « New Window » sans objet pour un launcher.
            CommandGroup(replacing: .newItem) {}
        }
    }
}
