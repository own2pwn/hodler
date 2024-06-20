import EPRouter
import EPUIKit
import HdWalletKit
import UIKit

public final class WalletRouter: Router, PresentableRouter {
  public let viewController: UIViewController

  public var onLogout: (() -> Void)!

  let balanceRouter: BalanceRouter
  let historyRouter: HistoryRouter
  let settingsRouter: SettingsRouter

  public init(wallet: HDWallet) {
    let tabbar = BaseTabBarController()
    self.balanceRouter = BalanceRouter(wallet: wallet)
    self.historyRouter = HistoryRouter(wallet: wallet)
    self.settingsRouter = SettingsRouter()
    self.viewController = tabbar
    super.init()
    tabbar.viewControllers = [
      balanceRouter.viewController,
      historyRouter.viewController,
      settingsRouter.viewController,
    ]
    settingsRouter.onLogout = {
      self.onLogout()
    }
  }
}
