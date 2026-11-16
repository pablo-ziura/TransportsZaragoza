import SwiftUI

struct TramStopRowView: View {

    @EnvironmentObject var coordinator: Coordinator
    @ObservedObject var viewModel: TramStopsViewModel
    let tramStop: TramStop

    @State private var isFavorite: Bool

    init(tramStop: TramStop, viewModel: TramStopsViewModel) {
        self.tramStop = tramStop
        self.viewModel = viewModel
        _isFavorite = State(initialValue: false)
    }

    @State private var favoriteTask: Task<Void, Never>?

    var body: some View {

        HStack {
            NavigationLink {
                coordinator.createTramStopDetailView(tramStop: tramStop)
            } label: {
                VStack(alignment: .leading) {
                    Text(tramStop.title).font(.headline)
                    Text("Parada: \(tramStop.id)").font(.subheadline).foregroundStyle(.secondary)
                }
            }
            .accessibilityIdentifier("tram-stop-\(tramStop.id)")
            Spacer()
            Button {
                favoriteTask = Task {
                    if isFavorite { await viewModel.removeFavorite(tramStop: tramStop) }
                    else { await viewModel.addFavorite(tramStop: tramStop) }
                    isFavorite = await viewModel.isFavorite(tramStop: tramStop)
                    favoriteTask = nil
                }
            } label: {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .font(.title2).frame(minWidth: 44, minHeight: 44)
            }
            .buttonStyle(.borderless)
            .disabled(favoriteTask != nil)
            .accessibilityIdentifier("tram-favorite-\(tramStop.id)")
            .accessibilityLabel(isFavorite ? "Quitar de favoritos" : "Añadir a favoritos")
        }
        .task { isFavorite = await viewModel.isFavorite(tramStop: tramStop) }
        .onDisappear { favoriteTask?.cancel() }
    }
}

#Preview {
    let coordinator = Coordinator()
    return coordinator.createTramStopRowView(tramStop: .example).environmentObject(coordinator)
}
