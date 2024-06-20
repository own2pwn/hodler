import Foundation
import HsExtensions

public struct VarString {
  public typealias StringLiteralType = String
  public let length: VarInt
  public let value: String

  public init(_ value: String, length: Int) {
    self.value = value
    self.length = VarInt(length)
  }

  public func serialized() -> Data {
    var data = Data()
    data += length.serialized()
    data += value
    return data
  }
}

extension VarString: CustomStringConvertible {
  public var description: String {
    "\(value)"
  }
}
