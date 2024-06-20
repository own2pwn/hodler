import Foundation

public struct Response {
  public let code: Int
  public let data: Data

  public func decode<T: Decodable>() throws -> T {
    return try jsonDecoder.decode(T.self, from: data)
  }
}
