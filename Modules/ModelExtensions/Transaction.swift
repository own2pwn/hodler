import Foundation
import HsExtensions
import Models

public extension Transaction {
  init?(raw: String) {
    guard let data = Data(hex: raw) else { return nil }
    let stream = ByteStream(data)
    let version = Int(stream.read(Int32.self))
    let segWit = stream.last == 0
    if segWit {
      _ = stream.read(Int16.self)
    }
    let txInCount = stream.read(VarInt.self)
    var inputs: [Input] = []
    inputs.reserveCapacity(Int(txInCount.underlyingValue))
    for _ in 0 ..< Int(txInCount.underlyingValue) {
      inputs.append(deserializeInput(stream: stream))
    }
    let txOutCount = stream.read(VarInt.self)
    var outputs: [Output] = []
    outputs.reserveCapacity(Int(txOutCount.underlyingValue))
    for i in 0 ..< Int(txOutCount.underlyingValue) {
      outputs.append(deserializeOutput(stream: stream, index: i))
    }
    if segWit {
      for i in 0 ..< Int(txInCount.underlyingValue) {
        inputs[i].witnessData = deserializeDataList(stream: stream)
      }
    }
    let lockTime = Int(stream.read(UInt32.self))
    self = Transaction(version: version, segWit: segWit, lockTime: lockTime, inputs: inputs, outputs: outputs)
  }
}

public func deserializeInput(stream: ByteStream) -> Input {
  let previousOutputTxHash = stream.read(Data.self, count: 32)
  let previousOutputIndex = Int(stream.read(UInt32.self))
  let scriptLength: VarInt = stream.read(VarInt.self)
  let signatureScript = stream.read(Data.self, count: Int(scriptLength.underlyingValue))
  let sequence = Int(stream.read(UInt32.self))

  return Input(
    previousOutputTxHash: previousOutputTxHash,
    previousOutputIndex: previousOutputIndex,
    signatureScript: signatureScript,
    sequence: sequence,
    witnessData: []
  )
}

public func deserializeOutput(stream: ByteStream, index: Int = 0) -> Output {
  let value = Int(stream.read(Int64.self))
  let scriptLength: VarInt = stream.read(VarInt.self)
  let lockingScript = stream.read(Data.self, count: Int(scriptLength.underlyingValue))
  var output = Output(
    value: value,
    lockingScript: lockingScript,
    index: index,
    scriptType: .unknown,
    transactionHash: nil
  )
  output.parseScriptType()
  return output
}

public func deserializeDataList(stream: ByteStream) -> [Data] {
  var data = [Data]()
  let count = stream.read(VarInt.self)
  for _ in 0 ..< Int(count.underlyingValue) {
    let dataSize = stream.read(VarInt.self)
    data.append(stream.read(Data.self, count: Int(dataSize.underlyingValue)))
  }
  return data
}

public extension Output {
  mutating func parseScriptType() {
    var payload: Data?
    var validScriptType: ScriptType = .unknown
    let lockingScriptCount = lockingScript.count
    if
      lockingScriptCount == ScriptType.p2pkh.size, // P2PKH Output script 25 bytes: 76 A9 14 {20-byte-key-hash} 88 AC
      lockingScript[0] == OpCode.dup,
      lockingScript[1] == OpCode.hash160,
      lockingScript[2] == 20,
      lockingScript[23] == OpCode.equalVerify,
      lockingScript[24] == OpCode.checkSig
    {
      // parse P2PKH transaction output
      payload = lockingScript.subdata(in: 3 ..< 23)
      validScriptType = .p2pkh
    } else if
      lockingScriptCount == ScriptType.p2pk.size || lockingScriptCount == 67, // P2PK Output script 35/67 bytes: {push-length-byte 33/65} {length-byte-public-key 33/65} AC
      lockingScript[0] == 33 || lockingScript[0] == 65,
      lockingScript[lockingScriptCount - 1] == OpCode.checkSig
    {
      // parse P2PK transaction output
      payload = lockingScript.subdata(in: 1 ..< (lockingScriptCount - 1))
      validScriptType = .p2pk
    } else if
      lockingScriptCount == ScriptType.p2sh.size, // P2SH Output script 23 bytes: A9 14 {20-byte-script-hash} 87
      lockingScript[0] == OpCode.hash160,
      lockingScript[1] == 20,
      lockingScript[lockingScriptCount - 1] == OpCode.equal
    {
      // parse P2SH transaction output
      payload = lockingScript.subdata(in: 2 ..< (lockingScriptCount - 1))
      validScriptType = .p2sh
    } else if
      lockingScriptCount == ScriptType.p2wpkh.size, // P2WPKH Output script 22 bytes: {version-byte {00} 14 {20-byte-key-hash}
      lockingScript[0] == 0, // push version byte 0
      lockingScript[1] == 20
    {
      // parse P2WPKH transaction output
      payload = lockingScript.subdata(in: 2 ..< lockingScriptCount)
      validScriptType = .p2wpkh
    } else if
      lockingScriptCount == ScriptType.p2tr.size, // P2TR Output script 34 bytes: {version-byte 51} {51} 20 {32-byte-public-key}
      lockingScript[0] == 0x51, // push version byte 1 and
      lockingScript[1] == 32
    {
      // parse P2WPKH transaction output
      payload = lockingScript.subdata(in: 2 ..< lockingScriptCount)
      validScriptType = .p2tr
    } else if lockingScriptCount > 0, lockingScript[0] == OpCode.op_return { // nullData output
      payload = lockingScript.subdata(in: 0 ..< lockingScriptCount)
      validScriptType = .nullData
    }
    scriptType = validScriptType
    lockingScriptPayload = payload
  }
}
