import Foundation

public protocol Address {
  var scriptType: ScriptType { get }
  var lockingScriptPayload: Data { get }
  var stringValue: String { get }
  var lockingScript: Data { get }
}

public enum AddressType: UInt8 {
  case pubKeyHash = 0
  case scriptHash = 8
}
