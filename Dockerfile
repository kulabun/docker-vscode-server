FROM gitpod/openvscode-server:latest

### Versions ###
ENV NODE_VERSION=lts
ENV GO_VERSION=1.17.1

### Prerequisites ###
# Switch to root user to make installs and add openvscode-server to sudo group
USER root
RUN apt-get update
# Install necessary tools (sorted alphabetically) (ripgrep doesn't work)
RUN apt-get install \
    apt-transport-https \ 
    apt-utils \
    bash-completion \
    build-essential \
    ca-certificates \
    curl \
    fish \
    htop \
    jq \
    less \
    locales \
    lsof \
    man-db \
    ssl-cert \
    sudo \
    time \
    unzip \
    vim \
    zip \
    software-properties-common \
    -y
# Generate and set locale to en_US.UTF-8
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
# Add openvscode-server to sudoers file
RUN echo "openvscode-server  ALL=(ALL) NOPASSWD:ALL"  >> /etc/sudoers
# Switch back to openvscode-server for setup
USER openvscode-server
# Test sudo capability of openvscode-server
RUN sudo echo "openvscode-server running sudo"

### C / C++ ###
# Add LLVM GPG key and repository to apt (clangd doesn't work)
RUN curl -sL https://apt.llvm.org/llvm-snapshot.gpg.key | sudo apt-key add \
    && sudo bash -c 'echo "deb https://apt.llvm.org/focal/ llvm-toolchain-focal main" >> /etc/apt/sources.list.d/llvm.list' \
    && sudo apt-get install \
    clang \
    clang-format \
    clang-tidy  \
    g++ \
    gcc \
    gdb \
    lld \
    make -y

### Node.js ###
# Run Node.js setup script
RUN curl -sL https://deb.nodesource.com/setup_$NODE_VERSION.x | sudo bash \
    && sudo apt-get install nodejs -y \
    && sudo npm install -g typescript yarn node-gyp

### Go ###
RUN curl -sL https://storage.googleapis.com/golang/go$GO_VERSION.linux-amd64.tar.gz | sudo tar -C /usr/local -xvz
ENV PATH=/usr/local/go/bin:${PATH}

### Rust ###
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y

### Docker ###
# Add vfs storage-driver config to daemon.json
RUN sudo mkdir /etc/docker && echo '{"storage-driver": "vfs"}' | sudo tee /etc/docker/daemon.json \
    && curl -sL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add \
    && sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable" \
    && sudo apt-get install docker-ce docker-ce-cli containerd.io -y \
    && sudo usermod -aG docker openvscode-server

RUN echo "PATH="${PATH}"" | sudo tee /etc/environment

ENTRYPOINT sudo service docker start && ${OPENVSCODE_SERVER_ROOT}/server.sh
