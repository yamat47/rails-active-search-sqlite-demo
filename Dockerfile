# Local development image. CI runs natively on GitHub's runners, so this only has to
# serve the `make` targets: Ruby for the app, Node for the Vite PWA in pwa/, and the
# ruby.wasm toolchain for `wasmify:pack`.

ARG RUBY_VERSION=4.0.7
ARG NODE_VERSION=24.21.0

FROM node:${NODE_VERSION}-trixie-slim AS node

FROM ruby:${RUBY_VERSION}-slim

ARG WASI_SDK_VERSION=34
ARG BINARYEN_VERSION=133
ARG WASI_VFS_VERSION=0.6.3
ARG WASMTIME_VERSION=49.0.2
# amd64 or arm64, filled in by BuildKit from the platform being built for.
ARG TARGETARCH

# build-essential also brings make and patch, which ruby.wasm needs to cross-compile CRuby.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      build-essential ca-certificates curl git libyaml-dev pkg-config unzip xz-utils \
 && rm -rf /var/lib/apt/lists/*

# Node is copied from the official image (same Debian release) rather than installed from
# NodeSource: one pinned version, identical on amd64 and arm64, no third-party apt source.
COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -s ../lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
 && ln -s ../lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx \
 && ln -s ../lib/node_modules/corepack/dist/corepack.js /usr/local/bin/corepack

# ruby_wasm downloads wasi-sdk and binaryen by itself only on x86_64-linux and macOS;
# elsewhere it expects WASI_SDK_PATH and wasm-opt on PATH, so both are preinstalled for
# every arch. wasi-vfs is needed by wasmify:pack, wasmtime by wasmify:pack:core:verify.
# Only binaryen publishes checksums; the others are trusted over HTTPS.
RUN set -eux; \
    case "${TARGETARCH}" in \
      amd64) gnu_arch=x86_64;  wasi_sdk_arch=x86_64 ;; \
      arm64) gnu_arch=aarch64; wasi_sdk_arch=arm64 ;; \
      *) echo "unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    # A connection that stalls would otherwise hang the build forever: below 1 KB/s for a
    # minute curl gives up, and --retry starts the download again.
    fetch() { curl -fsSL --retry 3 --speed-limit 1024 --speed-time 60 "$@"; }; \
    tmp="$(mktemp -d)"; cd "${tmp}"; \
    \
    wasi_sdk="wasi-sdk-${WASI_SDK_VERSION}.0-${wasi_sdk_arch}-linux.tar.gz"; \
    fetch -O "https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-${WASI_SDK_VERSION}/${wasi_sdk}"; \
    mkdir /opt/wasi-sdk; \
    tar -xzf "${wasi_sdk}" -C /opt/wasi-sdk --strip-components=1; \
    \
    binaryen="binaryen-version_${BINARYEN_VERSION}-${gnu_arch}-linux.tar.gz"; \
    fetch -O "https://github.com/WebAssembly/binaryen/releases/download/version_${BINARYEN_VERSION}/${binaryen}"; \
    fetch -O "https://github.com/WebAssembly/binaryen/releases/download/version_${BINARYEN_VERSION}/${binaryen}.sha256"; \
    sha256sum -c "${binaryen}.sha256"; \
    mkdir /opt/binaryen; \
    tar -xzf "${binaryen}" -C /opt/binaryen --strip-components=1; \
    # The static library and headers are for embedding binaryen, not for running wasm-opt.
    rm -rf /opt/binaryen/include /opt/binaryen/lib; \
    \
    wasi_vfs="wasi-vfs-cli-${gnu_arch}-unknown-linux-gnu.zip"; \
    fetch -O "https://github.com/kateinoigakukun/wasi-vfs/releases/download/v${WASI_VFS_VERSION}/${wasi_vfs}"; \
    unzip -q "${wasi_vfs}" wasi-vfs -d /usr/local/bin; \
    chmod +x /usr/local/bin/wasi-vfs; \
    \
    wasmtime="wasmtime-v${WASMTIME_VERSION}-${gnu_arch}-linux"; \
    fetch "https://github.com/bytecodealliance/wasmtime/releases/download/v${WASMTIME_VERSION}/${wasmtime}.tar.xz" \
      | tar -xJf - -C /usr/local/bin --strip-components=1 "${wasmtime}/wasmtime"; \
    \
    cd /; rm -rf "${tmp}"

ENV WASI_SDK_PATH=/opt/wasi-sdk \
    PATH=/opt/binaryen/bin:${PATH}

WORKDIR /app

# Gems live in the image, not under the bind-mounted /app, so Linux-built extensions never
# land in the host checkout. BUNDLE_WITHOUT is cleared so the wasm group is installed too.
ENV BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT=""

COPY Gemfile Gemfile.lock ./
RUN bundle install \
 && rm -rf "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git
