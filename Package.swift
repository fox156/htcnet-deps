// swift-tools-version: 5.9
import PackageDescription

let githubBaseURL = "https://github.com/fox156/htcnet-deps/releases/download"

let libsignalVersion = "libsignal-v0.86.16i"
let signalFfiChecksum = "2f6ec0d95c7e78e29ca531086436c7d80629272329eb97e0505c8c48f8cb9cdb"

let sqlcipherVersion = "sqlcipher-v4.6.1-fts5b"
let sqlcipherChecksum = "b9463fa3ba3a680b8b29dbff6ad870ca003520f1160e8759c29df60a2218fc46"

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
