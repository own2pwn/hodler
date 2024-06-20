// swift-tools-version: 5.10
import PackageDescription

#if TUIST
  import ProjectDescription

  let moduleType: ProjectDescription.Product = .staticFramework

  let packageSettings = PackageSettings(
    productTypes: [
      "ComposableArchitecture": moduleType,
      "HdWalletKit": moduleType,
    ]
  )
#endif

let package = Package(
  name: "HODL",
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", exact: "1.10.4"),
    .package(url: "https://github.com/horizontalsystems/HdWalletKit.Swift", exact: "1.3.0"),
  ]
)
