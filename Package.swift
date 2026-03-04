// swift-tools-version: 5.9
import PackageDescription

let githubBaseURL = "https://github.com/fox156/htcnet-deps/releases/download"

let libsignalVersion = "libsignal-v0.86.16"
let signalFfiChecksum = "79881d9613e5536c7b9d7fece032bc5d8542eb5d3c4cebf6d232ee285a18fbba"

let ringrtcVersion = "ringrtc-v2.64.1"
let ringRTCChecksum = "775cf83d086aa15baaeb912d3b62483491036f6a695ca8dc8057606e8a2732c8"
let webRTCChecksum = "d6fcb8aec002f769b2987c0ac372a04d9a553b08f3fc61020dedf3acc68ffd4a"

let sqlcipherVersion = "sqlcipher-v4.6.1"
let sqlcipherChecksum = "432d65f72a82544038087e7d7df5b3db215925a0d3eb5c72befed99e2fab3267"

let package = Package(
    name: "HTCNetDeps",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "LibSignalClient", targets: ["LibSignalClient"]),
        .library(name: "SignalRingRTC", targets: ["SignalRingRTC"]),
        .library(name: "GRDB", targets: ["GRDB"]),
    ],
    targets: [
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
