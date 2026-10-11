# Default to latest Ubuntu LTS.
# (See https://hub.docker.com/r/microsoft/devcontainers-base)
ARG VARIANT="ubuntu"
ARG PLATFORM="linux/amd64"
FROM --platform=${PLATFORM} mcr.microsoft.com/devcontainers/base:${VARIANT}

# From https://github.com/chipsalliance/verible/releases
ARG VERIBLE_VERSION="v0.0-4007-g98bdb38a"

# From https://github.com/verilator/verilator/releases
ARG VERILATOR_VERSION="v5.044"

# From https://github.com/steveicarus/iverilog/releases
ARG IVERILOG_VERSION="v12_0"

# From https://github.com/libsidplayfp/libresidfp/releases
ARG LIBRESIDFP_VERSION="1.2.3"
ARG LIBRESIDFP_SHA256="e9b53a984ca708c3e8d9139eb6aad6141f73ffc22d70a020f7966803f4e2f76d"

# Efinity software requires a free license from Efinix. Please do the right thing.
# From https://www.efinixinc.com/support/
ARG EFINITY_MAJOR_MINOR="2025.2"
ARG EFINITY_PATCH="288.2.10"

# From https://apt.kitware.com/
# Pin to 3.x: IceSID's CMakeLists.txt still requires compatibility with CMake 3.0,
# which CMake 4.x removed.
ARG CMAKE_VERSION="3.*"

# Cache large downloads:

# Download Efinity software -- Requires a free license from Efinix. Please do the right thing.
#
#   1. Create an account on the Efinix website.
#   2. Log in to your account.
#   3. Navigate to the Efinity page to request your free license.
#      (See: https://www.efinixinc.com/support/)
#
ARG EFINITY_ARCHIVE="efinity-${EFINITY_MAJOR_MINOR}.${EFINITY_PATCH}-linux-x64.tar.bz2"
RUN wget https://www.efinixinc.com/dl/${EFINITY_ARCHIVE} -P /tmp

# Clone Verilator (built from source)
RUN cd /tmp && \
    git clone --branch ${VERILATOR_VERSION} --depth 1 --single-branch https://github.com/verilator/verilator.git

# Clone Icarus Verilog (built from source)
RUN cd /tmp && \
    git clone --branch ${IVERILOG_VERSION} --depth 1 --single-branch https://github.com/steveicarus/iverilog.git

ARG VERIBLE_ARCHIVE="verible-${VERIBLE_VERSION}-linux-static-x86_64.tar.gz"
RUN wget https://github.com/chipsalliance/verible/releases/download/${VERIBLE_VERSION}/${VERIBLE_ARCHIVE} -P /tmp

# Dependencies for native C/C++ simulation and table generation, Verilator and
# Icarus/reSIDfp source builds, HDL editing, and waveform inspection.
# NumPy/SciPy provide audio metrics, FFTs, and resampling; Matplotlib provides
# diagnostic plots. Yosys is retained for portable synthesis/equivalence work.
# Minicom is retained for FPGA UART diagnostics.
# libgl1, libegl1, and libxkbcommon0 are Efinity GUI dependencies.

# Use unattended mode for 'apt'
ARG DEBIAN_FRONTEND="noninteractive"

# Install Kitware APT repository so CMake is newer than Ubuntu default.
RUN apt-get update && apt-get -y install --no-install-recommends \
    ca-certificates \
    gpg \
    wget && \
    wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | \
    gpg --dearmor - | tee /usr/share/keyrings/kitware-archive-keyring.gpg >/dev/null && \
    . /etc/os-release && \
    echo "deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ ${UBUNTU_CODENAME} main" \
    | tee /etc/apt/sources.list.d/kitware.list >/dev/null && \
    apt-get update && \
    apt-get -y install --no-install-recommends kitware-archive-keyring

RUN apt-get update && apt-get -y install --no-install-recommends \
    autoconf \
    autoconf-archive \
    automake \
    bison \
    build-essential \
    ca-certificates \
    clang-format \
    cmake=${CMAKE_VERSION} \
    cmake-data=${CMAKE_VERSION} \
    flex \
    gperf \
    gtkwave \
    help2man \
    libegl1 \
    libfl-dev \
    libgl1 \
    libtool \
    libxkbcommon0 \
    minicom \
    ninja-build \
    pkg-config \
    python3 \
    python3-matplotlib \
    python3-numpy \
    python3-pip \
    python3-scipy \
    python3-venv \
    universal-ctags \
    yosys

# Fail build if CMake is not installed correctly.
RUN cmake --version

# Clean apt cache and temporary files
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/*

#
# Build and install the tools
#

# Install Verilator (built from source)
# (Do this early as it takes a while).
RUN cd /tmp/verilator && \
    autoconf && \
    ./configure && \
    make -j$(nproc) && \
    make install && \
    cd /tmp && \
    rm -rf verilator

# Install Icarus Verilog (built from source)
# (Do this early as it takes a while).
RUN cd /tmp/iverilog && \
    sh autoconf.sh && \
    sh configure && \
    make -j$(nproc) && \
    make install && \
    cd /tmp && \
    rm -rf iverilog

# Install Efinity -- Requires a free license from Efinix. Please do the right thing.
# (See: https://www.efinixinc.com/support/)
RUN tar -xjvf /tmp/${EFINITY_ARCHIVE} -C /opt && \
    rm -rf /tmp/${EFINITY_ARCHIVE} && \
    chmod +x /opt/efinity/${EFINITY_MAJOR_MINOR}/bin/setup.sh
ENV EFINITY_HOME="/opt/efinity/${EFINITY_MAJOR_MINOR}"

# Install Verible (download from chipsalliance)
RUN mkdir -p /opt/verible && \
    tar -x -f /tmp/${VERIBLE_ARCHIVE} -C /opt/verible --strip-components 1 && \
    rm -rf /tmp/${VERIBLE_ARCHIVE}
ENV PATH="/opt/verible/bin:${PATH}"

# Install uv for Python-based HDL tests and analysis tools.
# (See: https://github.com/astral-sh/uv)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:${PATH}"

# Install the GPL-2.0-or-later reSIDfp oracle library and public development API.
# Retain the source archive and license; keep this dependency out of core RTL.
# CXXFLAGS follow upstream CPPFLAGS, overriding its fast-math flags.
ARG LIBRESIDFP_ARCHIVE="libresidfp-${LIBRESIDFP_VERSION}.tar.gz"
RUN wget "https://github.com/libsidplayfp/libresidfp/releases/download/v${LIBRESIDFP_VERSION}/${LIBRESIDFP_ARCHIVE}" -P /tmp && \
    echo "${LIBRESIDFP_SHA256}  /tmp/${LIBRESIDFP_ARCHIVE}" | sha256sum -c - && \
    mkdir -p /tmp/libresidfp && \
    tar -xzf /tmp/${LIBRESIDFP_ARCHIVE} -C /tmp/libresidfp --strip-components=1 && \
    cd /tmp/libresidfp && \
    ./configure --with-simd=none --disable-lto \
        CXXFLAGS="-O2 -fno-fast-math -ffp-contract=off" && \
    make -j$(nproc) && \
    make check && \
    make install && \
    ldconfig && \
    test "$(pkg-config --modversion libresidfp)" = "${LIBRESIDFP_VERSION}" && \
    mkdir -p /usr/local/share/doc/libresidfp && \
    install -m 0644 COPYING /tmp/${LIBRESIDFP_ARCHIVE} /usr/local/share/doc/libresidfp/ && \
    cd /tmp && \
    rm -rf /tmp/libresidfp /tmp/${LIBRESIDFP_ARCHIVE}
