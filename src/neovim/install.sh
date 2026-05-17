#!/bin/sh
# Debian / Ubuntu dependencies
install_debian_dependencies() {
  # Neovim plugin dependencies
  apt-get update -y
  apt-get install -y build-essential npm python3-pip python3-venv ripgrep fd-find
  npm install -g tree-sitter-cli

  apt-get -y clean
  rm -rf /var/lib/apt/lists/*
}

set -ex

echo "Activating feature 'neovim'"

VERSION=${VERSION:-stable}
ADJUSTED_VERSION=$VERSION
if [ "$VERSION" != "stable" ] && [ "$VERSION" != "nightly" ]; then
  ADJUSTED_VERSION="v$VERSION"
fi

echo "The version to be installed is: $VERSION"

if [ "$(id -u)" -ne 0 ]; then
  echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
  exit 1
fi

# Bring in ID, ID_LIKE, VERSION_ID, VERSION_CODENAME
. /etc/os-release
# Get an adjusted ID independent of distro variants
if [ "${ID}" = "debian" ] || [ "${ID_LIKE}" = "debian" ]; then
  ADJUSTED_ID="debian"
else
  echo "Linux distro ${ID} not supported."
  exit 1
fi

# Install packages for appropriate OS
case "${ADJUSTED_ID}" in
"debian")
  install_debian_dependencies
  ;;
esac

ARCHITECTURE="$(dpkg --print-architecture)"
case "${ARCHITECTURE}" in
"amd64")
  ADJUSTED_ARCHITECTURE=x86_64
  ;;
"arm64")
  ADJUSTED_ARCHITECTURE=arm64
  ;;
*)
  echo "Unsupported architecture: $TARGETARCH" >&2
  exit 1
  ;;
esac
ASSET_PREFIX="nvim-linux-${ADJUSTED_ARCHITECTURE}"
ASSET="${ASSET_PREFIX}.tar.gz"
DOWNLOAD_URL="https://github.com/neovim/neovim/releases/download/${ADJUSTED_VERSION}/${ASSET}"

echo "Downloading Neovim ${ADJUSTED_VERSION} binary for ${ADJUSTED_ARCHITECTURE}..."

curl -LO "${DOWNLOAD_URL}"
tar -C /opt -xzf "${ASSET}"
rm "${ASSET}"
ln -sf "/opt/${ASSET_PREFIX}/bin/nvim" /usr/local/bin/nvim
