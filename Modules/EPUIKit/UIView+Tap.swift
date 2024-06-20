import UIKit

public func IsRecognizerTapHandler(_ recognizer: UIGestureRecognizer) -> Bool {
  return recognizer is CustomGestureRecognizer
}

private final class CustomGestureRecognizer: UIGestureRecognizer {
  private var firstTouchLocation: CGPoint?

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
    super.touchesBegan(touches, with: event)

    guard touches.count == 1 else {
      state = .failed
      return
    }

    if firstTouchLocation == nil {
      firstTouchLocation = touches.first?.location(in: view?.window)
      state = .began
    }

    var optSuperview: UIView? = view?.superview
    while let superview = optSuperview {
      if let scrollView = superview as? UIScrollView, scrollView.isDragging {
        state = .failed
        return
      }
      optSuperview = superview.superview
    }
  }

  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
    super.touchesMoved(touches, with: event)

    if let touch = touches.first, let firstTouchLocation = firstTouchLocation {
      let diffX = abs(firstTouchLocation.x - touch.location(in: view?.window).x)
      let diffY = abs(firstTouchLocation.y - touch.location(in: view?.window).y)
      if diffX > 10 || diffY > 10 {
        state = .cancelled
        return
      }
    }

    state = .changed
  }

  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
    super.touchesEnded(touches, with: event)

    state = .ended
  }

  override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
    super.touchesCancelled(touches, with: event)

    state = .cancelled
  }

  override func reset() {
    firstTouchLocation = nil
  }
}

private final class CancelableDelegate: NSObject, UIGestureRecognizerDelegate {
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return otherGestureRecognizer is UIPanGestureRecognizer
  }

  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
    return !(touch.view is UIControl)
  }
}

private let delegate = CancelableDelegate()

public extension UIView {
  func removeTapHandler() {
    gestureRecognizers?.filter { $0 is CustomGestureRecognizer }.forEach(removeGestureRecognizer)
  }

  @discardableResult
  func addTapHandler(_ tapHandler: @escaping (Self) -> Void) -> UIGestureRecognizer {
    removeTapHandler()
    let recognizer = addGestureRecognizer { [weak self] (recognizer: CustomGestureRecognizer) in
      guard let self = self else { return }

      let oldSize = max(self.frame.width, self.frame.height)
      let newSize = oldSize - 8
      let finalScale = newSize / oldSize

      if recognizer.state == .began {
        UIView.animate(withDuration: 0.1, animations: {
          self.transform = CGAffineTransform.identity.scaledBy(x: finalScale, y: finalScale)
        })
      }

      if Set([UIGestureRecognizer.State.failed, UIGestureRecognizer.State.cancelled, UIGestureRecognizer.State.ended]).contains(recognizer.state) {
        let ended = recognizer.state == .ended

        UIView.animate(withDuration: 0.1, animations: {
          self.transform = CGAffineTransform.identity
        }, completion: { _ in
          if ended {
            tapHandler(self as! Self)
          }
        })
      }
    }

    recognizer.delegate = delegate
    return recognizer
  }

  @discardableResult
  func addTapHandler(_ tapHandler: @escaping () -> Void) -> UIGestureRecognizer {
    return addTapHandler { _ in
      tapHandler()
    }
  }
}
