import SwiftUI

@main
struct TransportZaragozaApp: App {
    
    @StateObject private var coordinator = Coordinator()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(coordinator)
        }
    }
}
