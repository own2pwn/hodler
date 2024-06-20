import UIKit

open class BaseViewController: UIViewController {
  public init() {
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  public required init?(coder: NSCoder) {
    return nil
  }

  #if DEBUG
    deinit {
      print("[DEINIT]", self)
    }
  #endif

  // MARK: -

  override open func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    setup()
  }

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    onWillAppear()
  }

  override open func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    onDidAppear()
  }

  override open func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    layout()
  }

  // MARK: -

  @inline(__always)
  open func setup() {}

  @inline(__always)
  open func onWillAppear() {}

  @inline(__always)
  open func onDidAppear() {}

  @inline(__always)
  open func layout() {}
}
