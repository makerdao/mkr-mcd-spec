FROM runtimeverificationinc/ubuntu:bionic

RUN    apt-get update                                                              \
    && apt-get upgrade --yes                                                       \
    && apt-get install --yes                                                       \
        autoconf bison clang++-8 clang-8 cmake curl flex gcc git libboost-test-dev \
        libgmp-dev libjemalloc-dev libmpfr-dev libprocps-dev libprotobuf-dev       \
        libsecp256k1-dev libtool libyaml-dev libz3-dev lld-8 llvm-8 llvm-8-tools   \
        make maven opam openjdk-11-jdk pandoc pkg-config protobuf-compiler python3 \
        python3-pygments python3-recommonmark python3-setuptools python3-sphinx    \
        python3-sphinx-rtd-theme z3 zlib1g-dev

ADD deps/k/haskell-backend/src/main/native/haskell-backend/scripts/install-stack.sh /.install-stack/
RUN /.install-stack/install-stack.sh

USER user:user

ADD deps/k/k-distribution/src/main/scripts/bin/k-configure-opam-dev deps/k/k-distribution/src/main/scripts/bin/k-configure-opam-common /home/user/.tmp-opam/bin/
ADD deps/k/k-distribution/src/main/scripts/lib/opam  /home/user/.tmp-opam/lib/opam/
RUN    cd /home/user                        \
    && ./.tmp-opam/bin/k-configure-opam-dev

ADD --chown=user:user deps/k/haskell-backend/src/main/native/haskell-backend/stack.yaml /home/user/.tmp-haskell/
ADD --chown=user:user deps/k/haskell-backend/src/main/native/haskell-backend/kore/package.yaml /home/user/.tmp-haskell/kore/
RUN    cd /home/user/.tmp-haskell  \
    && stack build --only-snapshot
