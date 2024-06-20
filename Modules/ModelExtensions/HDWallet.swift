import Foundation
import HdWalletKit
import Models

extension HDWallet: Equatable {
  public static func == (lhs: HdWalletKit.HDWallet, rhs: HdWalletKit.HDWallet) -> Bool {
    return lhs.masterKey.raw == rhs.masterKey.raw
  }
}
