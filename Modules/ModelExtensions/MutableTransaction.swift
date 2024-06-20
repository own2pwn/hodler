import CryptoKit
import Foundation
import HdWalletKit
import HsCryptoKit
import HsExtensions
import Models

public extension MutableTransaction {
  mutating func sign(wallet: HDWallet) throws {
    for i in 0 ..< inputsToSign.count {
      var inputToSign = inputsToSign[i]
      let witnessData = try sigScriptData(
        wallet: wallet,
        inputsToSign: inputsToSign,
        outputs: outputs,
        index: i
      )
      inputToSign.input.witnessData = witnessData
      inputsToSign[i] = inputToSign
    }
  }
}

func sigScriptData(wallet: HDWallet, inputsToSign: [InputToSign], outputs: [Output], index: Int) throws -> [Data] {
  let input = inputsToSign[index]
  let pubKey = input.previousOutputPublicKey
  let privateKeyData = try wallet.privateKey(account: pubKey.account, index: pubKey.index, chain: pubKey.external ? .external : .internal).raw
  let serializedTransaction = serializedForTaprootSignature(version: 2, lockTime: 0, inputsToSign: inputsToSign, outputs: outputs, inputIndex: index)

  let signatureHash = try SchnorrHelper.hashTweak(data: serializedTransaction, tag: "TapSighash")
  let signature = try SchnorrHelper.sign(data: signatureHash, privateKey: privateKeyData, publicKey: pubKey.raw)

  return [signature]
}

func serializedForTaprootSignature(
  version: Int,
  lockTime: Int,
  inputsToSign: [InputToSign],
  outputs: [Output],
  inputIndex: Int
) -> Data {
  var data = Data()
  data += UInt8(0)
  data += UInt8(0) // SIGHASH_DEFAULT
  data += UInt32(version)
  data += UInt32(lockTime)
  let hashPrevouts = inputsToSign.flatMap { input in
    serializedOutPoint(input: input)
  }
  data += Data(SHA256.hash(data: hashPrevouts))

  var outputValues = Data()
  for input in inputsToSign {
    outputValues += UInt64(input.previousOutput.value)
  }
  data += Data(SHA256.hash(data: outputValues))
  let outputLockingScripts = Data(inputsToSign.flatMap { OpCode.push($0.previousOutput.lockingScript) })
  data += Data(SHA256.hash(data: outputLockingScripts))

  var sequences = Data()
  for input in inputsToSign {
    sequences += UInt32(input.input.sequence)
  }
  data += Data(SHA256.hash(data: sequences))
  let hashOutputs = outputs.flatMap { $0.serialize() }
  data += Data(SHA256.hash(data: hashOutputs))

  data += UInt8(0) // spendType (no annex, no scriptPath)
  data += UInt32(inputIndex)

  return data
}

func serializedOutPoint(input: InputToSign) -> Data {
  var data = Data()
  let output = input.previousOutput
  data += output.transactionHash!
  data += UInt32(output.index)
  return data
}

public extension MutableTransaction {
  static let legacyTx = 16 + 4 + 4 + 16 // 40 Version + number of inputs + number of outputs + locktime
  static let witnessTx = legacyTx + 1 + 1 // 42 SegWit marker + SegWit flag
  static let legacyWitnessData = 1 // 1 Only 0x00 for legacy input
  // P2WPKH or P2WPKH(SH)
  static let p2wpkhWitnessData = 1 + ecdsaSignatureLength + pubKeyLength // 108 Number of stack items for input + Size of stack item 0 + Stack item 0, signature + Size of stack item 1 + Stack item 1, pubkey
  static let p2trWitnessData = 1 + schnorrSignatureLength

  static let ecdsaSignatureLength = 72 + 1 // signature length plus pushByte
  static let schnorrSignatureLength = 64 + 1 // signature length plus pushByte
  static let pubKeyLength = 33 + 1 // ECDSA compressed pubKey length plus pushByte
  static let p2wpkhShLength = 22 + 1 // 0014<20byte-scriptHash> plus pushByte

  func calculateSize(segWit: Bool, memo: String?) -> Int {
    var inputSize = 0
    for output in inputsToSign.map(\.previousOutput) {
      inputSize += self.inputSize(output: output) * 4
      if segWit {
        switch output.scriptType {
        case .p2wpkh, .p2wpkhSh:
          inputSize += MutableTransaction.p2wpkhWitnessData
        case .p2tr:
          inputSize += MutableTransaction.p2trWitnessData
        default:
          inputSize += MutableTransaction.legacyWitnessData
        }
      }
    }
    var outputSize = 0
    for output in outputs {
      outputSize += (8 + 1 + output.scriptType.size) * 4
    }
    if let memo, let memoData = memo.data(using: .utf8) {
      let lockingScript = Data([OpCode.op_return]) + OpCode.push(memoData)
      outputSize += 8 + 1 + lockingScript.count // spentValue + scriptLength + script
    }
    let txWeight = segWit ? MutableTransaction.witnessTx : MutableTransaction.legacyTx
    return toBytes(fee: txWeight + inputSize + outputSize)
  }

  private func toBytes(fee: Int) -> Int {
    return fee / 4 + (fee % 4 == 0 ? 0 : 1)
  }

  private func inputSize(output: Output) -> Int {
    let sigScriptLength: Int
    switch output.scriptType {
    case .p2pkh: sigScriptLength = MutableTransaction.ecdsaSignatureLength + MutableTransaction.pubKeyLength
    case .p2pk: sigScriptLength = MutableTransaction.ecdsaSignatureLength
    case .p2wpkhSh: sigScriptLength = MutableTransaction.p2wpkhShLength
    case .p2sh:
      // TODO: redeemScript, signatureScriptFunction
      sigScriptLength = 0
    default: sigScriptLength = 0
    }
    let inputTxSize = 32 + 4 + 1 + sigScriptLength + 4 // PreviousOutputHex + InputIndex + sigLength + sigScript + sequence
    return inputTxSize
  }
}
