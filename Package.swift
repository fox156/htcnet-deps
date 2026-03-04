// swift-tools-version: 5.9
// ============================================================================
// HTCNet Dependencies Package
// ============================================================================
//
// Зависимости:
//   1. LibSignalFFI     — Rust FFI слой libsignal (XCFramework)
//   2. LibSignalClient  — Swift-обёртка над LibSignalFFI
//   3. LibRingRTC       — Rust/C++ FFI слой RingRTC (XCFramework)
//   4. WebRTC           — WebRTC framework (XCFramework)
//   5. SignalRingRTC    — Swift-обёртка над LibRingRTC + WebRTC
//
// Репозиторий: https://github.com/fox156/htcnet-deps
// ============================================================================

import PackageDescription

let githubBaseURL = "https://github.com/fox156/htcnet-deps/releases/download"

// libsignal v0.86.16
let libsignalVersion = "libsignal-v0.86.16"
let libsignalFFIChecksum = "ddaab4252a9b5f37e0ed9359173f922fd64a36ef8ba0213965278dc987f16a67"

// RingRTC v2.64.1
let ringrtcVersion = "ringrtc-v2.64.1"
let libRingRTCChecksum = "0485f7d136ae9c3a6db85b1d7ede38bea9d1d76f2819801892ec2c6e388f8946"
let webRTCChecksum = "d6fcb8aec002f769b2987c0ac372a04d9a553b08f3fc61020dedf3acc68ffd4a"

let package = Package(
    name: "HTCNetDeps",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        // Фаза 2: E2E-шифрование
        .library(
            name: "LibSignalClient",
            targets: ["LibSignalClient"]
        ),
        // Фаза 3: Звонки
        .library(
            name: "SignalRingRTC",
            targets: ["SignalRingRTC"]
        ),
    ],
    targets: [
        // ══════════════════════════════════════════════════════════════
        // BINARY TARGETS (pre-built XCFrameworks)
        // ══════════════════════════════════════════════════════════════

        .binaryTarget(
            name: "SignalFfi",
            url: "\(githubBaseURL)/\(libsignalVersion)/LibSignalFFI.xcframework.zip",
            checksum: libsignalFFIChecksum
        ),
        .binaryTarget(
            name: "RingRTC",
            url: "\(githubBaseURL)/\(ringrtcVersion)/LibRingRTC.xcframework.zip",
            checksum: libRingRTCChecksum
        ),
        .binaryTarget(
            name: "WebRTC",
            url: "\(githubBaseURL)/\(ringrtcVersion)/WebRTC.xcframework.zip",
            checksum: webRTCChecksum
        ),

        // ══════════════════════════════════════════════════════════════
        // SWIFT WRAPPER TARGETS
        // ══════════════════════════════════════════════════════════════

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
    ]
)
