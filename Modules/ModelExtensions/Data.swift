import Foundation

public extension Data {
  init?(hex: String) {
    guard hex.count % 2 == 0 else {
      return nil
    }
    let len = hex.count / 2
    var data = Data(capacity: len)
    var byteArray = [UInt8](repeating: 0, count: len)
    for (index, char) in hex.enumerated() {
      let nibble: UInt8
      switch char {
      case "0" ... "9":
        nibble = UInt8(char.unicodeScalars.first!.value - UnicodeScalar("0").value)
      case "a" ... "f":
        nibble = UInt8(char.unicodeScalars.first!.value - UnicodeScalar("a").value) + 10
      case "A" ... "F":
        nibble = UInt8(char.unicodeScalars.first!.value - UnicodeScalar("A").value) + 10
      default:
        return nil
      }
      if index % 2 == 0 {
        byteArray[index / 2] = nibble << 4
      } else {
        byteArray[index / 2] |= nibble
      }
    }
    data.append(contentsOf: byteArray)
    self = data
  }
}
