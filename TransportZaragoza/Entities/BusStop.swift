import Foundation

struct BusStop: Codable, Identifiable, Sendable, Equatable {
    let id: String
    let title: String
    let location: Coordinates
    let busLine: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title = "title"
        case location = "geometry"
        case busLine
    }
    
    static var example: BusStop {
        .init(
            id: "tuzsa-688",
            title: "(688) P. Reyes De Aragón N.º 24 Líneas: 58, 41, 22",
            location: Coordinates(coordinates: [-0.884626111810379,41.68681362815634]),
            busLine: "22"
        )
    }
}

struct BusStopData: Decodable, Sendable, Equatable {
    let geometry: Geometry
    let destinos: [ArrivalBus]

    init(geometry: Geometry, destinos: [ArrivalBus]) {
        self.geometry = geometry
        self.destinos = destinos
    }

    private enum CodingKeys: String, CodingKey { case geometry, destinos }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        geometry = try container.decode(Geometry.self, forKey: .geometry)
        destinos = try container.decodeIfPresent([ArrivalBus].self, forKey: .destinos) ?? []
    }
}

struct BusStopDetail: Sendable {
    let busStop: BusStop
    let details: BusStopData
}

struct Geometry: Decodable, Sendable, Equatable {
    let type: String
    let coordinates: [Double]
}

struct ArrivalBus: Decodable, Sendable, Equatable {
    let linea: String
    let destino: String
    let primero: String
    let segundo: String
}
