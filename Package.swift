// swift-tools-version: 5.9
import PackageDescription

let githubBaseURL = "https://github.com/fox156/htcnet-deps/releases/download"

let libsignalVersion = "libsignal-v0.86.16j"
let signalFfiChecksum = "83e13888c05f163069e6ec74c2afa8776cce70035fcaa25f5c074bb51892dfa5"

let sqlcipherVersion = "sqlcipher-v4.6.1-fts5c"
let sqlcipherChecksum = "795454eeaaf4d59795f0fb49d115a4d868020523e8591873706ca12508850872"

let package = Package(
    name: "HTCNetDeps",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "LibSignalClient", targets: ["LibSignalClient"]),
        .library(name: "GRDB", targets: ["GRDB"]),
    ],
    dependencies: [
        .package(url: "https://github.com/stasel/WebRTC.git", exact: "141.0.0"),
    ],
    targets: [
        .binaryTarget(
            name: "SignalFfi",
            url: "\(githubBaseURL)/\(libsignalVersion)/LibSignalFFI.xcframework.zip",
            checksum: signalFfiChecksum
        ),
        .binaryTarget(
            name: "GRDBSQLCipher",
            url: "\(githubBaseURL)/\(sqlcipherVersion)/SQLCipher.xcframework.zip",
            checksum: sqlcipherChecksum
        ),
        .target(
            name: "LibSignalClient",
            dependencies: ["SignalFfi"],
            path: "Sources/LibSignalClient",
            swiftSettings: [
                .define("SIGNAL_MEDIA_SUPPORTED", .when(platforms: [.iOS])),
            ]
        ),
        .target(
            name: "GRDB",
            dependencies: ["GRDBSQLCipher"],
            path: "Sources/GRDB",
            swiftSettings: [
                .define("GRDBCIPHER"),
                .define("SQLITE_ENABLE_FTS5"),
            ]
        ),
    ]
)
