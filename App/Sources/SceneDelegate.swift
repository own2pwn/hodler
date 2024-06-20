import EPUIKit
import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?
  private let appRouter = AppRouter()

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard let ws = (scene as? UIWindowScene) else { return }
    let window = UIWindow(windowScene: ws)
    self.window = window
    appRouter.setup(in: window)
    window.makeKeyAndVisible()
    UIScrollView.appearance().keyboardDismissMode = .onDrag
  }
}
