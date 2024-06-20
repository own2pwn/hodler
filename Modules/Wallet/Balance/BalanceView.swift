import ComposableArchitecture
import HdWalletKit
import SwiftUI

struct BalanceView: View {
  @Perception.Bindable var store: StoreOf<BalanceModel>

  var body: some View {
    return WithPerceptionTracking {
      ScrollView {
        content
      }
    }
  }

  private var content: some View {
    return VStack(alignment: .leading, spacing: 0) {
      VStack(alignment: .leading, spacing: 0) {
        balanceView
        Divider().padding(.top, 16)
      }
      VStack(alignment: .leading, spacing: 0) {
        TextField("Amount to send (in BTC)", text: $store.amount.sending(\.setAmount))
          .keyboardType(.decimalPad)
          .padding(.top, 16)
        Divider().padding(.top, 16)
      }
      VStack(alignment: .leading, spacing: 0) {
        TextField("Recipient", text: $store.recipient.sending(\.setRecipient))
          .truncationMode(.middle)
          .padding(.top, 16)
        Divider().padding(.top, 16)
      }
      Button {
        store.send(.transfer)
      } label: {
        Text("Send")
          .font(.title3)
          .frame(maxWidth: .infinity, minHeight: 48)
      }
      .padding(.top, 16)
      .buttonStyle(.borderedProminent)
      Button {
        store.send(.loadBalance)
      } label: {
        Text("Refresh balance")
          .font(.body)
          .frame(maxWidth: .infinity, minHeight: 42)
      }
      .padding(.top, 16)
      .buttonStyle(.bordered)
    }
    .padding(16)
  }

  private var balanceView: some View {
    let title: String
    switch store.balance {
    case .loading:
      title = "Loading balance"
    case let .error(e):
      title = "Failed to load balance: \(e.localizedDescription)"
    case let .balance(satoshis):
      let value = balanceFmt.string(for: Double(satoshis) / denominatorD) ?? String(format: "%.6f", Double(satoshis) / denominatorD)
      title = "Balance: \(value) BTC"
    }
    return Text(title)
      .padding(.top, 16)
  }
}
