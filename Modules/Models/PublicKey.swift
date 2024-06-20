import Foundation
import HsCryptoKit

public struct PublicKey: Hashable {
  public let path: String
  public let account: Int
  public let index: Int
  public let external: Bool
  public let raw: Data
  public let hashP2pkh: Data
  public let hashP2wpkhWrappedInP2sh: Data
  public let convertedForP2tr: Data

  public init(withAccount account: Int, index: Int, external: Bool, hdPublicKeyData data: Data) throws {
    self.account = account
    self.index = index
    self.external = external
    self.path = "\(account)/\(external ? 0 : 1)/\(index)"
    self.raw = data
    self.hashP2pkh = Crypto.ripeMd160Sha256(data)
    self.hashP2wpkhWrappedInP2sh = Crypto.ripeMd160Sha256(OpCode.segWitOutputScript(hashP2pkh, versionByte: 0))
    self.convertedForP2tr = try SchnorrHelper.tweakedOutputKey(publicKey: raw)
  }

  public static func == (lhs: PublicKey, rhs: PublicKey) -> Bool {
    lhs.path == rhs.path
  }

  public var hashValue: Int {
    path.hashValue
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(path)
  }
}

public extension SegWitBech32AddressConverter {
  func convert(publicKey: PublicKey, type: ScriptType) throws -> Address {
    switch type {
    case .p2wpkh, .p2wsh:
      return try convert(lockingScriptPayload: publicKey.hashP2pkh, type: type)
    case .p2tr:
      return try convert(lockingScriptPayload: publicKey.convertedForP2tr, type: type)
    default: throw BitcoinCoreErrors.AddressConversion.unknownAddressType
    }
  }
}


