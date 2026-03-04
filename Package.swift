// swift-tools-version: 5.9
import PackageDescription

let githubBaseURL = "https://github.com/fox156/htcnet-deps/releases/download"

let libsignalVersion = "libsignal-v0.86.16"
let signalFfiChecksum = "8b5c8482a18e1441ac646a40e390a7add76a1fa1684caa6d8af3d164f27138cc"

let ringrtcVersion = "ringrtc-v2.64.1"
let ringRTCChecksum = "0485f7d136ae9c3a6db85b1d7ede38bea9d1d76f2819801892ec2c6e388f8946"
let webRTCChecksum = "d6fcb8aec002f769b2987c0ac372a04d9a553b08f3fc61020dedf3acc68ffd4a"

let sqlcipherVersion = "sqlcipher-v4.6.1"
let sqlcipherChecksum = "0d370c6bf761d767a9fc9f24949d747923abef4f7d7d5fd2333f1638897bf1ac"

let package = Package(
    name: "HTCNetDeps",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "LibSignalClient", targets: ["LibSignalClient"]),
        .library(name: "SignalRingRTC", targets: ["SignalRingRTC"]),
        .library(name: "GRDB", targets: ["GRDB"]),
    ],
    targets: [
        // Binary targets
        .binaryTarget(
            name: "SignalFfi",
            url: "\(githubBaseURL)/\(libsignalVersion)/LibSignalFFI.xcframework.zip",
            checksum: signalFfiChecksum
        ),
        .binaryTarget(
            name: "RingRTC",
            url: "\(githubBaseURL)/\(ringrtcVersion)/LibRingRTC.xcframework.zip",
            checksum: ringRTCChecksum
        ),
        .binaryTarget(
            name: "WebRTC",
            url: "\(githubBaseURL)/\(ringrtcVersion)/WebRTC.xcframework.zip",
            checksum: webRTCChecksum
        ),
        .binaryTarget(
            name: "GRDBSQLCipher",
            url: "\(githubBaseURL)/\(sqlcipherVersion)/SQLCipher.xcframework.zip",
            checksum: sqlcipherChecksum
        ),

        // Swift wrappers
        .target(
            name: "LibSignalClient",
            dependencies: ["SignalFfi"],
            path: "Sources/LibSignalClient",
            swiftSettings: [
                .define("SIGNAL_MEDIA_SUPPORTED", .when(platforms: [.iOS])),
            ]
        ),
        .target(
            name: "SignalRingRTC",
            dependencies: ["RingRTC", "WebRTC"],
            path: "Sources/SignalRingRTC"
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
