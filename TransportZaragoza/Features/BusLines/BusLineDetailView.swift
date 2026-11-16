import SwiftUI
import MapKit

struct BusLineDetailView: View {
    let busLine: String
    @StateObject private var viewModel: BusLineDetailViewModel
    @EnvironmentObject private var coordinator: Coordinator
    @State private var reloadID = 0

    init(viewModel: BusLineDetailViewModel, busLine: String) {
        self.busLine = busLine
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            switch viewModel.stopsState {
            case .idle, .loading:
                ProgressView("Cargando paradas…")
            case .content(let stops):
                List {
                    Map {
                        ForEach(stops) { stop in
                            if let coordinate = stop.location.mapCoordinate {
                                Marker(stop.title.extractAddress(), coordinate: coordinate)
                            }
                        }
                    }
                    .frame(height: 220)
                    .accessibilityLabel("Mapa de paradas de la línea \(busLine)")
                    Section("Paradas") {
                        ForEach(stops) { stop in
                            coordinator.createBusLineStopRowView(busStop: stop, busLine: busLine)
                        }
                    }
                }
            case .empty:
                ContentUnavailableView("Sin paradas", systemImage: "bus", description: Text("No hay paradas disponibles para esta línea."))
            case .failed:
                ContentUnavailableView {
                    Label("No se pudieron cargar las paradas", systemImage: "wifi.exclamationmark")
                } actions: {
                    Button("Reintentar") { reloadID += 1 }
                }
            }
        }
        .navigationTitle("Línea \(busLine)")
        .toolbar { Button("Actualizar", systemImage: "arrow.clockwise") { reloadID += 1 } }
        .task(id: reloadID) { await viewModel.getBusStopsByLine() }
    }
}
