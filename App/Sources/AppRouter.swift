import Combine
import EPRouter
import EPUIKit
import Onboarding
import UIKit
import Wallet

final class AppRouter: Router {
  private unowned(unsafe) var window: UIWindow?
  private let controller: AppController
  private unowned var onboardingRouter: OnboardingRouter?
  private unowned var walletRouter: WalletRouter?

  override init() {
    self.controller = AppController()
    super.init()
  }

  func setup(in window: UIWindow) {
    let navBarAppearanceProxy = UINavigationBar.appearance()
    navBarAppearanceProxy.tintColor = .label
    self.window = window
    start()
  }

  private func start() {
    switch controller.state {
    case let .onboarded(state):
      startMainFlow(state: state)
    case .notOnboarded:
      startOnboarding()
    }
  }

  private func startMainFlow(state: WalletState) {
    let router = WalletRouter(wallet: state.wallet)
    walletRouter = router
    attach(router)
    window?.rootViewController = router.viewController
    window?.makeKeyAndVisible()
  }

  private func startOnboarding() {
    let router = OnboardingRouter()
    router.onFinish = { [unowned router] seed in
      self.controller.onboard(seed: seed)
      self.start()
      self.detach(router)
      self.onboardingRouter = nil
    }
    attach(router)
    onboardingRouter = router
    window?.rootViewController = router.viewController
    window?.makeKeyAndVisible()
  }
}
