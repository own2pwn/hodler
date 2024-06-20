import Foundation

public struct SegWitBech32AddressConverter {
  private let prefix: String
  private let hasAdvanced: Bool

  public init(prefix: String, hasAdvanced: Bool = true) {
    self.prefix = prefix
    self.hasAdvanced = hasAdvanced
  }

  public func convert(address: String) throws -> Address {
    if let segWitData = try? SegWitBech32.decode(hrp: prefix, addr: address, hasAdvanced: hasAdvanced) {
      switch segWitData.version {
      case 0:
        var type: AddressType = .pubKeyHash
        switch segWitData.program.count {
        case 20: type = .pubKeyHash
        case 32: type = .scriptHash
        default: break
        }
        return SegWitV0Address(type: type, payload: segWitData.program, bech32: address)
      case 1:
        guard segWitData.program.count == 32 else {
          break
        }
        return TaprootAddress(payload: segWitData.program, bech32m: address, version: segWitData.version)
      default:
        break
      }
    }
    throw BitcoinCoreErrors.AddressConversion.unknownAddressType
  }

  public func convert(lockingScriptPayload: Data, type: ScriptType) throws -> Address {
    switch type {
    case .p2wpkh:
      let bech32 = try SegWitBech32.encode(hrp: prefix, version: 0, program: lockingScriptPayload, encoding: .bech32)
      return SegWitV0Address(type: AddressType.pubKeyHash, payload: lockingScriptPayload, bech32: bech32)
    case .p2wsh:
      let bech32 = try SegWitBech32.encode(hrp: prefix, version: 0, program: lockingScriptPayload, encoding: .bech32)
      return SegWitV0Address(type: AddressType.scriptHash, payload: lockingScriptPayload, bech32: bech32)
    case .p2tr:
      let bech32 = try SegWitBech32.encode(hrp: prefix, version: 1, program: lockingScriptPayload, encoding: .bech32m)
      return TaprootAddress(payload: lockingScriptPayload, bech32m: bech32, version: 1)
    default: throw BitcoinCoreErrors.AddressConversion.unknownAddressType
    }
  }
}
