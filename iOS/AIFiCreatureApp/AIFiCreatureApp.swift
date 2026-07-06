import SwiftUI

@main
struct AIFiCreatureApp: App {
    @State private var store = CreatureStore()

    var body: some Scene {
        WindowGroup {
            AppView()
                .environment(store)
        }
    }
}
