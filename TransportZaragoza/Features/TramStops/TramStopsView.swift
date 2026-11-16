import SwiftUI

struct TramStopsView: View {
    
    @StateObject private var viewModel: TramStopsViewModel
    @EnvironmentObject var coordinator: Coordinator
    @State private var selectedDirection: Int = 0
    @State private var reloadID = 0
    
    init(
        viewModel: TramStopsViewModel
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        Text("Líneas de tranvía")
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundColor(.orange)
            .cornerRadius(10)
            .padding(.bottom, 5)
        Group {
            VStack {
                Picker("Dirección", selection: $selectedDirection) {
                    Text("Mago de Oz").tag(0)
                    Text("Parque Goya").tag(1)
                }
                .pickerStyle(.segmented)
                
                List(sortedTramStops) { tramStop in
                    makeNavigationLink(for: tramStop)
                }
                .task(id: reloadID) {
                    await viewModel.getTramStops()
                }
            }
            .navigationTitle("Tranvía")
            .alert("Error", isPresented: $viewModel.showErrorAlert) {
                Button("Cancelar", role: .cancel) { }
                Button("Reintentar") {
                    reloadID += 1
                }
            } message: {
                Text("Error al cargar las paradas")
            }
        }
    }
    
    private var sortedTramStops: [TramStop] {
        viewModel.tramStopsList.filter { tramStop in
            guard let lastDigit = tramStop.id.last, let digit = Int(String(lastDigit)) else {
                return false
            }
            return (selectedDirection == 0) ? (digit % 2 == 0) : (digit % 2 != 0)
        }.sorted {
            guard let id1 = Int($0.id.dropLast()),
                  let id2 = Int($1.id.dropLast()) else { return false }
            return id1 < id2
        }
    }
    
    private func makeNavigationLink(for tramStop: TramStop) -> some View {
        coordinator.createTramStopRowView(tramStop: tramStop)
    }
    
}

#Preview {
    let coordinator = Coordinator()
    return coordinator.createTramStopListView().environmentObject(coordinator)
}
