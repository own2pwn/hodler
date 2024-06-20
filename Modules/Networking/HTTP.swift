import Foundation
import Keychain

public enum Method {
  case GET
  case POST
  case PUT
}

extension Method {
  var name: String {
    switch self {
    case .GET: return "GET"
    case .POST: return "POST"
    case .PUT: return "PUT"
    }
  }
}

let dateFormatter: DateFormatter = {
  let fmt = DateFormatter()
  // "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
  fmt.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ"
  return fmt
}()

let dateFormatterShort: DateFormatter = {
  let fmt = DateFormatter()
  // "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
  fmt.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
  return fmt
}()

let networkSession: URLSession = {
  var config = URLSessionConfiguration.ephemeral
  config.timeoutIntervalForRequest = 120
  config.timeoutIntervalForResource = 600
  let s = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
  return s
}()

let jsonEncoder: JSONEncoder = {
  let e = JSONEncoder()
  e.dataEncodingStrategy = .base64
  e.dateEncodingStrategy = .formatted(dateFormatter)
  return e
}()

let jsonDecoder: JSONDecoder = {
  let e = JSONDecoder()
  e.dataDecodingStrategy = .base64
  e.dateDecodingStrategy = .custom { decoder in
    let container = try decoder.singleValueContainer()
    let dateString = try container.decode(String.self)
    if let v = dateFormatter.date(from: dateString) {
      return v
    }
    if let v = dateFormatterShort.date(from: dateString) {
      return v
    }
    return try container.decode(Date.self)
  }
  // e.keyDecodingStrategy = .convertFromSnakeCase
  return e
}()

public var NetworkingJsonDecoder: JSONDecoder {
  return jsonDecoder
}
