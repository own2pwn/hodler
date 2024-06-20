import Foundation
import HdWalletKit
import Models

let addressConverter = SegWitBech32AddressConverter(prefix: "tb")

let denominatorD: Double = 100_000_000

let balanceFmt: NumberFormatter = {
  let formatter = NumberFormatter()
  formatter.maximumFractionDigits = 9
  formatter.minimumFractionDigits = 0
  formatter.numberStyle = .decimal
//  formatter.decimalSeparator = "."
  return formatter
}()
