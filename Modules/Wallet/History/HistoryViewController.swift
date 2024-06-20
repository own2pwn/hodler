import ComposableArchitecture
import EPUIKit
import SwiftUI
import UIKit

final class HistoryViewController: BaseViewController {
  private let store: StoreOf<HistoryModel>
  init(store: StoreOf<HistoryModel>) {
    self.store = store
    super.init()
    title = "History"
    let contentView = HistoryView(store: store)
    let hostingController = UIHostingController(rootView: contentView)
    embed(hostingController)
    hostingController.view.backgroundColor = .systemBackground
  }

  override func onWillAppear() {
    store.send(.loadHistory)
  }
}
