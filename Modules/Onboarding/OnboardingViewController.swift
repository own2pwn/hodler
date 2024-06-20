import EPUIKit
import HdWalletKit
import SwiftUI
import UIKit

final class OnboardingViewController: BaseViewController {
  private unowned let router: OnboardingRouter

  init(router: OnboardingRouter) {
    self.router = router
    super.init()
  }

  override func setup() {
    title = "Create wallet"
    let contentView = OnboardingView(onContinue: { [unowned self] seedWords in
      let seed = Mnemonic.seed(mnemonic: seedWords, passphrase: "HODL")
      self.router.finish(walletSeed: seed!)
    })
    let hostingController = UIHostingController(rootView: contentView)
    embed(hostingController)
    hostingController.view.backgroundColor = .systemBackground
  }
}
