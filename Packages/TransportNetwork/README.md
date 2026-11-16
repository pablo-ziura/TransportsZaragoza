# TransportNetwork

Cliente HTTP genérico con Swift 6.1, Foundation y OSLog. Compatible con iOS 17 y macOS 13; sin dependencias externas.

```swift
import Foundation
import TransportNetwork

struct Stop: Decodable, Sendable {
    let id: String
}

let client = NetworkClient(baseURL: URL(string: "https://example.com/api")!)
let stop: Stop = try await client.get(endpoint: "stops/688", params: nil, headers: nil)
```

`NetworkClientProtocol` expone GET y POST. Se puede inyectar una URLSession configurada o un `HTTPTransport: Sendable`. Cada petición crea su JSONDecoder y comprueba cancelación antes del transporte y después de recibir y decodificar la respuesta.

`NetworkError` distingue URL inválida, transporte, respuesta no HTTP, estado HTTP y fallos de codificación/decodificación. Los errores HTTP incluyen un máximo de 4 KiB del cuerpo para diagnóstico. No se registran cuerpos ni cabeceras en logs.

```sh
swift test --package-path Packages/TransportNetwork
```
