build:
    FROM ubuntu:xenial
    RUN apt-get update \
        && apt-get install -y --no-install-recommends \
            software-properties-common \
            build-essential \
            curl \
            git \
            # Neko deps
            cmake \
            ninja-build \
            pkg-config \
            libgtk2.0-dev \
        #
        # Clean up
        && apt-get autoremove -y \
        && apt-get clean -y \
        && rm -rf /var/lib/apt/lists/*
    WORKDIR /src
    COPY . .
    WORKDIR /src/build
    RUN cmake .. -DSTATIC_DEPS=all -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo
    RUN ninja download_static_deps
    RUN ninja
    RUN ninja test
    RUN ninja package
    SAVE ARTIFACT bin/neko-*.tar.gz AS LOCAL ./
