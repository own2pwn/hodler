import EPRouter
import UIKit

public final class OnboardingRouter: NavigationRouter {
  public var onFinish: ((Data) -> Void)!

  private let navigationController: NavigationStackController

  public init() {
    self.navigationController = NavigationStackController()
    super.init(navigationStack: navigationController)

    let onboardingViewController = OnboardingViewController(router: self)
    let navigationBar = navigationController.navigationBar
    navigationBar.prefersLargeTitles = true
    navigationController.viewControllers = [onboardingViewController]
  }

  func finish(walletSeed: Data) {
    onFinish(walletSeed)
  }
}
