import Combine
import UIKit

open class NavigationRouter: Router, PresentableRouter {
  open var viewController: UIViewController {
    return navigationStackController
  }

  public var navigationViewController: UINavigationController {
    return navigationStackController
  }

  public private(set) var context: [Any] = []

  private let navigationStackController: NavigationStackController

  public init(navigationStack: NavigationStackController) {
    self.navigationStackController = navigationStack
  }

  open func reset(with viewController: UIViewController = UIViewController(), animated: Bool = false) {
    navigationStackController.setViewControllers([viewController], animated: animated)
  }

  open func push(router: PresentableRouter) {
    attach(router)
    bindDetach(router)
    navigationStackController.pushViewController(router.viewController, animated: true)
  }

  open func present(router: PresentableRouter) {
    attach(router)
    navigationStackController.present(router.viewController, animated: true)
    bindDetach(router)
  }

  open func dismiss() {
    navigationStackController.dismiss(animated: true)
  }

  open func pop() {
    navigationStackController.popViewController(animated: true)
  }

  open func popToRoot() {
    navigationStackController.popToRootViewController(animated: true)
  }

  open func replace(with router: PresentableRouter) {
    attach(router)
    bindDetach(router)
    var controllers = navigationStackController.viewControllers
    controllers.removeLast()
    controllers.append(router.viewController)
    navigationStackController.setViewControllers(controllers, animated: true)
  }

  public func addContext(_ context: Any) {
    self.context.append(context)
  }

  public func replaceContext<T>(_ context: T) {
    if let index = self.context.firstIndex(where: { $0 as? T != nil }) {
      self.context.remove(at: index)
    }
    addContext(context)
  }

  public func getContext<T>(of type: T.Type = T.self) -> T? {
    return context.first(where: { $0 as? T != nil }) as? T
  }

  public func bindDetach(_ router: PresentableRouter) {
    let viewControllerToObserve: UIViewController
    if let nav = router.viewController as? UINavigationController, let top = nav.topViewController {
      viewControllerToObserve = top
    } else {
      viewControllerToObserve = router.viewController
    }
    let observer = LifecycleViewController(observedParent: router.viewController)
    viewControllerToObserve.addChild(observer)
    viewControllerToObserve.view.insertSubview(observer.view, at: 0)
    observer.didMove(toParent: viewControllerToObserve)

    #if DEBUG
      var sink: Subscribers.Sink<LifecycleViewController.DetachReason, Never>?
      sink = Subscribers.Sink<LifecycleViewController.DetachReason, Never>(
        receiveCompletion: { _ in sink = nil },
        receiveValue: { reason in
          print("[NavRouter]:", router, reason, "-> detached from", self)
          self.detach(router)
        }
      )
      observer.didDetachPublisher.subscribe(sink.unsafelyUnwrapped)
    #else
      var sink: Subscribers.Sink<Void, Never>?
      sink = Subscribers.Sink<Void, Never>(
        receiveCompletion: { _ in sink = nil },
        receiveValue: {
          self.detach(router)
        }
      )
      observer.didDetachPublisher.subscribe(sink.unsafelyUnwrapped)
    #endif
  }
}

private class InvisibleView: UIView {
  override var isHidden: Bool {
    get {
      return super.isHidden
    }
    set {
      assert(newValue == true)
      super.isHidden = newValue
    }
  }

  override var isUserInteractionEnabled: Bool {
    get {
      return super.isHidden
    }
    set {
      assert(newValue == false)
      super.isHidden = newValue
    }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    hide()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    hide()
  }

  func hide() {
    isHidden = true
    isUserInteractionEnabled = false
  }
}

private final class LifecycleViewController: UIViewController {
  enum DetachReason {
    case disappear
    case `deinit`
  }

  private unowned(unsafe) let observedParent: UIViewController
  #if DEBUG
    private let didDetachSubject = PassthroughSubject<DetachReason, Never>()
  #else
    private let didDetachSubject = PassthroughSubject<Void, Never>()
  #endif

  #if DEBUG
    var didDetachPublisher: AnyPublisher<DetachReason, Never> {
      return didDetachSubject.first().eraseToAnyPublisher()
    }
  #else
    var didDetachPublisher: AnyPublisher<Void, Never> {
      return didDetachSubject.first().eraseToAnyPublisher()
    }
  #endif

  init(observedParent: UIViewController) {
    self.observedParent = observedParent
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    return nil
  }

  deinit {
    #if DEBUG
      didDetachSubject.send(.deinit)
    #else
      didDetachSubject.send()
    #endif
  }

  override func loadView() {
    view = InvisibleView()
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    let observing = observedParent
    if observing.isMovingFromParent || observing.isBeingDismissed || observing.parent == nil {
      #if DEBUG
        didDetachSubject.send(.disappear)
      #else
        didDetachSubject.send()
      #endif
    }
  }
}
