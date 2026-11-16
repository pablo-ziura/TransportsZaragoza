import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var coordinator: Coordinator
    @State private var showSplashScreen = true

    var body: some View {
        if showSplashScreen {
            coordinator.createSplashScreenView(isActive: $showSplashScreen)
        } else {
            NavigationStack { MainMenuView() }
        }
    }
}

struct MainMenuView: View {
    @EnvironmentObject private var coordinator: Coordinator

    var body: some View {
        List {
            Image("app_logo_image")
                .resizable().scaledToFit().frame(maxWidth: .infinity, maxHeight: 180)
                .accessibilityHidden(true)
            NavigationLink { coordinator.createTramStopListView() } label: {
                Label("Tranvía", systemImage: "tram.fill")
            }
            NavigationLink { coordinator.createBusLinesView() } label: {
                Label("Autobuses", systemImage: "bus.fill")
            }
            .accessibilityIdentifier("menu-buses")
            NavigationLink { coordinator.createFavoriteListView() } label: {
                Label("Favoritos", systemImage: "star.fill")
            }
            .accessibilityIdentifier("menu-favorites")
        }
        .navigationTitle("Transportes Zaragoza")
    }
}

#Preview { ContentView().environmentObject(Coordinator()) }
