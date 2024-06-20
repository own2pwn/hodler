import ComposableArchitecture
import EPUIKit
import SwiftUI
import UIKit

final class BalanceViewController: BaseViewController {
  init(store: StoreOf<BalanceModel>) {
    super.init()
    title = "Balance"
    let contentView = BalanceView(store: store)
    let hostingController = UIHostingController(rootView: contentView)
    embed(hostingController)
    hostingController.view.backgroundColor = .systemBackground
    store.send(.loadBalance)
  }
}
