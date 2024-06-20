import CryptoKit
import Foundation
import Keychain

public enum Networking {
  private static let baseURL = URL(string: "https://mempool.space/signet/api").unsafelyUnwrapped
}

private enum RequestDataType {
  case none
  case json(Data)
  case text(Data)
}

public extension Networking {
  static func get(path: String, query: [URLQueryItem] = [], timeout: TimeInterval = 120) async throws -> Response {
    let request = try Networking.prepareRequest(method: .GET, path: path, timeout: timeout, query: query)
    let (data, response) = try await networkSession.data(for: request)
    return try toResponse(data, response)
  }

  static func post<M: Encodable>(path: String, request: M, timeout: TimeInterval = 120) async throws -> Response {
    let bodyData = try jsonEncoder.encode(request)
    let request = try Networking.prepareRequest(method: .POST, path: path, timeout: timeout, dataType: .json(bodyData))
    let (data, response) = try await networkSession.data(for: request)
    return try toResponse(data, response)
  }

  static func postText(path: String, data: String, timeout: TimeInterval = 180) async throws -> Response {
    let content = Data(data.utf8)
    let request = try Networking.prepareRequest(method: .POST, path: path, timeout: timeout, dataType: .text(content))
    let (data, response) = try await networkSession.data(for: request)
    return try toResponse(data, response)
  }

  private static func toResponse(_ data: Data, _ response: URLResponse) throws -> Response {
    try validate(data, response)
    let code: Int = (response as? HTTPURLResponse)?.statusCode ?? -1
    return Response(code: code, data: data)
  }

  private static func validate(_ data: Data, _ response: URLResponse) throws {
    guard let code = ((response as? HTTPURLResponse)?.statusCode) else { return }
    switch code {
    case 401:
      throw NetworkingError.unauthorized
    case 500 ..< 600:
      throw NetworkingError.server(code)
    default:
      break
    }
  }

  private static func prepareRequest(
    method: Method,
    path: String,
    timeout: TimeInterval,
    query: [URLQueryItem] = [],
    dataType: RequestDataType = .none
  ) throws -> URLRequest {
    var urlComps = URLComponents(url: Networking.baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false).unsafelyUnwrapped
    if !query.isEmpty {
      urlComps.queryItems = query
    }
    var request = URLRequest(
      url: urlComps.url.unsafelyUnwrapped,
      timeoutInterval: timeout
    )
    request.httpMethod = method.name
    switch dataType {
    case .none:
      break
    case let .json(data), let .text(data):
      request.httpBody = data
    }
    if case .json = dataType {
      request.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
    }
    return request
  }

  private static func decodeResponse<T: Decodable>(data: Data) throws -> T {
    return try jsonDecoder.decode(T.self, from: data)
  }
}
