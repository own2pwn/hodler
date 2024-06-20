import Foundation
import Security

enum Enclave {
  static func makeAndStoreKey(name: String) throws -> SecKey? {
    let flags: SecAccessControlCreateFlags
    #if targetEnvironment(simulator)
      flags = [.privateKeyUsage]
    #else
      flags = [.privateKeyUsage, .biometryCurrentSet]
    #endif

    guard
      let access =
      SecAccessControlCreateWithFlags(
        kCFAllocatorDefault,
        kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
        flags,
        nil
      )
    else {
      throw KeychainError.accessControl
    }
    let attributes: [String: Any] = [
      kSecAttrKeyType as String: kSecAttrKeyTypeEC,
      kSecAttrKeySizeInBits as String: 256,
      kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
      kSecPrivateKeyAttrs as String: [
        kSecAttrIsPermanent as String: true,
        kSecAttrApplicationTag as String: Enclave.kSecTag(name),
        kSecAttrAccessControl as String: access,
      ],
    ]
    var error: Unmanaged<CFError>?
    let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error)
    if let error = error {
      throw error.takeRetainedValue()
    }
    return privateKey
  }

  static func loadKey(name: String) throws -> SecKey? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassKey,
      kSecAttrApplicationTag as String: kSecTag(name),
      kSecAttrKeyType as String: kSecAttrKeyTypeEC,
      kSecReturnRef as String: true,
    ]
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    if status == errSecItemNotFound {
      return nil
    }
    guard status == errSecSuccess else {
      throw KeychainError.other(status)
    }
    guard let item = item else {
      return nil
    }
    return unsafeDowncast(item, to: SecKey.self)
  }

  static func removeKey(name: String) -> Bool {
    let query: [String: Any] = [
      kSecClass as String: kSecClassKey,
      kSecAttrApplicationTag as String: kSecTag(name),
      kSecAttrKeyType as String: kSecAttrKeyTypeEC,
    ]
    let result = SecItemDelete(query as CFDictionary)
    return result == noErr || result == errSecItemNotFound
  }

  static func encrypt(data: Data, key: SecKey) throws -> Data? {
    guard let publicKey = SecKeyCopyPublicKey(key) else {
      return nil
    }
    let algorithm: SecKeyAlgorithm = .eciesEncryptionCofactorVariableIVX963SHA512AESGCM
    guard SecKeyIsAlgorithmSupported(publicKey, .encrypt, algorithm) else {
      return nil
    }
    var error: Unmanaged<CFError>?
    let encryptedData = SecKeyCreateEncryptedData(
      publicKey,
      algorithm,
      data as CFData,
      &error
    )
    if let error = error {
      throw error.takeRetainedValue()
    }
    return encryptedData as Data?
  }

  static func decrypt(data: Data, key: SecKey) throws -> Data? {
    let algorithm: SecKeyAlgorithm = .eciesEncryptionCofactorVariableIVX963SHA512AESGCM
    guard SecKeyIsAlgorithmSupported(key, .decrypt, algorithm) else {
      return nil
    }
    assert(!Thread.isMainThread)
    var error: Unmanaged<CFError>?
    let decryptedData = SecKeyCreateDecryptedData(
      key,
      algorithm,
      data as CFData,
      &error
    )
    if let error = error {
      throw error.takeRetainedValue()
    }
    return decryptedData as Data?
  }

  static func available(name: String) -> Bool {
    let query = [
      kSecClass as String: kSecClassKey,
      kSecAttrApplicationTag as String: kSecTag(name),
      kSecAttrKeyType as String: kSecAttrKeyTypeEC,
      kSecMatchLimit as String: kSecMatchLimitOne,
      kSecUseAuthenticationUI as String: kSecUseAuthenticationUIFail,
    ] as CFDictionary
    var dataTypeRef: AnyObject?
    let status = SecItemCopyMatching(query, &dataTypeRef)
    return status == noErr || status == errSecInteractionNotAllowed || status == errSecAuthFailed
  }

  private static func kSecTag(_ name: String) -> Data {
    return (baseId + name).bytes
  }
}

extension String {
  @inline(__always)
  var bytes: Data {
    return Data(utf8)
  }
}
