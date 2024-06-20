import EPRouter
import EPUIKit
import HdWalletKit
import UIKit

public final class WalletRouter: Router, PresentableRouter {
  public let viewController: UIViewController
  let balanceRouter: BalanceRouter
  let historyRouter: HistoryRouter

  public init(wallet: HDWallet) {
    let tabbar = BaseTabBarController()
    self.balanceRouter = BalanceRouter(wallet: wallet)
    self.historyRouter = HistoryRouter(wallet: wallet)
    self.viewController = tabbar
    super.init()
    tabbar.viewControllers = [balanceRouter.viewController, historyRouter.viewController]
  }
}
