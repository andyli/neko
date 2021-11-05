FROM mcr.microsoft.com/vscode/devcontainers/base:0-focal
ARG DEVCONTAINER_IMAGE_NAME=haxe/neko_devcontainer

devcontainer:
    BUILD +devcontainer-build
    BUILD +update-devcontainer-refs

devcontainer-build:
    # Avoid warnings by switching to noninteractive
    ENV DEBIAN_FRONTEND=noninteractive

    ARG INSTALL_ZSH="false"
    ARG UPGRADE_PACKAGES="false"
    ARG ENABLE_NONROOT_DOCKER="true"
    ARG USE_MOBY="true"
    ENV DOCKER_BUILDKIT=1
    ARG USERNAME=automatic
    ARG USER_UID=1000
    ARG USER_GID=$USER_UID
    COPY .devcontainer/library-scripts/*.sh /tmp/library-scripts/
    RUN apt-get update \
        && /bin/bash /tmp/library-scripts/common-debian.sh "${INSTALL_ZSH}" "${USERNAME}" "${USER_UID}" "${USER_GID}" "${UPGRADE_PACKAGES}" "true" "true" \
        # Use Docker script from script library to set things up
        && /bin/bash /tmp/library-scripts/docker-debian.sh "${ENABLE_NONROOT_DOCKER}" "/var/run/docker-host.sock" "/var/run/docker.sock" "${USERNAME}" "${USE_MOBY}" \
        # Clean up
        && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/* /tmp/library-scripts/

    # Setting the ENTRYPOINT to docker-init.sh will configure non-root access 
    # to the Docker socket. The script will also execute CMD as needed.
    ENTRYPOINT [ "/usr/local/share/docker-init.sh" ]
    CMD [ "sleep", "infinity" ]

    # Configure apt and install packages
    RUN apt-get update \
        && apt-get install -y --no-install-recommends apt-utils dialog 2>&1 \
        && apt-get install -y \
            iproute2 \
            procps \
            sudo \
            bash-completion \
            build-essential \
            curl \
            wget \
            software-properties-common \
            direnv \
            tzdata \
            # Neko deps
            cmake \
            ninja-build \
            pkg-config \
            libgtk2.0-dev \
            # Neko dynamic link deps
            libgc-dev \
            libpcre3-dev \
            zlib1g-dev \
            apache2-dev \
            libmysqlclient-dev \
            libsqlite3-dev \
            libmbedtls-dev \
        && echo 'eval "$(direnv hook bash)"' >> /etc/bash.bashrc \
        # install the latest git
        && add-apt-repository ppa:git-core/ppa \
        && apt-get install -y git \
        #
        # Clean up
        && apt-get autoremove -y \
        && apt-get clean -y \
        && rm -rf /var/lib/apt/lists/*

    ARG TARGETARCH
    RUN wget https://github.com/earthly/earthly/releases/download/v0.5.24/earthly-linux-${TARGETARCH} -O /usr/local/bin/earthly \
        && chmod +x /usr/local/bin/earthly
    RUN earthly bootstrap --no-buildkit --with-autocomplete

    # Switch back to dialog for any ad-hoc use of apt-get
    ENV DEBIAN_FRONTEND=

    ARG EARTHLY_GIT_SHORT_HASH
    SAVE IMAGE --push $DEVCONTAINER_IMAGE_NAME:$EARTHLY_GIT_SHORT_HASH

update-devcontainer-refs:
    BUILD --build-arg FILE=./.devcontainer/docker-compose.yml +update-devcontainer-ref

update-devcontainer-ref:
    WORKDIR /tmp
    ARG FILE
    COPY $FILE file.o
    ARG EARTHLY_GIT_SHORT_HASH
    RUN sed -e "s#$DEVCONTAINER_IMAGE_NAME:[a-z0-9]*#$DEVCONTAINER_IMAGE_NAME:$EARTHLY_GIT_SHORT_HASH#g" file.o > file
    SAVE ARTIFACT file AS LOCAL $FILE

devcontainer-all-platforms:
    BUILD --platform=linux/amd64 --platform=linux/arm64 +devcontainer-build
    BUILD +update-devcontainer-refs

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

package:
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

package-all-platforms:
    BUILD --platform=linux/amd64 --platform=linux/arm64 +package
