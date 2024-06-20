import CryptoKit
import Foundation
import HsExtensions

public struct Input {
  public let previousOutputTxHash: Data
  public let previousOutputIndex: Int
  public let signatureScript: Data
  public let sequence: Int
  public var witnessData: [Data]
  public var transactionHash: Data?

  public init(previousOutputTxHash: Data, previousOutputIndex: Int, signatureScript: Data, sequence: Int, witnessData: [Data], transactionHash: Data? = nil) {
    self.previousOutputTxHash = previousOutputTxHash
    self.previousOutputIndex = previousOutputIndex
    self.signatureScript = signatureScript
    self.sequence = sequence
    self.witnessData = witnessData
    self.transactionHash = transactionHash
  }

  public func serialize() -> Data {
    var data = Data()
    data += previousOutputTxHash
    data += UInt32(previousOutputIndex)
    let scriptLength = VarInt(signatureScript.count)
    data += scriptLength.serialized()
    data += signatureScript
    data += UInt32(sequence)
    return data
  }
}

public struct Output {
  public var value: Int
  public var lockingScript: Data
  public var index: Int
  public var scriptType: ScriptType
  public var transactionHash: Data?
  public var lockingScriptPayload: Data?
  public var address: String?

  public init(value: Int, lockingScript: Data, index: Int, scriptType: ScriptType, transactionHash: Data? = nil, lockingScriptPayload: Data? = nil, address: String? = nil) {
    self.value = value
    self.lockingScript = lockingScript
    self.index = index
    self.scriptType = scriptType
    self.transactionHash = transactionHash
    self.lockingScriptPayload = lockingScriptPayload
    self.address = address
  }

  public func serialize() -> Data {
    var data = Data()
    data += value
    let scriptLength = VarInt(lockingScript.count)
    data += scriptLength.serialized()
    data += lockingScript
    return data
  }
}

public struct InputToSign {
  public var input: Input
  public let previousOutput: Output
  public let previousOutputPublicKey: PublicKey

  public init(input: Input, previousOutput: Output, previousOutputPublicKey: PublicKey) {
    self.input = input
    self.previousOutput = previousOutput
    self.previousOutputPublicKey = previousOutputPublicKey
  }
}

public struct Transaction {
  public var version: Int
  public var segWit: Bool
  public var lockTime: Int
  public var dataHash: Data?
  public var inputs: [Input]
  public var outputs: [Output]

  public init(version: Int, segWit: Bool, lockTime: Int, dataHash: Data? = nil, inputs: [Input], outputs: [Output]) {
    self.version = version
    self.segWit = segWit
    self.lockTime = lockTime
    self.dataHash = dataHash
    self.inputs = inputs
    self.outputs = outputs
  }

  public mutating func setTxHash() {
    let serialized = serialize(withoutWitness: true)
    let p1 = Data(SHA256.hash(data: serialized))
    let p2 = Data(SHA256.hash(data: p1))
    dataHash = p2
    for i in 0 ..< inputs.count {
      inputs[i].transactionHash = p2
    }
    for i in 0 ..< outputs.count {
      outputs[i].transactionHash = p2
    }
  }

  public func serialize(withoutWitness: Bool = false) -> Data {
    var data = Data()
    data += UInt32(version)
    if segWit, !withoutWitness {
      data += UInt8(0) // marker 0x00
      data += UInt8(1) // flag 0x01
    }
    data += VarInt(inputs.count).serialized()
    data += inputs.flatMap { $0.serialize() }
    data += VarInt(outputs.count).serialized()
    data += outputs.flatMap { $0.serialize() }
    if segWit, !withoutWitness {
      data += inputs.flatMap {
        Models.serialize(dataList: $0.witnessData)
      }
    }
    data += UInt32(lockTime)
    return data
  }
}

public struct MutableTransaction {
  public var inputsToSign: [InputToSign] = []
  public var outputs: [Output] = []

  public init(inputsToSign: [InputToSign], outputs: [Output]) {
    self.inputsToSign = inputsToSign
    self.outputs = outputs
  }
}

func serialize(dataList: [Data]) -> Data {
  var data = Data()
  data += VarInt(dataList.count).serialized()
  for witness in dataList {
    data += VarInt(witness.count).serialized() + witness
  }
  return data
}
