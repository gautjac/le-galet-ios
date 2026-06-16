import SwiftUI
import SwiftData

@main
struct LeGaletApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: GaletItem.self, GaletSettings.self)
        } catch {
            fatalError("Le Galet could not open its local store: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
                .tint(.amber)
        }
        .modelContainer(container)
    }
}
