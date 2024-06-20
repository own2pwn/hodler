import EPRouter
import UIKit

public extension UIViewController {
  func showLoader() {
    if view.subviews.contains(where: { $0.tag == 9991 }) {
      return
    }
    let spinnerView = SpinnerView(frame: CGRect(origin: .zero, size: CGSize(width: 64, height: 64)))
    spinnerView.tag = 9991
    spinnerView.layer.zPosition = 1000
    view.addSubview(spinnerView)
    spinnerView.center = view.center
  }

  func hideLoader() {
    if let spinnerView = view.subviews.first(where: { $0.tag == 9991 }) {
      spinnerView.removeFromSuperview()
    }
  }
}

public extension PresentableRouter {
  func showLoader() {
    viewController.showLoader()
  }

  func hideLoader() {
    viewController.hideLoader()
  }
}
