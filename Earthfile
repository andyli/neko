build-env:
    FROM ubuntu:xenial
    RUN apt-get update \
        && apt-get install -y --no-install-recommends \
            software-properties-common \
            curl \
            build-essential \
            git \
            ninja-build \
            pkg-config \
            libgtk2.0-dev \
        #
        # Clean up
        && apt-get autoremove -y \
        && apt-get clean -y \
        && rm -rf /var/lib/apt/lists/*
    # install a recent CMake
    ARG TARGETARCH
    RUN case $TARGETARCH in \
            amd64) curl -fsSL https://github.com/Kitware/CMake/releases/download/v3.21.4/cmake-3.21.4-linux-x86_64.sh -o cmake-install.sh;; \
            arm64) curl -fsSL https://github.com/Kitware/CMake/releases/download/v3.21.4/cmake-3.21.4-linux-aarch64.sh -o cmake-install.sh;; \
        esac \
        && sh cmake-install.sh --skip-license --prefix /usr/local \
        && rm cmake-install.sh

build-all-platforms:
    BUILD --platform=linux/amd64 --platform=linux/arm64 +build

build:
    FROM +build-env
    WORKDIR /src
    COPY . .
    WORKDIR /src/build
    RUN cmake .. -DSTATIC_DEPS=all -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo
    RUN ninja download_static_deps
    RUN ninja
    RUN ninja test
    RUN ninja package
    ARG TARGETOS
    ARG TARGETARCH
    RUN mv bin/neko-*.tar.gz "bin/neko-$(cmake -L -N -B . | awk -F '=' '/NEKO_VERSION/ {print $2}')-${TARGETOS}-${TARGETARCH}.tar.gz"
    SAVE ARTIFACT bin/neko-*.tar.gz AS LOCAL ./build/
