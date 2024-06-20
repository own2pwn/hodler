import Foundation
import HdWalletKit
import Keychain
import Networking

struct WalletState: Codable {
  enum CodingKeys: CodingKey {
    case seed
  }

  let wallet: HDWallet
  private let seed: Data

  init(seed: Data) {
    self.seed = seed
    self.wallet = HDWallet(seed: seed, coinType: 1, xPrivKey: HDExtendedKeyVersion.xprv.rawValue, purpose: .bip86)
  }

  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let seed = try container.decode(Data.self, forKey: .seed)
    self.wallet = HDWallet(seed: seed, coinType: 1, xPrivKey: HDExtendedKeyVersion.xprv.rawValue, purpose: .bip86)
    self.seed = seed
  }

  func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(seed, forKey: .seed)
  }
}

final class AppController {
  enum State {
    case onboarded(WalletState), notOnboarded
  }

  var state: State

  init() {
    if let walletState: WalletState = try? Keychain.read(AppKeys.walletState) {
      self.state = .onboarded(walletState)
    } else {
      self.state = .notOnboarded
    }
  }

  func onboard(seed: Data) {
    let state = WalletState(seed: seed)
    try! Keychain.save(AppKeys.walletState, item: state)
    self.state = .onboarded(state)
  }

  func logout() {
    try! Keychain.delete(AppKeys.walletState)
    state = .notOnboarded
  }
}
