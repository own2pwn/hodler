import HdWalletKit
import SwiftUI

struct OnboardingView: View {
  private let seedWords = try! Mnemonic.generate(wordCount: .twentyFour, language: .english)

  let onContinue: ([String]) -> Void

  var body: some View {
    return ScrollView {
      content
    }
  }

  private var content: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text("Your 24-Word Seed Phrase")
        .font(.headline)
      Text("Save it in a secure place")
        .font(.callout)
        .foregroundStyle(.secondary)
        .padding(.top, 2)

      LazyVGrid(columns: [
        GridItem(.flexible()),
        GridItem(.flexible()),
      ], spacing: 8) {
        ForEach(0 ..< seedWords.count, id: \.self) { index in
          HStack(alignment: .center, spacing: 2) {
            Text("\(index + 1).")
              .font(.callout)
              .foregroundColor(.gray)
              .padding(.top, 2)
            Text(seedWords[index])
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(8)
          .background(Color(UIColor.systemGray6))
          .cornerRadius(8)
        }
      }.padding(.top, 16)

      Button {
        onContinue(seedWords)
      } label: {
        Text("Continue")
          .font(Font(UIFont.systemFont(ofSize: 16, weight: .semibold)))
          .frame(maxWidth: .infinity, minHeight: 42)
      }
      .padding(.top, 16)
      .buttonStyle(.borderedProminent)
      .disableWithOpacity(false)
    }.padding(16)
  }
}
