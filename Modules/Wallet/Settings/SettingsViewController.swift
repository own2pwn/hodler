import EPUIKit
import HdWalletKit
import SwiftUI
import UIKit

final class SettingsViewController: BaseViewController {
  private unowned let router: SettingsRouter

  init(router: SettingsRouter) {
    self.router = router
    super.init()
  }

  override func setup() {
    title = "Settings"

    let button = ButtonView()
    button.set(text: "Logout")
    button.set(enabled: true)
    view.addSubview(button)
    button.backgroundColor = .systemRed
    button.textLabel.textColor = .white
    button.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
      button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
      button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24)
    ])
    button.addTapHandler { [unowned self] in
      self.confirmLogout()
    }
  }

  private func confirmLogout() {
    let alert = UIAlertController(title: "Logout", message: "This will delete your private key", preferredStyle: .actionSheet)
    alert.addAction(
      UIAlertAction(title: "Logout", style: .destructive) { _ in
        self.router.logout()
      }
    )
    alert.addAction(
      UIAlertAction(title: "Cancel", style: .cancel) { _ in }
    )
    present(alert, animated: true)
  }
}

public final class ButtonView: UIView {
  public let textLabel = UILabel()

  override init(frame: CGRect) {
    super.init(frame: frame)
    addSubview(textLabel)
    textLabel.font = UIFont.preferredFont(forTextStyle: .title3)
    layer.cornerRadius = 16
    backgroundColor = UIColor.systemBlue
    translatesAutoresizingMaskIntoConstraints = false
    textLabel.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      heightAnchor.constraint(equalToConstant: 56),
      textLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
      textLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    return nil
  }

  public func set(enabled: Bool) {
    isUserInteractionEnabled = enabled
    alpha = enabled ? 1 : 0.5
  }

  public func set(text: String) {
    textLabel.text = text
  }
}
