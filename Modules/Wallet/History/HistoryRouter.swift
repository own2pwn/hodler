import ComposableArchitecture
import EPRouter
import EPUIKit
import HdWalletKit
import SwiftUI
import UIKit

final class HistoryRouter: NavigationRouter {
  private let navigationController: NavigationStackController

  init(wallet: HDWallet) {
    self.navigationController = NavigationStackController()
    super.init(navigationStack: navigationController)

    let historyStore = Store(initialState: try! HistoryModel.State(wallet: wallet)) {
      HistoryModel(
        onOpenTx: { [weak self] tx in
          self?.openTx(id: tx)
        },
        onDisplayMessage: { [weak self] message, type in
          guard let self else { return }
          DispatchQueue.main.async {
            self.show(message: message, type: type)
          }
        },
        displayLoader: { [weak self] show in
          guard let self else { return }
          DispatchQueue.main.async {
            if show {
              self.showLoader()
            } else {
              self.hideLoader()
            }
          }
        }
      )
    }
    let vc = HistoryViewController(store: historyStore)
    let navigationBar = navigationController.navigationBar
    navigationBar.prefersLargeTitles = false
    navigationController.viewControllers = [vc]
    navigationController.tabBarItem = UITabBarItem(
      title: "History",
      image: UIImage(systemName: "clock"),
      selectedImage: UIImage(systemName: "clock.fill")
    )
  }

  private func openTx(id: String) {
    if let url = URL(string: "https://mempool.space/signet/tx/\(id)") {
      UIApplication.shared.open(url)
    }
  }
}
