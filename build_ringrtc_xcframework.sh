#!/bin/bash
set -euo pipefail

#=============================================================================
# build_ringrtc_xcframework.sh
# Собирает RingRTC (WebRTC.xcframework + libringrtc.a) для iOS
#
# Использование:
#   ./build_ringrtc_xcframework.sh [--version v2.56.0] [--output ./output]
#
# Требования:
#   - macOS с Xcode 15+
#   - Rust (устанавливается автоматически)
#   - cmake, protobuf (brew install cmake protobuf)
#   - depot_tools (Chromium build tools, ~200 МБ)
#   - ~20 ГБ свободного места (WebRTC sources)
#   - ~30-60 минут на первую сборку
#
# Результат:
#   output/
#   ├── SignalRingRTC.xcframework/     ← WebRTC + RingRTC в одном XCFramework
#   ├── SignalRingRTC.xcframework.zip  ← Архив для GitHub Releases
#   └── checksum.txt                  ← swift package compute-checksum
#
# ВНИМАНИЕ: Первая сборка занимает 30-60 минут и скачивает ~20 ГБ!
# Последующие пересборки значительно быстрее (инкрементальные).
#=============================================================================

VERSION="${1:-v2.56.0}"
OUTPUT_DIR="${2:-./output}"
DEPOT_TOOLS_DIR="${HOME}/depot_tools"

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()  { echo -e "${GREEN}[BUILD]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
err()  { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
step() { echo -e "\n${BLUE}━━━ Step $1 ━━━${NC}"; }

#=============================================================================
step "1/8: Проверка зависимостей"
#=============================================================================

[[ "$(uname)" == "Darwin" ]] || err "Этот скрипт работает только на macOS"
xcode-select -p &>/dev/null || err "Xcode не установлен"

# Rust
if ! command -v rustup &>/dev/null; then
    warn "Rust не найден. Устанавливаем..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
fi

# cmake
command -v cmake &>/dev/null || err "cmake не найден: brew install cmake"

# protoc
command -v protoc &>/dev/null || err "protoc не найден: brew install protobuf"

# Свободное место
AVAILABLE_GB=$(df -g . | tail -1 | awk '{print $4}')
if (( AVAILABLE_GB < 25 )); then
    warn "Доступно только ${AVAILABLE_GB} ГБ. Рекомендуется >= 25 ГБ для WebRTC."
    read -p "Продолжить? [y/N] " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] || exit 1
fi

log "Все базовые зависимости OK"

#=============================================================================
step "2/8: Установка depot_tools (Chromium build system)"
#=============================================================================

if [[ -d "${DEPOT_TOOLS_DIR}" ]]; then
    log "depot_tools уже установлены: ${DEPOT_TOOLS_DIR}"
    cd "${DEPOT_TOOLS_DIR}" && git pull --quiet && cd -
else
    log "Клонируем depot_tools..."
    git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git "${DEPOT_TOOLS_DIR}"
fi

export PATH="${DEPOT_TOOLS_DIR}:${PATH}"
log "depot_tools в PATH"

#=============================================================================
step "3/8: Клонирование RingRTC ${VERSION}"
#=============================================================================

RINGRTC_DIR="${HOME}/ringrtc-build"
mkdir -p "${RINGRTC_DIR}"
cd "${RINGRTC_DIR}"

if [[ -d "ringrtc/.git" ]]; then
    log "RingRTC уже клонирован, обновляем..."
    cd ringrtc
    git fetch --tags
    git checkout "${VERSION}"
else
    log "Клонируем signalapp/ringrtc (tag: ${VERSION})..."
    git clone https://github.com/signalapp/ringrtc.git
    cd ringrtc
    git checkout "${VERSION}"
fi

log "RingRTC ${VERSION} готов"

#=============================================================================
step "4/8: Настройка Rust toolchain"
#=============================================================================

# RingRTC использует свой rust-toolchain файл
log "Настраиваем Rust toolchain из rust-toolchain..."
rustup show active-toolchain

# Добавляем iOS targets
rustup target add aarch64-apple-ios x86_64-apple-ios aarch64-apple-ios-sim
rustup component add rust-src

# cbindgen
if ! command -v cbindgen &>/dev/null; then
    log "Устанавливаем cbindgen..."
    cargo install cbindgen
fi

log "Rust toolchain готов"

#=============================================================================
step "5/8: Загрузка WebRTC (ДОЛГИЙ ЭТАП ~20 ГБ)"
#=============================================================================

# RingRTC's Makefile handles WebRTC fetching
log "Загружаем WebRTC dependencies..."
log "⚠️  Это может занять 15-30 минут при первом запуске"

# Проверяем есть ли уже WebRTC
if [[ -d "src/webrtc/src" ]]; then
    log "WebRTC уже загружен, пропускаем (gclient sync при сборке)"
else
    log "Первая загрузка WebRTC..."
fi

#=============================================================================
step "6/8: Сборка RingRTC для iOS (ДОЛГИЙ ЭТАП ~30 минут)"
#=============================================================================

log "Запускаем сборку iOS..."
log "⚠️  Первая сборка: 30-60 минут. Последующие: 5-15 минут."
log "Архитектуры: arm64 (device), arm64+x86_64 (simulator)"

# RingRTC Makefile target для iOS
# Результат: out/WebRTC.xcframework + out/libringrtc/*/libringrtc.a
make ios

log "Сборка завершена!"

#=============================================================================
step "7/8: Сборка XCFramework"
#=============================================================================

mkdir -p "${OUTPUT_DIR}"

# Проверяем результаты сборки
WEBRTC_XCF="out/WebRTC.xcframework"
RINGRTC_H="out/libringrtc/ringrtc.h"
RINGRTC_DEVICE="out/libringrtc/aarch64-apple-ios/libringrtc.a"
RINGRTC_SIM_ARM="out/libringrtc/aarch64-apple-ios-sim/libringrtc.a"
RINGRTC_SIM_X86="out/libringrtc/x86_64-apple-ios/libringrtc.a"

for f in "${WEBRTC_XCF}" "${RINGRTC_H}" "${RINGRTC_DEVICE}"; do
    [[ -e "${f}" ]] || err "Не найден: ${f}"
done
log "Все артефакты на месте"

# Вариант 1: Создаём отдельный XCFramework для libringrtc
# (WebRTC.xcframework уже готов от make ios)

# Создаём fat binary для simulator
log "Создаём fat binary для симулятора..."
COMBINED_DIR="$(mktemp -d)"

if [[ -f "${RINGRTC_SIM_X86}" ]]; then
    lipo -create "${RINGRTC_SIM_ARM}" "${RINGRTC_SIM_X86}" \
        -output "${COMBINED_DIR}/libringrtc.a"
else
    # Если x86_64 не собран, используем только arm64 sim
    cp "${RINGRTC_SIM_ARM}" "${COMBINED_DIR}/libringrtc.a"
fi

# modulemap для libringrtc
cat > "${COMBINED_DIR}/module.modulemap" << 'MODULEMAP'
module RingRTC {
    header "ringrtc.h"
    export *
}
MODULEMAP

# Структура для xcodebuild
DEVICE_DIR="${COMBINED_DIR}/ios-arm64"
SIM_DIR="${COMBINED_DIR}/ios-arm64_x86_64-simulator"

mkdir -p "${DEVICE_DIR}/Headers" "${DEVICE_DIR}/Modules"
mkdir -p "${SIM_DIR}/Headers" "${SIM_DIR}/Modules"

cp "${RINGRTC_DEVICE}"          "${DEVICE_DIR}/libringrtc.a"
cp "${RINGRTC_H}"               "${DEVICE_DIR}/Headers/"
cp "${COMBINED_DIR}/module.modulemap" "${DEVICE_DIR}/Modules/"

cp "${COMBINED_DIR}/libringrtc.a"     "${SIM_DIR}/libringrtc.a"
cp "${RINGRTC_H}"               "${SIM_DIR}/Headers/"
cp "${COMBINED_DIR}/module.modulemap" "${SIM_DIR}/Modules/"

# Создаём LibRingRTC.xcframework
RINGRTC_XCF="${OUTPUT_DIR}/LibRingRTC.xcframework"
rm -rf "${RINGRTC_XCF}"
xcodebuild -create-xcframework \
    -library "${DEVICE_DIR}/libringrtc.a" \
    -headers "${DEVICE_DIR}/Headers" \
    -library "${SIM_DIR}/libringrtc.a" \
    -headers "${SIM_DIR}/Headers" \
    -output "${RINGRTC_XCF}"

# Копируем modulemap
for slice_dir in "${RINGRTC_XCF}"/*/; do
    if [[ -d "${slice_dir}/Headers" ]]; then
        mkdir -p "${slice_dir}/Modules"
        cp "${COMBINED_DIR}/module.modulemap" "${slice_dir}/Modules/"
    fi
done

# Копируем WebRTC.xcframework
cp -R "${WEBRTC_XCF}" "${OUTPUT_DIR}/WebRTC.xcframework"

# Копируем Swift-исходники
SWIFT_SOURCES="${OUTPUT_DIR}/swift-sources"
mkdir -p "${SWIFT_SOURCES}"
cp -r src/ios/SignalRingRTC/SignalRingRTC/ "${SWIFT_SOURCES}/"

rm -rf "${COMBINED_DIR}"

log "XCFrameworks созданы"

#=============================================================================
step "8/8: Архивирование и контрольные суммы"
#=============================================================================

cd "${OUTPUT_DIR}"

# Архивируем LibRingRTC
zip -r -y "LibRingRTC.xcframework.zip" "LibRingRTC.xcframework"
RINGRTC_CHECKSUM=$(swift package compute-checksum "LibRingRTC.xcframework.zip")
echo "LibRingRTC: ${RINGRTC_CHECKSUM}" >> checksum.txt

# Архивируем WebRTC
zip -r -y "WebRTC.xcframework.zip" "WebRTC.xcframework"
WEBRTC_CHECKSUM=$(swift package compute-checksum "WebRTC.xcframework.zip")
echo "WebRTC: ${WEBRTC_CHECKSUM}" >> checksum.txt

log "LibRingRTC.xcframework.zip: $(du -h "LibRingRTC.xcframework.zip" | cut -f1)"
log "WebRTC.xcframework.zip: $(du -h "WebRTC.xcframework.zip" | cut -f1)"

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN} ГОТОВО! RingRTC ${VERSION} XCFrameworks${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo ""
echo "Результаты:"
echo "  LibRingRTC:    ${OUTPUT_DIR}/LibRingRTC.xcframework"
echo "  WebRTC:        ${OUTPUT_DIR}/WebRTC.xcframework"
echo "  Swift sources: ${SWIFT_SOURCES}"
echo ""
echo "Checksums:"
echo "  LibRingRTC: ${RINGRTC_CHECKSUM}"
echo "  WebRTC:     ${WEBRTC_CHECKSUM}"
echo ""
echo "Загрузите ZIP-файлы в GitHub Release и используйте в Package.swift"
echo ""

