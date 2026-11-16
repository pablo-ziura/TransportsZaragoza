import SwiftUI
import MapKit
import UIKit

struct BusLineStopDetailView: View {
    let busStop: BusStop
    @StateObject private var viewModel: BusLineDetailViewModel
    @State private var reloadID = 0

    init(busStop: BusStop, viewModel: BusLineDetailViewModel) {
        self.busStop = busStop
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(busStop.title.extractAddress()).font(.title2).accessibilityAddTraits(.isHeader)
                if let coordinate = busStop.location.mapCoordinate {
                    Map(initialPosition: .region(MKCoordinateRegion(
                        center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    ))) { Marker(busStop.title.extractAddress(), coordinate: coordinate) }
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .accessibilityLabel("Ubicación de la parada \(busStop.id)")
                }
                Text("Tiempos de llegada").font(.headline).accessibilityAddTraits(.isHeader)
                switch viewModel.arrivalsState {
                case .idle, .loading:
                    ProgressView("Consultando tiempos…")
                case .content(let arrivals):
                    ForEach(Array(arrivals.enumerated()), id: \.offset) { _, arrival in
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Línea \(arrival.linea) · \(arrival.destino)").font(.headline)
                            Text("Próximo bus: \(arrival.primero)")
                            Text("Siguiente bus: \(arrival.segundo)").foregroundStyle(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityIdentifier("arrival-\(arrival.linea)")
                        Divider()
                    }
                case .empty:
                    Label("No hay información de tiempos disponible para esta parada.", systemImage: "clock")
                case .failed:
                    Label("No se pudieron consultar los tiempos. Comprueba tu conexión.", systemImage: "wifi.exclamationmark")
                }
                Button(viewModel.arrivalsState == .failed ? "Reintentar" : "Actualizar tiempos", systemImage: "arrow.clockwise") {
                    reloadID += 1
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("reload-arrivals")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle("Parada \(busStop.id)")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: reloadID) { await viewModel.getBusStopData(busStopId: busStop.id) }
        .onChange(of: viewModel.arrivalsState) { _, state in
            let message: String
            switch state {
            case .content: message = String(localized: "Tiempos de llegada actualizados")
            case .empty: message = String(localized: "No hay información de tiempos disponible")
            case .failed: message = String(localized: "No se pudieron consultar los tiempos")
            default: return
            }
            UIAccessibility.post(notification: .announcement, argument: message)
        }
    }
}
