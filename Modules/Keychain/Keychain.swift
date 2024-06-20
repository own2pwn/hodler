import Foundation
import Security

let baseId = "app.hodl.ios."

public enum KeychainError: Error {
  case accessControl
  case authFailed
  case other(OSStatus)
  case secureKeyNotLoaded
  case secureDataNotProvided
}

public let AccountName = "HODL"

public protocol KeychainKey: RawRepresentable<String> {}
public protocol KeychainSecureKey: RawRepresentable<String> {}

public enum Keychain {
  private static let encoder: JSONEncoder = {
    let e = JSONEncoder()
    e.dataEncodingStrategy = .base64
    e.dateEncodingStrategy = .secondsSince1970
    return e
  }()

  private static let decoder: JSONDecoder = {
    let e = JSONDecoder()
    e.dataDecodingStrategy = .base64
    e.dateDecodingStrategy = .secondsSince1970
    return e
  }()

  public static func save(_ key: any KeychainKey, item: Encodable) throws {
    let data = try Keychain.encoder.encode(item)
    return try save(key.rawValue, data: data)
  }

  private static func save(_ key: String, data: Data) throws {
    let query = [
      kSecClass: kSecClassGenericPassword,
      kSecAttrService: key,
      kSecAttrAccount: AccountName,
      kSecValueData: data,
    ] as CFDictionary
    let result = SecItemAdd(query, nil)
    if result == errSecDuplicateItem {
      return try Keychain.update(key, data: data)
    }
    if result != noErr {
      if result == errSecAuthFailed {
        throw KeychainError.authFailed
      }
      throw KeychainError.other(result)
    }
  }

  public static func save(_ key: any KeychainSecureKey, item: Encodable) throws {
    var secureKey: SecKey?
    if Enclave.available(name: key.rawValue) {
      secureKey = try Enclave.loadKey(name: key.rawValue)
    } else {
      secureKey = try Enclave.makeAndStoreKey(name: key.rawValue)
    }
    guard let secureKey = secureKey else {
      throw KeychainError.secureKeyNotLoaded
    }
    let data = try encoder.encode(item)
    guard let encryptedData = try Enclave.encrypt(data: data, key: secureKey) else {
      throw KeychainError.secureDataNotProvided
    }
    return try save(key.rawValue, data: encryptedData)
  }

  public static func read<T: Decodable>(_ key: any KeychainKey) throws -> T? {
    return try read(key.rawValue)
  }

  private static func read<T: Decodable>(_ key: String) throws -> T? {
    if let data = try readData(key) {
      return try Keychain.decoder.decode(T.self, from: data)
    }
    return nil
  }

  private static func readData(_ key: String) throws -> Data? {
    var data: CFTypeRef?
    let query = [
      kSecAttrService: key,
      kSecAttrAccount: AccountName,
      kSecClass: kSecClassGenericPassword,
      kSecReturnData: true,
    ] as CFDictionary
    let result = SecItemCopyMatching(query, &data)
    if result == errSecItemNotFound {
      return nil
    }
    if result != noErr {
      if result == errSecAuthFailed {
        throw KeychainError.authFailed
      }
      throw KeychainError.other(result)
    }
    return data as? Data
  }

  public static func read<T: Decodable>(_ key: any KeychainSecureKey) throws -> T? {
    guard let secureKey = try Enclave.loadKey(name: key.rawValue) else {
      return nil
    }
    guard let encryptedData: Data = try readData(key.rawValue) else {
      throw KeychainError.secureDataNotProvided
    }
    guard let decryptedData = try Enclave.decrypt(data: encryptedData, key: secureKey) else {
      throw KeychainError.secureDataNotProvided
    }
    return try decoder.decode(T.self, from: decryptedData)
  }

  public static func delete(_ key: any KeychainKey) throws {
    try delete(key.rawValue)
  }

  public static func delete(_ key: any KeychainSecureKey) throws {
    try delete(key.rawValue)
  }

  public static func delete(_ key: String) throws {
    let query = [
      kSecAttrService: key,
      kSecAttrAccount: AccountName,
      kSecClass: kSecClassGenericPassword,
    ] as CFDictionary
    let result = SecItemDelete(query)
    if result == errSecItemNotFound {
      return
    }
    if result != noErr {
      if result == errSecAuthFailed {
        throw KeychainError.authFailed
      }
      throw KeychainError.other(result)
    }
  }

  public static func update(_ key: any KeychainKey, item: Encodable) throws {
    let data = try Keychain.encoder.encode(item)
    return try update(key.rawValue, data: data)
  }

  public static func exists(key: any KeychainKey) -> Bool {
    return exists(key: key.rawValue)
  }

  public static func exists(key: any KeychainSecureKey) -> Bool {
    return exists(key: key.rawValue)
  }

  public static func exists(key: String) -> Bool {
    let query = [
      kSecAttrService: key,
      kSecAttrAccount: AccountName,
      kSecClass: kSecClassGenericPassword,
      kSecReturnData: true,
    ] as CFDictionary
    let result = SecItemCopyMatching(query, nil)
    return result == noErr
  }

  private static func update(_ key: String, data: Data) throws {
    let query = [
      kSecAttrService: key,
      kSecAttrAccount: AccountName,
      kSecClass: kSecClassGenericPassword,
    ] as CFDictionary
    let attributesToUpdate = [kSecValueData as String: data] as CFDictionary
    let result = SecItemUpdate(query, attributesToUpdate)
    if result != noErr {
      if result == errSecAuthFailed {
        throw KeychainError.authFailed
      }
      throw KeychainError.other(result)
    }
  }
}
