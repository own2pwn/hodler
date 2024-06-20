import UIKit

public extension UIViewController {
  func embed(_ child: UIViewController) {
    guard let childView = child.view else { return }
    addChild(child)
    view.addSubview(childView)
    childView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      childView.topAnchor.constraint(equalTo: view.topAnchor),
      childView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      childView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      childView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
    ])
    child.didMove(toParent: self)
  }
}
