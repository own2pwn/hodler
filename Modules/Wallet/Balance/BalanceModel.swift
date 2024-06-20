import ComposableArchitecture
import EPUIKit
import HdWalletKit
import ModelExtensions
import Models
import Networking
import SwiftUI

enum BalanceState: Equatable {
  case loading, error(Error), balance(UInt64)
}

enum SendError: Error, LocalizedError {
  case cantCoverFee(String)
  case broadcast(String?)

  var errorDescription: String? {
    switch self {
    case let .cantCoverFee(v): "Can't cover fee. Amount needed: \(v)"
    case let .broadcast(v): "Can't broadcast tx: \(v ?? "<>")"
    }
  }
}

@Reducer
struct BalanceModel {
  enum Action {
    case loadBalance, setBalance(BalanceState)
    case setAmount(String), setRecipient(String)
    case transfer, showTx(String)
  }

  enum Cancel {
    case balance
  }

  @ObservableState
  struct State: Equatable {
    let wallet: Wallet
    var balance: BalanceState = .loading
    var amount = ""
    var recipient = ""

    init(wallet: HDWallet) throws {
      let pubKey = try wallet.publicKey(account: 0, index: 0, external: true)
      let pubKeyChange = try wallet.publicKey(account: 0, index: 0, external: false)
      let pubAddress = try addressConverter.convert(publicKey: pubKey, type: .p2tr)
      let changeAddress = try addressConverter.convert(publicKey: pubKeyChange, type: .p2tr)
      self.wallet = .init(
        wallet: wallet,
        pubKey: pubKey,
        pubKeyChange: pubKeyChange,
        pubAddress: pubAddress,
        changeAddress: changeAddress
      )
    }
  }

  let onShowTx: (String) -> Void
  let onDisplayMessage: (String, AlertType) -> Void
  let displayLoader: (Bool) -> Void

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .loadBalance:
        state.balance = .loading
        return .run(priority: .userInitiated) { [state] send in
          displayLoader(true)
          do {
            let pubBalance = try await Networking.getBalance(address: state.wallet.pubAddress.stringValue)
            let changeBalance = try await Networking.getBalance(address: state.wallet.changeAddress.stringValue)
            await send(.setBalance(.balance(pubBalance + changeBalance)))
          } catch {
            await send(.setBalance(.error(error)))
            onDisplayMessage(error.localizedDescription, .error)
          }
          displayLoader(false)
        }.cancellable(id: Cancel.balance, cancelInFlight: true)
      case let .setBalance(v):
        state.balance = v
        return .none
      case let .setAmount(v):
        state.amount = v
        return .none
      case let .setRecipient(v):
        state.recipient = v
        return .none
      case .transfer:
        let balance: UInt64
        switch state.balance {
        case let .balance(v):
          balance = v
        case .error:
          return .send(.loadBalance)
        case .loading:
          onDisplayMessage("Balance is updating", .info)
          return .none
        }
        guard let amount = balanceFmt.number(from: state.amount)?.doubleValue else {
          onDisplayMessage("You entered invalid amount", .error)
          return .none
        }
        let recipientAddress: Address
        do {
          recipientAddress = try addressConverter.convert(address: state.recipient)
        } catch {
          onDisplayMessage("You entered invalid recipient", .error)
          return .none
        }
        let satoshisToSend = UInt64(amount * denominatorD)
        if satoshisToSend >= balance {
          onDisplayMessage("Balance is not enough", .error)
          return .none
        }
        return .run(priority: .userInitiated) { [state] send in
          displayLoader(true)
          do {
            let txID = try await self.sendTx(to: recipientAddress, amountToSend: satoshisToSend, state: state)
            if let txID {
              await send(.showTx(txID))
            } else {
              onDisplayMessage("No tx id found in response", .error)
            }
          } catch {
            onDisplayMessage("Couldn't send tx: \(error.localizedDescription)", .error)
          }
          displayLoader(false)
        }
      case let .showTx(id):
        onShowTx(id)
        return .none
      }
    }
  }

  private func sendTx(to recipient: Address, amountToSend: UInt64, state: State) async throws -> String? {
    let unspentAddress = try await Networking.getUnspentTransactions(address: state.wallet.pubAddress.stringValue)
    let unspentChange = try await Networking.getUnspentTransactions(address: state.wallet.changeAddress.stringValue)
    let txFee = try await Networking.getTxFee()
    let unspentAddressAvailable = unspentAddress
      .compactMap { raw in
        var tx = Transaction(raw: raw)
        if tx != nil {
          tx!.setTxHash()
        }
        return tx
      }
      .flatMap(\.outputs)
      .filter { output in
        output.lockingScript == state.wallet.pubAddress.lockingScript
      }.map { output in
        (output, state.wallet.pubKey)
      }
    let unspentChangeAvailable = unspentChange
      .compactMap { raw in
        var tx = Transaction(raw: raw)
        if tx != nil {
          tx!.setTxHash()
        }
        return tx
      }
      .flatMap(\.outputs)
      .filter { output in
        output.lockingScript == state.wallet.changeAddress.lockingScript
      }.map { output in
        (output, state.wallet.pubKeyChange)
      }
    let sortedAvailable = (unspentAddressAvailable + unspentChangeAvailable).sorted { a, b in
      a.0.value > b.0.value
    }
    let totalAvailable = sortedAvailable.reduce(UInt64(0)) { partialResult, t in
      partialResult + UInt64(t.0.value)
    }
    var available = UInt64(0)
    var amountNeeded = amountToSend
    var mutableTx: MutableTransaction = .init(inputsToSign: [], outputs: [])
    while amountNeeded > available {
      available = 0
      let outputsToUse = sortedAvailable.prefix { output, _ in
        if available >= amountToSend {
          return false
        }
        available += UInt64(output.value)
        return true
      }
      let inputsToSign = outputsToUse.map { output, pubkey in
        InputToSign(
          input: Input(
            previousOutputTxHash: output.transactionHash!,
            previousOutputIndex: output.index,
            signatureScript: Data(),
            sequence: 0,
            witnessData: [],
            transactionHash: nil
          ),
          previousOutput: output,
          previousOutputPublicKey: pubkey
        )
      }
      var outputs: [Output] = [
        .init(
          value: Int(amountToSend),
          lockingScript: recipient.lockingScript,
          index: 0,
          scriptType: recipient.scriptType
        ),
        .init(
          value: 0,
          lockingScript: state.wallet.changeAddress.lockingScript,
          index: 1,
          scriptType: state.wallet.changeAddress.scriptType
        ),
      ]
      mutableTx = MutableTransaction(
        inputsToSign: inputsToSign,
        outputs: outputs
      )
      let txSize = mutableTx.calculateSize(segWit: true, memo: nil)
      let feeAmount = UInt64(txFee * txSize)
      amountNeeded = amountToSend + feeAmount
      if amountNeeded > totalAvailable {
        let s = balanceFmt.string(for: amountNeeded) ?? "\(amountNeeded)"
        throw SendError.cantCoverFee(s)
      }
      let amountLeft = available - amountNeeded
      if amountLeft > 0 {
        outputs[1].value = Int(amountLeft)
      }
      mutableTx.outputs = outputs
    }
    try mutableTx.sign(wallet: state.wallet.wallet)
    let sendTransaction = Transaction(
      version: 2,
      segWit: true,
      lockTime: 0,
      dataHash: nil,
      inputs: mutableTx.inputsToSign.map(\.input),
      outputs: mutableTx.outputs
    )
    return try await Networking.sendRawTx(data: sendTransaction.serialize().hs.hex)
  }
}

