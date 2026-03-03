// swift-tools-version: 5.9
// ============================================================================
// HTCNet Dependencies Package
// ============================================================================
//
// Этот пакет объединяет все бинарные зависимости HTCNet в одном SPM-пакете:
//
//   1. LibSignalFFI     — Rust FFI слой libsignal (бинарный XCFramework)
//   2. LibSignalClient  — Swift-обёртка над LibSignalFFI
//   3. LibRingRTC       — Rust/C++ FFI слой RingRTC (бинарный XCFramework)
//   4. WebRTC           — WebRTC framework от Google/Signal (бинарный XCFramework)
//   5. SignalRingRTC    — Swift-обёртка над LibRingRTC + WebRTC
//
// Репозиторий: https://github.com/fox156/htcnet-deps
//
// Структура:
//   htcnet-deps/
//   ├── Package.swift           ← этот файл
//   ├── Sources/
//   │   ├── LibSignalClient/    ← Swift-исходники из libsignal/swift/Sources/LibSignalClient/
//   │   └── SignalRingRTC/      ← Swift-исходники из ringrtc/src/ios/SignalRingRTC/
//   └── (XCFrameworks скачиваются из GitHub Releases как binary targets)
// ============================================================================

import PackageDescription

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ВЕРСИИ И CHECKSUMS
// Обновляйте при пересборке XCFrameworks
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

let githubBaseURL = "https://github.com/fox156/htcnet-deps/releases/download"

// libsignal v0.78.0
let libsignalVersion = "libsignal-v0.86.16"
let libsignalFFIChecksum = "c77deee591fb7433613ecbcdaa5c31e40fd166c1e0f02cecc29f083706b93592"

// RingRTC v2.56.0
let ringrtcVersion = "v2.56.0"
let libRingRTCChecksum = "<CHECKSUM_AFTER_BUILD>"
let webRTCChecksum = "<CHECKSUM_AFTER_BUILD>"

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

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

        // Rust FFI layer для libsignal (libsignal_ffi.a)
        .binaryTarget(
            name: "LibSignalFFI",
            url: "\(githubBaseURL)/\(libsignalVersion)/LibSignalFFI.xcframework.zip",
            checksum: libsignalFFIChecksum
        ),

        // Rust/C++ FFI layer для RingRTC (libringrtc.a)
        .binaryTarget(
            name: "LibRingRTC",
            url: "\(githubBaseURL)/\(ringrtcVersion)/LibRingRTC.xcframework.zip",
            checksum: libRingRTCChecksum
        ),

        // WebRTC framework (от Google через Signal)
        .binaryTarget(
            name: "WebRTC",
            url: "\(githubBaseURL)/\(ringrtcVersion)/WebRTC.xcframework.zip",
            checksum: webRTCChecksum
        ),

        // ══════════════════════════════════════════════════════════════
        // SWIFT WRAPPER TARGETS
        // ══════════════════════════════════════════════════════════════

        // Swift-обёртка Signal Protocol
        // Исходники: libsignal/swift/Sources/LibSignalClient/
        .target(
            name: "LibSignalClient",
            dependencies: ["LibSignalFFI"],
            path: "Sources/LibSignalClient",
            swiftSettings: [
                .define("SIGNAL_MEDIA_SUPPORTED", .when(platforms: [.iOS])),
            ]
        ),

        // Swift-обёртка RingRTC (видео/аудио звонки)
        // Исходники: ringrtc/src/ios/SignalRingRTC/SignalRingRTC/
        .target(
            name: "SignalRingRTC",
            dependencies: ["LibRingRTC", "WebRTC"],
            path: "Sources/SignalRingRTC"
        ),
    ]
)
