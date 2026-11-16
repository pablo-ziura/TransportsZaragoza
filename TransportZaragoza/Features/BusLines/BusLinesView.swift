import SwiftUI

struct BusLinesView: View {
    @StateObject private var viewModel: BusLinesViewModel
    @EnvironmentObject private var coordinator: Coordinator
    @State private var reloadID = 0

    init(viewModel: BusLinesViewModel) { _viewModel = StateObject(wrappedValue: viewModel) }

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView("Cargando líneas…")
            case .content(let lines):
                List(lines, id: \.self) { line in
                    NavigationLink {
                        coordinator.createBusLineDetailView(busLine: line)
                    } label: { Label("Línea \(line)", systemImage: "bus.fill") }
                    .accessibilityIdentifier("bus-line-\(line)")
                }
                .refreshable { await viewModel.getBusLines(updateData: true) }
            case .empty:
                ContentUnavailableView("Sin líneas disponibles", systemImage: "bus", description: Text("Actualiza para consultar de nuevo el catálogo."))
            case .failed:
                ContentUnavailableView("No se pudieron cargar las líneas", systemImage: "wifi.exclamationmark", description: Text("Comprueba tu conexión y vuelve a intentarlo."))
            }
        }
        .navigationTitle("Autobuses")
        .toolbar { Button("Actualizar", systemImage: "arrow.clockwise") { reloadID += 1 } }
        .safeAreaInset(edge: .bottom) {
            if viewModel.state == .failed || viewModel.state == .empty {
                Button("Reintentar") { reloadID += 1 }.buttonStyle(.borderedProminent).padding()
            }
        }
        .task(id: reloadID) { await viewModel.getBusLines(updateData: reloadID > 0) }
    }
}
