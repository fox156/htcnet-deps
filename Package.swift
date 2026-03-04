// swift-tools-version: 5.9
import PackageDescription

let githubBaseURL = "https://github.com/fox156/htcnet-deps/releases/download"

let libsignalVersion = "libsignal-v0.86.16i"
let signalFfiChecksum = "2f6ec0d95c7e78e29ca531086436c7d80629272329eb97e0505c8c48f8cb9cdb"

let ringrtcVersion = "ringrtc-v2.64.1"
let ringRTCChecksum = "775cf83d086aa15baaeb912d3b62483491036f6a695ca8dc8057606e8a2732c8"
let webRTCChecksum = "d6fcb8aec002f769b2987c0ac372a04d9a553b08f3fc61020dedf3acc68ffd4a"

let sqlcipherVersion = "sqlcipher-v4.6.1-fts5"
let sqlcipherChecksum = "00d76dd5d407a81521b9b1f536e3ce43fa9e3fcb505196589586ad0b61df15e5"

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
