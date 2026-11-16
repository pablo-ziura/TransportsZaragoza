import SwiftUI

struct BusLineStopRowView: View {
    @EnvironmentObject private var coordinator: Coordinator
    @ObservedObject var viewModel: BusLineDetailViewModel
    let busStop: BusStop
    let busLine: String
    @State private var isFavorite = false
    @State private var favoriteTask: Task<Void, Never>?

    init(busStop: BusStop, busLine: String, viewModel: BusLineDetailViewModel) {
        self.busStop = busStop
        self.busLine = busLine
        self.viewModel = viewModel
    }

    var body: some View {
        HStack {
            NavigationLink {
                coordinator.createBusLineStopDetailView(busStop: BusStop(
                    id: busStop.id, title: busStop.title, location: busStop.location, busLine: busLine
                ))
            } label: {
                VStack(alignment: .leading) {
                    Text(busStop.title.extractAddress()).font(.headline)
                    Text("Parada: \(busStop.id)").font(.subheadline).foregroundStyle(.secondary)
                }
            }
            .accessibilityIdentifier("bus-stop-\(busStop.id)")
            Button {
                favoriteTask?.cancel()
                favoriteTask = Task {
                    let newValue = !isFavorite
                    await viewModel.setFavorite(newValue, busStop: busStop, busLine: busLine)
                    isFavorite = await viewModel.isFavorite(busStop: busStop, busLine: busLine)
                    favoriteTask = nil
                }
            } label: {
                Image(systemName: isFavorite ? "star.fill" : "star").font(.title2)
                    .frame(minWidth: 44, minHeight: 44)
            }
            .buttonStyle(.borderless)
            .disabled(favoriteTask != nil)
            .accessibilityLabel(isFavorite ? "Quitar de favoritos" : "Añadir a favoritos")
            .accessibilityValue("Parada \(busStop.id), línea \(busLine)")
            .accessibilityIdentifier("favorite-\(busStop.id)")
        }
        .task { isFavorite = await viewModel.isFavorite(busStop: busStop, busLine: busLine) }
        .onDisappear { favoriteTask?.cancel() }
    }
}
