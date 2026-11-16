import Foundation
import OSLog

public protocol NetworkClientProtocol: Sendable {
    func get<Output: Decodable & Sendable>(
        endpoint: String, params: [String: String]?, headers: [String: String]?
    ) async throws -> Output
    func post<Output: Decodable & Sendable>(
        endpoint: String, params: [String: String]?, headers: [String: String]?, body: Data
    ) async throws -> Output
}

public extension NetworkClientProtocol {
    func post<Input: Encodable & Sendable, Output: Decodable & Sendable>(
        endpoint: String, params: [String: String]? = nil,
        headers: [String: String]? = nil, data: Input
    ) async throws -> Output {
        let body: Data
        do { body = try JSONEncoder().encode(data) }
        catch let error as EncodingError { throw NetworkError.encoding(underlying: error) }
        return try await post(endpoint: endpoint, params: params, headers: headers, body: body)
    }
}

public struct NetworkClient: NetworkClientProtocol {
    private let baseURL: URL
    private let transport: any HTTPTransport
    private let logger = Logger(subsystem: "TransportNetwork", category: "HTTP")

    public init(baseURL: URL, session: URLSession = .shared) {
        self.init(baseURL: baseURL, transport: URLSessionTransport(session: session))
    }

    public init(baseURL: URL, transport: any HTTPTransport) {
        self.baseURL = baseURL
        self.transport = transport
    }

    public func get<Output: Decodable & Sendable>(
        endpoint: String, params: [String: String]? = nil, headers: [String: String]? = nil
    ) async throws -> Output {
        try await request(method: "GET", endpoint: endpoint, params: params, headers: headers, body: nil)
    }

    public func post<Output: Decodable & Sendable>(
        endpoint: String, params: [String: String]? = nil,
        headers: [String: String]? = nil, body: Data
    ) async throws -> Output {
        try await request(method: "POST", endpoint: endpoint, params: params, headers: headers, body: body)
    }

    private func request<Output: Decodable & Sendable>(
        method: String, endpoint: String, params: [String: String]?,
        headers: [String: String]?, body: Data?
    ) async throws -> Output {
        try Task.checkCancellation()
        guard ["http", "https"].contains(baseURL.scheme), baseURL.host != nil,
              var components = URLComponents(url: baseURL.appendingPathComponent(endpoint), resolvingAgainstBaseURL: false)
        else { throw NetworkError.invalidURL }
        if let params {
            components.queryItems = params.sorted { $0.key < $1.key }.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = components.url else { throw NetworkError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if body != nil { request.setValue("application/json", forHTTPHeaderField: "Content-Type") }
        headers?.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await transport.data(for: request)
        } catch {
            if error is CancellationError || (error as? URLError)?.code == .cancelled || Task.isCancelled {
                throw CancellationError()
            }
            logger.error("Transport failed: \(error.localizedDescription, privacy: .private)")
            throw NetworkError.transport(url: url, underlying: error)
        }
        try Task.checkCancellation()
        guard let response = response as? HTTPURLResponse else { throw NetworkError.nonHTTPResponse(url: url) }
        logger.debug("\(method, privacy: .public) status \(response.statusCode) bytes \(data.count)")
        guard (200..<300).contains(response.statusCode) else {
            throw NetworkError.http(url: url, statusCode: response.statusCode, body: Data(data.prefix(4096)))
        }
        let output: Output
        do { output = try JSONDecoder().decode(Output.self, from: data) }
        catch let error as DecodingError { throw NetworkError.decoding(url: url, underlying: error) }
        try Task.checkCancellation()
        return output
    }
}
