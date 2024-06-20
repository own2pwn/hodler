import UIKit

public protocol PresentableRouter: Router {
  var viewController: UIViewController { get }
}

open class Router {
  open var children: [Router] = []
  open unowned(unsafe) var parent: Router?

  public init() {}

  #if DEBUG
    deinit {
      print("[DEINIT]", self)
    }
  #endif

  private static func detachRecursively(_ router: Router) {
    while let child = router.children.last {
      detachRecursively(child)
      router.detach(child)
    }
  }

  public final func attach(_ child: Router) {
    children.append(child)
    child.parent = self
    child.onAttach()
  }

  public final func detach(_ child: Router) {
    guard let childIndex = children.firstIndex(where: { $0 === child }) else {
      #if DEBUG
        print("[WARN]:[ROUTER]:child not found:", child)
      #endif
      return
    }
    Router.detachRecursively(child)
    children.remove(at: childIndex)
    child.parent = nil
    child.onDetach()
  }

  open func onAttach() {}

  open func onDetach() {}
}

open class ChildNavigationRouter: Router {
  public let navigationRouter: NavigationRouter

  public init(navigationRouter: NavigationRouter) {
    self.navigationRouter = navigationRouter
  }
}

public extension Router {
  @discardableResult
  func openURL(_ url: URL) -> Bool {
    let a = UIApplication.shared
    guard a.canOpenURL(url) else {
      return false
    }
    a.open(url, options: [:])
    return true
  }

  @discardableResult
  func openURL(_ url: String) -> Bool {
    guard let url = URL(string: url) else {
      return false
    }

    let a = UIApplication.shared
    guard a.canOpenURL(url) else {
      return false
    }
    a.open(url, options: [:])
    return true
  }
}

public extension Router {
  func openURL(_ url: URL, fallback: URL) {
    let a = UIApplication.shared
    if a.canOpenURL(url) {
      a.open(url, options: [:])
    } else {
      a.open(fallback, options: [:])
    }
  }

  func openURL(_ url: String, fallback: String) {
    let a = UIApplication.shared
    if let url = URL(string: url), a.canOpenURL(url) {
      a.open(url, options: [:])
    } else if let fallback = URL(string: fallback) {
      a.open(fallback, options: [:])
    }
  }
}
