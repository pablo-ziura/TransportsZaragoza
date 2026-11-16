import Foundation

public enum NetworkError: Error {
    case invalidURL
    case nonHTTPResponse(url: URL)
    case transport(url: URL, underlying: any Error)
    case http(url: URL, statusCode: Int, body: Data)
    case decoding(url: URL, underlying: DecodingError)
    case encoding(underlying: EncodingError)
}
