import Foundation
import HdWalletKit
import Models

struct Wallet: Equatable {
  let wallet: HDWallet
  let pubKey: PublicKey
  let pubKeyChange: PublicKey
  let pubAddress: Address
  let changeAddress: Address
  static func == (lhs: Wallet, rhs: Wallet) -> Bool {
    return lhs.wallet == rhs.wallet
  }
}
