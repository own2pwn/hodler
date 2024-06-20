import SwiftUI
import UIKit

public extension UIViewController {
  func addDismissOnTap() {
    let tap = UITapGestureRecognizer(target: self, action: #selector(handleDismissTap))
    view.addGestureRecognizer(tap)
  }

  @objc
  private func handleDismissTap() {
    view.endEditing(false)
  }
}

public extension View {
  func hideKeyboard() {
    let resign = #selector(UIResponder.resignFirstResponder)
    UIApplication.shared.sendAction(resign, to: nil, from: nil, for: nil)
  }
}
