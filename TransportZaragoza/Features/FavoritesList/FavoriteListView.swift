import SwiftUI

struct FavoriteListView: View {
    @StateObject private var viewModel: FavoriteListViewModel
    @EnvironmentObject private var coordinator: Coordinator
    @State private var selectedTransport = 0

    init(viewModel: FavoriteListViewModel) { _viewModel = StateObject(wrappedValue: viewModel) }

    var body: some View {
        VStack {
            Picker("Transporte", selection: $selectedTransport) {
                Text("Tranvía").tag(0)
                Text("Autobús").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()
            if selectedTransport == 0 {
                List(viewModel.favoriteTramStops) { stop in
                    coordinator.createTramStopRowView(tramStop: stop)
                }
                .task { await viewModel.getFavoritesTramStops() }
            } else {
                List(Array(viewModel.favoriteBusStops.enumerated()), id: \.offset) { _, stop in
                    coordinator.createBusLineStopRowView(busStop: stop, busLine: stop.busLine ?? "")
                        .id("\(stop.id)-\(stop.busLine ?? "")")
                }
                .task { await viewModel.getFavoritesBusStops() }
            }
        }
        .navigationTitle("Favoritos")
    }
}

#Preview {
    let coordinator = Coordinator()
    return coordinator.createFavoriteListView().environmentObject(coordinator)
}
