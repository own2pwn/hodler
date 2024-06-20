import EPRouter
import UIKit

public final class SettingsRouter: NavigationRouter {
  public var onLogout: (() -> Void)!

  private let navigationController: NavigationStackController

  public init() {
    self.navigationController = NavigationStackController()
    super.init(navigationStack: navigationController)

    let vc = SettingsViewController(router: self)
    let navigationBar = navigationController.navigationBar
    navigationBar.prefersLargeTitles = false
    navigationController.viewControllers = [vc]
    navigationController.tabBarItem = UITabBarItem(
      title: "Settings",
      image: UIImage(systemName: "gear"),
      selectedImage: UIImage(systemName: "gear")
    )
  }

  func logout() {
    onLogout()
  }
}
