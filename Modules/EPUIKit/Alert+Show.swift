import EPRouter
import UIKit

public enum AlertType {
  case success
  case error
  case info
}

final class AlertView: UIView {
  let alertLabel: UILabel = {
    let label = UILabel()
    label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
    label.textColor = .white
    label.textAlignment = .center
    label.numberOfLines = 4
    return label
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)
    addSubview(alertLabel)
    alertLabel.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      alertLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 16),
      alertLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
      alertLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
      alertLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -32),
    ])
    layer.cornerRadius = 34
    layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
    layer.allowsEdgeAntialiasing = true
    layer.cornerCurve = .continuous
    addGestureRecognizer { (_: UITapGestureRecognizer) in
      UINavigationController.hideAlert()
    }
    addGestureRecognizer { (pan: UIPanGestureRecognizer) in
      if pan.state == .ended || pan.state == .cancelled {
        UINavigationController.hideAlert()
      }
    }
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    return nil
  }

  func setup(message: String, type: AlertType) {
    alertLabel.text = message
    switch type {
    case .error:
      backgroundColor = .systemRed
    case .success:
      backgroundColor = .systemGreen
    case .info:
      backgroundColor = .systemBlue
    }
  }
}

public extension UIViewController {
  private static var isPresented = false
  private static let alertView = AlertView()
  private static var removeJob: DispatchWorkItem?

  func show(message: String, type: AlertType) {
    guard !Self.isPresented else {
      return
    }
    Self.isPresented = true
    let alertView = Self.alertView
    view.addSubview(alertView)
    alertView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      alertView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
      alertView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
      alertView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -0),
    ])
    alertView.setup(message: message, type: type)
    alertView.setNeedsLayout()
    view.setNeedsLayout()
//    alertView.update()
//    alertView.frame.size.width = view.bounds.width
//    alertView.frame.size.height = 64 + view.safeAreaInsets.top
//    alertView.frame.origin = view.bounds.origin
//    alertView.frame.origin.y = -alertView.frame.size.height
//    alertView.frame.origin.y = view.safeAreaInsets.top
//    alertView.alpha = 0
    alertView.alpha = 0
    alertView.alertLabel.alpha = 0
    UIView.animate(withDuration: 0.3) {
//      alertView.frame.origin.y = 0
      alertView.alpha = 1
      alertView.alertLabel.alpha = 1
    }
    let job = DispatchWorkItem {
      self.hideAlert()
      Self.removeJob = nil
    }
    Self.removeJob = job
    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(Int(3500)), execute: job)
  }

  static func hideAlert() {
    removeJob?.cancel()
    removeJob = nil
    UIView.animate(withDuration: 0.3) {
      alertView.alertLabel.alpha = 0
      alertView.alpha = 0
//      alertView.frame.origin.y = -alertView.frame.size.height
    } completion: { _ in
      alertView.removeFromSuperview()
      Self.isPresented = false
    }
  }

  func hideAlert() {
    Self.hideAlert()
  }
}

public extension PresentableRouter {
  func show(message: String, type: AlertType) {
    #if DEBUG
      if type == .error {
        print("[ERROR]:", message)
      }
    #endif
    viewController.show(message: message, type: type)
  }

  func display(error: Error) {
    #if DEBUG
      print("[ERROR]:", error.localizedDescription, error)
    #endif
    viewController.show(message: error.localizedDescription, type: .error)
  }
}

public extension ChildNavigationRouter {
  func show(message: String, type: AlertType) {
    #if DEBUG
      if type == .error {
        print("[ERROR]:", message)
      }
    #endif
    navigationRouter.navigationViewController.show(message: message, type: type)
  }

  func display(error: Error) {
    #if DEBUG
      print("[ERROR]:", error.localizedDescription, error)
    #endif
    navigationRouter.navigationViewController.show(message: error.localizedDescription, type: .error)
  }
}

final class AlertView1: UIView {
  let alertLabel: UILabel = {
    let label = UILabel()
    label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
    label.textColor = .white
    label.textAlignment = .center
    label.numberOfLines = 3
    return label
  }()

  var labelTopConstraint: NSLayoutConstraint?

  func setup(message: String, type: AlertType) {
    alertLabel.text = message
    switch type {
    case .error:
      backgroundColor = .systemRed
    case .success:
      backgroundColor = .systemGreen
    case .info:
      backgroundColor = .systemBlue
    }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    addSubview(alertLabel)
    alertLabel.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      alertLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
      alertLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
      alertLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
    ])
    self.frame.size.height = 100

    self.labelTopConstraint = alertLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
    labelTopConstraint?.isActive = true
    addGestureRecognizer { (_: UITapGestureRecognizer) in
      UINavigationController.hideAlert()
    }
    addGestureRecognizer { (pan: UIPanGestureRecognizer) in
      if pan.state == .ended || pan.state == .cancelled {
        UINavigationController.hideAlert()
      }
    }
  }

  func update() {
    if let c = labelTopConstraint, let p = superview {
      c.constant = p.safeAreaInsets.top / 2 - 4
    }
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    return nil
  }
}
