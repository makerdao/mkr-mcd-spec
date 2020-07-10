ARG K_COMMIT
FROM runtimeverificationinc/kframework-k:ubuntu-bionic-${K_COMMIT}

RUN    apt-get update        \
    && apt-get upgrade --yes \
    && apt-get install --yes \
        cmake                \
        curl                 \
        libprocps-dev        \
        jq                   \
        pandoc               \
        pkg-config           \
        python3              \
        sudo

ARG USER_ID=1000
ARG GROUP_ID=1000
RUN    groupadd -g $GROUP_ID user                             \
    && useradd -m -u $USER_ID -s /bin/sh -g user -G sudo user \
    && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER user:user
ENV USER=user
WORKDIR /home/user

RUN curl -L https://nixos.org/nix/install | sh
RUN curl -L https://dapp.tools/install    | bash
ENV PATH="$PATH:/home/user/.nix-profile/bin"

RUN    git config --global user.email "admin@runtimeverification.com" \
    && git config --global user.name  "RV Jenkins"                    \
    && mkdir -p ~/.ssh                                                \
    && echo 'host github.com'                       > ~/.ssh/config   \
    && echo '    hostname github.com'              >> ~/.ssh/config   \
    && echo '    user git'                         >> ~/.ssh/config   \
    && echo '    identityagent SSH_AUTH_SOCK'      >> ~/.ssh/config   \
    && echo '    stricthostkeychecking accept-new' >> ~/.ssh/config   \
    && chmod go-rwx -R ~/.ssh
