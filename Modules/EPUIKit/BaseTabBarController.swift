import Combine
import UIKit

public final class BaseTabBarController: UITabBarController, UITabBarControllerDelegate {
  override public var childForStatusBarStyle: UIViewController? {
    return selectedViewController
  }

  public var selectedIndexPublisher: AnyPublisher<Int, Never> {
    return selectedIndexSubject.eraseToAnyPublisher()
  }

  private let selectedIndexSubject = PassthroughSubject<Int, Never>()

  override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    self.delegate = self
    setupColor()
  }

  @available(*, unavailable)
  public required init?(coder: NSCoder) {
    return nil
  }

  public func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
    if let index = viewControllers?.firstIndex(of: viewController) {
      selectedIndexSubject.send(index)
    }
  }

  private func setupColor() {
    let appearance = UITabBarAppearance()
    appearance.configureWithDefaultBackground()
    appearance.backgroundColor = .systemBackground
    tabBar.standardAppearance = appearance
    if #available(iOS 15.0, *) {
      tabBar.scrollEdgeAppearance = appearance
    }
    tabBar.tintColor = .label
  }
}
