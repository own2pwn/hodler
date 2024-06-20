import SwiftUI

public extension View {
  func disableWithOpacity(_ condition: Bool, _ opacity: CGFloat = 0.5) -> some View {
    disabled(condition)
      .opacity(condition ? opacity : 1)
  }
}
