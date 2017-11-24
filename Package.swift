// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PerfectSSH",
    products: [
        .library(
            name: "PerfectSSH",
            targets: ["PerfectSSH"]),
    ],
    dependencies: [
      .package(url: "https://github.com/PerfectSideRepos/SSHApi.git", from: "3.0.0")
    ],
    targets: [
      .target(name: "mininet", dependencies: []),
      .target(name: "PerfectSSH", dependencies: ["mininet"]),
      .testTarget(name: "PerfectSSHTests", dependencies: ["PerfectSSH"])
    ]
)
