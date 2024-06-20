import Foundation

public enum NetworkingError: LocalizedError {
  case unauthorized
  case server(Int)

  public var errorDescription: String? {
    switch self {
    case .unauthorized:
      return "Пользователь не авторизован"
    case let .server(code):
      return "Сервер недоступен: \(code)"
    }
  }
}
