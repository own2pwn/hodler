import Foundation

public protocol ScriptDecoder {
  func decode(data: Data) throws -> Script
}

public enum ScriptError: Error {
  case wrongScriptLength
  case wrongSequence
}

public enum ScriptType: Int {
  case unknown, p2pkh, p2pk, p2multi, p2sh, p2wsh, p2wpkh, p2wpkhSh, p2tr, nullData

  public var size: Int {
    switch self {
    case .p2pk: return 35
    case .p2pkh: return 25
    case .p2sh: return 23
    case .p2wsh: return 34
    case .p2wpkh: return 22
    case .p2wpkhSh: return 23
    case .p2tr: return 34
    default: return 0
    }
  }

  public var witness: Bool {
    self == .p2wpkh || self == .p2wpkhSh || self == .p2wsh || self == .p2tr
  }
}

public struct Script {
  public let scriptData: Data
  public let chunks: [ScriptChunk]

  public var length: Int { scriptData.count }

  public func validate(opCodes: Data) throws {
    guard opCodes.count == chunks.count else {
      throw ScriptError.wrongScriptLength
    }
    try chunks.enumerated().forEach { index, chunk in
      if chunk.opCode != opCodes[index] {
        throw ScriptError.wrongSequence
      }
    }
  }

  public init(with data: Data, chunks: [ScriptChunk]) {
    self.scriptData = data
    self.chunks = chunks
  }
}

public struct ScriptChunk: Equatable {
  public let scriptData: Data
  public let index: Int
  public let payloadRange: Range<Int>?

  public var opCode: UInt8 { scriptData[index] }
  public var data: Data? {
    guard let payloadRange, scriptData.count >= payloadRange.upperBound else {
      return nil
    }
    return scriptData.subdata(in: payloadRange)
  }

  public init(scriptData: Data, index: Int, payloadRange: Range<Int>? = nil) {
    self.scriptData = scriptData
    self.index = index
    self.payloadRange = payloadRange
  }

  public static func == (lhs: ScriptChunk, rhs: ScriptChunk) -> Bool {
    lhs.scriptData == rhs.scriptData && lhs.opCode == rhs.opCode && lhs.payloadRange == rhs.payloadRange
  }
}
