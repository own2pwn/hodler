import ComposableArchitecture
import EPUIKit
import HdWalletKit
import ModelExtensions
import Models
import Networking
import SwiftUI

struct TxItem: Decodable, Equatable {
  struct Status: Decodable, Equatable {
    let block_time: Int?
  }

  struct Vin: Decodable, Equatable {
    struct Prevout: Decodable, Equatable {
      let scriptpubkey_address: String
    }

    let prevout: Prevout
  }

  struct Vout: Decodable, Equatable {
    let scriptpubkey_address: String
    let value: UInt64
  }

  let txid: String
  let status: Status
  let vin: [Vin]
  let vout: [Vout]
}

struct ChainTx: Hashable {
  let id: String
  let isOutgoing: Bool
  let address: String
  let amount: String
}

enum HistoryState: Equatable {
  case loading, error(Error), history([ChainTx])
}

enum LoadHistoryError: Error, LocalizedError {
  case load(String?)

  var errorDescription: String? {
    switch self {
    case let .load(v): "Can't load tx history: \(v ?? "<>")"
    }
  }
}

@Reducer
struct HistoryModel {
  enum Action {
    case loadHistory, setHistory(HistoryState)
    case openHistory(ChainTx)
  }

  enum Cancel {
    case history
  }

  @ObservableState
  struct State: Equatable {
    let wallet: Wallet
    var history: HistoryState = .loading

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

  let onOpenTx: (String) -> Void
  let onDisplayMessage: (String, AlertType) -> Void
  let displayLoader: (Bool) -> Void

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .loadHistory:
        state.history = .loading
        return .run(priority: .userInitiated) { [wallet = state.wallet] send in
          displayLoader(true)
          do {
            let pubAddr = wallet.pubAddress.stringValue
            let pubHistory = try await Networking.getTxs(address: pubAddr)
            let chainHistory = pubHistory.compactMap { tx -> ChainTx? in
              let myVin = tx.vin.first { vin in
                vin.prevout.scriptpubkey_address == pubAddr
              }
              let isOutgoing = myVin != nil
              let myVout = tx.vout.first { vout in
                vout.scriptpubkey_address == pubAddr
              }
              let isIncoming = myVout != nil
              if !isOutgoing && !isIncoming {
                assertionFailure("unexpected outgoing state")
                return nil
              }
              let address: String
              let amount: String
              if isOutgoing {
                if let out = tx.vout.first {
                  address = out.scriptpubkey_address
                  amount = (balanceFmt.string(for: Double(out.value) / denominatorD) ?? "") + " BTC"
                } else {
                  address = ""
                  amount = ""
                }
              } else {
                let ours = tx.vout.filter { vout in
                  let ours = vout.scriptpubkey_address == pubAddr
                  return ours
                }
                address = tx.vin.first?.prevout.scriptpubkey_address ?? ""
                let value = ours.reduce(UInt64(0)) { partialResult, out in
                  partialResult + out.value
                }
                amount = (balanceFmt.string(for: Double(value) / denominatorD) ?? "") + " BTC"
              }
              return ChainTx(id: tx.txid, isOutgoing: isOutgoing, address: address, amount: amount)
            }
            await send(.setHistory(.history(chainHistory)))
          } catch {
            await send(.setHistory(.error(error)))
            onDisplayMessage(error.localizedDescription, .error)
          }
          displayLoader(false)
        }.cancellable(id: Cancel.history, cancelInFlight: true)
      case let .setHistory(v):
        state.history = v
        return .none
      case let .openHistory(item):
        onOpenTx(item.id)
        return .none
      }
    }
  }
}

extension Networking {
  static func getTxs(address: String, after: String? = nil) async throws -> [TxItem] {
    var query: [URLQueryItem] = []
    if let after {
      query.append(.init(name: "after_txid", value: after))
    }
    let response = try await Networking.get(path: "/address/\(address)/txs", query: query)
    if response.code != 200 {
      throw LoadHistoryError.load(String(data: response.data, encoding: .utf8))
    }
    return try response.decode()
  }
}

extension HistoryState {
  static func == (lhs: HistoryState, rhs: HistoryState) -> Bool {
    switch (lhs, rhs) {
    case (.loading, .loading):
      return true
    case let (.error(a), .error(b)):
      return a.localizedDescription == b.localizedDescription
    case let (.history(a), .history(b)):
      return a == b
    default:
      return false
    }
  }
}
