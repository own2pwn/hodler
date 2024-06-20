import Foundation
import HdWalletKit
import Models

public extension HDWallet {
  enum HDWalletError: Error {
    case publicKeysDerivationFailed
  }

  func publicKey(account: Int, index: Int, external: Bool) throws -> PublicKey {
    try PublicKey(withAccount: account, index: index, external: external, hdPublicKeyData: publicKey(account: account, index: index, chain: external ? .external : .internal).raw)
  }

  internal func publicKeys(account: Int, indices: Range<UInt32>, external: Bool) throws -> [PublicKey] {
    let hdPublicKeys: [HDPublicKey] = try publicKeys(account: account, indices: indices, chain: external ? .external : .internal)

    guard hdPublicKeys.count == indices.count else {
      throw HDWalletError.publicKeysDerivationFailed
    }

    return try indices.map { index in
      let key = hdPublicKeys[Int(index - indices.lowerBound)]
      return try PublicKey(withAccount: account, index: Int(index), external: external, hdPublicKeyData: key.raw)
    }
  }
}