extension Networking {
  enum GetTxError: Error, LocalizedError {
    case invalidData(Data)

    var errorDescription: String? {
      switch self {
      case let .invalidData(v):
        return "Can't get tx data: \(v.hs.hex)"
      }
    }
  }

  static func getBalance(address: String) async throws -> UInt64 {
    struct Item: Decodable {
      let value: UInt64
    }
    let response = try await Networking.get(path: "/address/\(address)/utxo")
    let items: [Item] = try response.decode()
    return items.reduce(into: UInt64(0)) { partialResult, item in
      partialResult += item.value
    }
  }

  static func getUnspentTransactions(address: String) async throws -> [String] {
    struct OutputResponse: Decodable {
      let txid: String
    }
    let response = try await Networking.get(path: "/address/\(address)/utxo")
    let ids: [OutputResponse] = try response.decode()
    var raw: [String] = []
    raw.reserveCapacity(ids.count)
    for id in ids {
      let txResponse = try await Networking.get(path: "/tx/\(id.txid)/hex")
      if txResponse.code != 200 {
        throw GetTxError.invalidData(response.data)
      }
      if let value = String(data: txResponse.data, encoding: .utf8) {
        raw.append(value)
      } else {
        throw GetTxError.invalidData(txResponse.data)
      }
    }
    return raw
  }

  static func getTxFee() async throws -> Int {
    struct Response: Decodable {
      let fastestFee: Int
      let minimumFee: Int
    }
    let response = try await Networking.get(path: "/v1/fees/recommended")
    let result: Response = try response.decode()
    return result.fastestFee
  }

  static func sendRawTx(data: String) async throws -> String? {
    let txResponse = try await Networking.postText(path: "/tx", data: data)
    let text = String(data: txResponse.data, encoding: .utf8)
    if txResponse.code != 200 {
      throw SendError.broadcast(text)
    }
    return text
  }
}

extension BalanceState {
  static func == (lhs: BalanceState, rhs: BalanceState) -> Bool {
    switch (lhs, rhs) {
    case (.loading, .loading):
      return true
    case let (.error(a), .error(b)):
      return a.localizedDescription == b.localizedDescription
    case let (.balance(a), .balance(b)):
      return a == b
    default:
      return false
    }
  }
}
