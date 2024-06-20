import ProjectDescription

public let version = "0.1.1"
public let deploymentTargetString = "15.1"
public let appDeploymentTargets: DeploymentTargets = .iOS(deploymentTargetString)
public let appDestinations: Destinations = [.iPhone]
public let moduleType: Product = .staticFramework

let project = Project(
  name: "HODL",
  options: .options(
    disableShowEnvironmentVarsInScriptPhases: true,
    textSettings: .textSettings(
      indentWidth: 2,
      tabWidth: 2
    )
  ),

  settings: .settings(
    base: [
      "IPHONEOS_DEPLOYMENT_TARGET": SettingValue(stringLiteral: deploymentTargetString),
      "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
      "CODE_SIGN_IDENTITY": "",
      "CODE_SIGNING_REQUIRED": "NO",
      "DEVELOPMENT_TEAM": "FILL_ME", // TODO: PUT YOUR DEV TEAM
      "OTHER_LDFLAGS": "$(inherited)",
      "ENABLE_MODULE_VERIFIER": "YES",
    ],
    debug: [
      "DEBUG_INFORMATION_FORMAT": "dwarf",
      "SWIFT_OPTIMIZATION_LEVEL": "-Onone",
      "GCC_OPTIMIZATION_LEVEL": "0",
      "GCC_PREPROCESSOR_DEFINITIONS": "DEBUG=1 $(inherited)",
      "OTHER_SWIFT_FLAGS": "-D DEBUG $(inherited) -Xfrontend -warn-long-function-bodies=250 -Xfrontend -warn-long-expression-type-checking=250 -Xfrontend -debug-time-function-bodies -Xfrontend -enable-actor-data-race-checks",
      "OTHER_LDFLAGS": "-Xlinker -interposable $(inherited)",
    ]
  ),

  targets: [
    .target(
      name: "HODL",
      destinations: appDestinations,
      product: .app,
      bundleId: "app.hodl.ios",
      deploymentTargets: appDeploymentTargets,
      infoPlist: .extendingDefault(
        with: [
          "CFBundleShortVersionString": Plist.Value(stringLiteral: version),
          "UIApplicationSceneManifest": [
            "UIApplicationSupportsMultipleScenes": false,
            "UISceneConfigurations": [
              "UIWindowSceneSessionRoleApplication": [
                [
                  "UISceneConfigurationName": "Default",
                  "UISceneDelegateClassName": "$(PRODUCT_MODULE_NAME).SceneDelegate",
                ],
              ],
            ],
          ],
          "ITSAppUsesNonExemptEncryption": false,
          "UILaunchScreen": [
            "UILaunchScreen": [:],
          ],
          "UISupportedInterfaceOrientations": [
            "UIInterfaceOrientationPortrait",
          ],
          "UISupportedInterfaceOrientations~ipad": [
            "UIInterfaceOrientationPortrait",
            "UIInterfaceOrientationPortraitUpsideDown",
            "UIInterfaceOrientationLandscapeLeft",
            "UIInterfaceOrientationLandscapeRight",
          ],
          "UILaunchStoryboardName": "LaunchScreen.storyboard",
        ]
      ),
      sources: ["App/Sources/**"],
      resources: [
        "App/Resources/**",
      ],
      dependencies: [
        .external(name: "ComposableArchitecture"),
        .external(name: "HdWalletKit"),
        .target(name: "Keychain"),
        .target(name: "EPRouter"),
        .target(name: "Networking"),
        .target(name: "EPUIKit"),
        .target(name: "Models"),
        .target(name: "ModelExtensions"),
        .target(name: "Onboarding"),
        .target(name: "Wallet"),
      ],
      settings: .settings(
        base: [
          "CODE_SIGN_STYLE": "Automatic",
          "MARKETING_VERSION": SettingValue(stringLiteral: version),
          "CODE_SIGN_IDENTITY": "iPhone Developer",
          "CODE_SIGNING_REQUIRED": "YES",
        ]
      )
    ),

    .target(
      name: "Keychain",
      destinations: appDestinations,
      product: moduleType,
      bundleId: "app.hodl.ios.keychain",
      sources: ["Modules/Keychain/**"]
    ),

    .target(
      name: "EPRouter",
      destinations: appDestinations,
      product: moduleType,
      bundleId: "app.hodl.ios.eprouter",
      sources: ["Modules/EPRouter/**"]
    ),

    .target(
      name: "Models",
      destinations: appDestinations,
      product: moduleType,
      bundleId: "app.hodl.ios.models",
      sources: ["Modules/Models/**"],
      dependencies: [
        .external(name: "HdWalletKit"),
      ]
    ),

    .target(
      name: "Networking",
      destinations: appDestinations,
      product: moduleType,
      bundleId: "app.hodl.ios.networking",
      sources: ["Modules/Networking/**"],
      resources: [],
      dependencies: [
        .target(name: "Keychain"),
      ]
    ),

    .target(
      name: "EPUIKit",
      destinations: appDestinations,
      product: moduleType,
      bundleId: "app.hodl.ios.epuikit",
      sources: ["Modules/EPUIKit/**"],
      resources: [],
      dependencies: [
        .target(name: "EPRouter"),
        .external(name: "ComposableArchitecture"),
      ]
    ),

    .target(
      name: "ModelExtensions",
      destinations: appDestinations,
      product: moduleType,
      bundleId: "app.hodl.ios.modelextensions",
      sources: ["Modules/ModelExtensions/**"],
      dependencies: [
        .target(name: "Models"),
        .target(name: "EPUIKit"),
        .external(name: "HdWalletKit"),
      ]
    ),

    .target(
      name: "Onboarding",
      destinations: appDestinations,
      product: moduleType,
      bundleId: "app.hodl.ios.onboarding",
      sources: ["Modules/Onboarding/**"],
      dependencies: [
        .target(name: "EPRouter"),
        .target(name: "EPUIKit"),
        .external(name: "HdWalletKit"),
      ]
    ),

    .target(
      name: "Wallet",
      destinations: appDestinations,
      product: moduleType,
      bundleId: "app.hodl.ios.wallet",
      sources: ["Modules/Wallet/**"],
      dependencies: [
        .target(name: "EPRouter"),
        .target(name: "EPUIKit"),
        .target(name: "Networking"),
        .target(name: "Models"),
        .target(name: "ModelExtensions"),
        .external(name: "HdWalletKit"),
      ]
    ),
  ]
)
