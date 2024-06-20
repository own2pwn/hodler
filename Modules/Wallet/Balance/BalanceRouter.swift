import ComposableArchitecture
import EPRouter
import EPUIKit
import HdWalletKit
import SwiftUI
import UIKit

final class BalanceRouter: NavigationRouter {
  private let navigationController: NavigationStackController

  init(wallet: HDWallet) {
    self.navigationController = NavigationStackController()
    super.init(navigationStack: navigationController)

    let balanceStore = Store(initialState: try! BalanceModel.State(wallet: wallet)) {
      BalanceModel(
        onShowTx: { [weak self] hash in
          guard let self else { return }
          self.showTx(hash: hash)
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
    let vc = BalanceViewController(store: balanceStore)
    let navigationBar = navigationController.navigationBar
    navigationBar.prefersLargeTitles = false
    navigationController.viewControllers = [vc]
    navigationController.tabBarItem = UITabBarItem(
      title: "Wallet",
      image: UIImage(systemName: "dollarsign.circle"),
      selectedImage: UIImage(systemName: "dollarsign.circle.fill")
    )
  }

  private func showTx(hash: String) {
    let contentView = TxView(
      txHash: hash,
      onOpenTx: {
        if let url = URL(string: "https://mempool.space/signet/tx/\(hash)") {
          UIApplication.shared.open(url)
        }
      },
      onClose: { [weak self] in
        self?.navigationController.dismiss(animated: true)
      }
    )
    let hostingController = UIHostingController(rootView: contentView)
    hostingController.view.backgroundColor = .systemBackground
    navigationController.present(hostingController, animated: true)
  }
}
