ARG K_COMMIT
FROM runtimeverificationinc/kframework-k:ubuntu-bionic-${K_COMMIT}

RUN    apt-get update        \
    && apt-get upgrade --yes \
    && apt-get install --yes \
        cmake                \
        curl                 \
        libprocps-dev        \
        pandoc               \
        pkg-config           \
        python3

RUN    addgroup --system nixbld                                                       \
    && adduser --home /home/nix --disabled-password --gecos "" --shell /bin/bash nix  \
    && adduser nix nixbld                                                             \
    && mkdir -m 0755 /nix                                                             \
    && chown nix /nix                                                                 \
    && mkdir -p /etc/nix                                                              \
    && echo 'sandbox = false' > /etc/nix/nix.conf
USER nix
ENV USER=nix
WORKDIR /home/nix
RUN touch .bash_profile && curl https://nixos.org/nix/install | sh --daemon

USER root
ENV user=root
ARG USER_ID=1000
ARG GROUP_ID=1000
RUN groupadd -g $GROUP_ID user && useradd -m -u $USER_ID -s /bin/sh -g user -G user

USER user:user
WORKDIR /home/user
ENV user=user

RUN    git config --global user.email "admin@runtimeverification.com" \
    && git config --global user.name  "RV Jenkins"                    \
    && mkdir -p ~/.ssh                                                \
    && echo 'host github.com'                       > ~/.ssh/config   \
    && echo '    hostname github.com'              >> ~/.ssh/config   \
    && echo '    user git'                         >> ~/.ssh/config   \
    && echo '    identityagent SSH_AUTH_SOCK'      >> ~/.ssh/config   \
    && echo '    stricthostkeychecking accept-new' >> ~/.ssh/config   \
    && chmod go-rwx -R ~/.ssh

RUN curl https://dapp.tools/install | sh
ENV PATH="$PATH:$HOME/.nix-profile/bin"
