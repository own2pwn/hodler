import ComposableArchitecture
import HdWalletKit
import SwiftUI

struct HistoryView: View {
  @Perception.Bindable var store: StoreOf<HistoryModel>

  var body: some View {
    return WithPerceptionTracking {
      ScrollView {
        content
      }
    }
  }

  private var content: some View {
    let view: any View
    switch store.history {
    case .loading:
      view = Text("Loading balance")
        .padding(.top, 16)
    case let .error(e):
      view = Text("Failed to load balance: \(e.localizedDescription)")
        .padding(.top, 16)
    case let .history(v):
      if v.isEmpty {
        view = Text("Nothing received. Yet.")
          .padding(.top, 16)
      } else {
        view = LazyVStack(alignment: .leading, spacing: 0) {
          Divider().padding(.top, 16)
          ForEach(v, id: \.id) { item in
            VStack(alignment: .leading, spacing: 0) {
              HStack(alignment: .center) {
                if item.isOutgoing {
                  Image(systemName: "arrow.up.right.circle.fill")
                    .imageScale(.large)
                } else {
                  Image(systemName: "arrow.down.right.circle.fill")
                    .imageScale(.large)
                }
                VStack(alignment: .leading, spacing: 0) {
                  Text(item.isOutgoing ? "Sent" : "Received")
                  Text((item.isOutgoing ? "To: " : "From: ") + item.address)
                    .font(.caption)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
                  Text(item.id)
                    .font(.caption)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
                }.padding(.leading, 8)
                Spacer()
                Text(item.amount)
                  .font(.callout)
                  .padding(.leading, 8)
              }
              .frame(height: 48)
              .padding(.top, 16)
              Divider().padding(.top, 16)
            }
          }
        }.padding(16)
      }
    }
    return AnyView(view)
  }
}
