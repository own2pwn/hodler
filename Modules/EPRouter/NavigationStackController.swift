import Combine
import UIKit

public final class NavigationStackController: UINavigationController, UINavigationControllerDelegate {
    override public var childForStatusBarStyle: UIViewController? {
        return presentedViewController ?? topViewController
    }

    public var willShowControllerPublisher: AnyPublisher<UIViewController, Never> {
        return willShowControllerSubject.eraseToAnyPublisher()
    }

    public var didShowControllerPublisher: AnyPublisher<UIViewController, Never> {
        return didShowControllerSubject.eraseToAnyPublisher()
    }

    private let willShowControllerSubject = PassthroughSubject<UIViewController, Never>()
    private let didShowControllerSubject = PassthroughSubject<UIViewController, Never>()

    public init() {
        super.init(nibName: nil, bundle: nil)
        self.delegate = self
    }

    override public init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        self.delegate = self
    }

    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.delegate = self
    }

    @available(*, unavailable)
    public required init?(coder aDecoder: NSCoder) {
        return nil
    }

    public func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        willShowControllerSubject.send(viewController)
    }

    public func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        didShowControllerSubject.send(viewController)
    }
}
