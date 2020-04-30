FROM runtimeverificationinc/ubuntu:bionic

RUN    apt-get update        \
    && apt-get upgrade --yes \
    && apt-get install --yes \
        autoconf             \
        bison                \
        clang++-8            \
        clang-8              \
        cmake                \
        curl                 \
        flex                 \
        gcc                  \
        git                  \
        libboost-test-dev    \
        libgmp-dev           \
        libjemalloc-dev      \
        libmpfr-dev          \
        libprocps-dev        \
        libprotobuf-dev      \
        libsecp256k1-dev     \
        libtool              \
        libyaml-dev          \
        libz3-dev            \
        lld-8                \
        llvm-8               \
        llvm-8-tools         \
        make                 \
        maven                \
        openjdk-11-jdk       \
        pandoc               \
        pkg-config           \
        protobuf-compiler    \
        python3              \
        z3                   \
        zlib1g-dev

ADD deps/k/haskell-backend/src/main/native/haskell-backend/scripts/install-stack.sh /.install-stack/
RUN /.install-stack/install-stack.sh

USER user:user

ADD --chown=user:user deps/k/haskell-backend/src/main/native/haskell-backend/stack.yaml /home/user/.tmp-haskell/
ADD --chown=user:user deps/k/haskell-backend/src/main/native/haskell-backend/kore/package.yaml /home/user/.tmp-haskell/kore/
RUN    cd /home/user/.tmp-haskell  \
    && stack build --only-snapshot

RUN    git config --global user.email "admin@runtimeverification.com" \
    && git config --global user.name  "RV Jenkins"                    \
    && mkdir -p ~/.ssh                                                \
    && echo 'host github.com'                       > ~/.ssh/config   \
    && echo '    hostname github.com'              >> ~/.ssh/config   \
    && echo '    user git'                         >> ~/.ssh/config   \
    && echo '    identityagent SSH_AUTH_SOCK'      >> ~/.ssh/config   \
    && echo '    stricthostkeychecking accept-new' >> ~/.ssh/config   \
    && chmod go-rwx -R ~/.ssh
