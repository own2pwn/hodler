import SwiftUI

struct TxView: View {
  let txHash: String
  let onOpenTx: () -> Void
  let onClose: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      VStack(alignment: .leading, spacing: 0) {
        Text("Your transaction has been sent")
          .font(.title2)
          .padding(.top, 16)
        Text("Tx id: \(txHash)")
          .font(.title3)
          .padding(.top, 8)
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity, alignment: .leading)
          .onTapGesture {
            UIPasteboard.general.string = txHash
          }
      }
      Spacer()
      Button {
        onOpenTx()
      } label: {
        Text("Open in explorer")
          .frame(maxWidth: .infinity, minHeight: 44)
      }
      .buttonStyle(.borderedProminent)
      Button {
        onClose()
      } label: {
        Text("Done")
          .frame(maxWidth: .infinity, minHeight: 44)
      }
      .padding(.top, 16)
      .padding(.bottom, 24)
      .buttonStyle(.bordered)
    }.padding(16)
  }
}
