#!/usr/bin/env bash

set -euo pipefail

PROTONMAIL_BRIDGE_VERSION=""
PUSH=""

usage() {
  echo "Usage: $0 [-v version] [-p]"
  echo "  -v  Proton Mail Bridge version to build (e.g. v3.25.0). Default: latest release."
  echo "  -p  Push images to ghcr.io after building (no prompt)."
  exit 1
}

while getopts "v:ph" opt; do
  case $opt in
    v) PROTONMAIL_BRIDGE_VERSION=$OPTARG ;;
    p) PUSH="y" ;;
    *) usage ;;
  esac
done

# Get the latest version from the Proton Mail Bridge GitHub repository if not given
if [ -z "$PROTONMAIL_BRIDGE_VERSION" ]; then
  PROTONMAIL_BRIDGE_VERSION=$(curl -s https://api.github.com/repos/ProtonMail/proton-bridge/releases/latest | grep -o '"tag_name": *"[^"]*"' | grep -o 'v[0-9.]*')
  if [ -z "$PROTONMAIL_BRIDGE_VERSION" ]; then
    echo "Error: Could not determine the latest Proton Mail Bridge version."
    echo "Please specify a version manually with the -v flag."
    exit 1
  fi
fi

REGISTRY_IMAGE="ghcr.io/asyncura/proton-mail-bridge"

echo "Building Proton Mail Bridge docker images ${PROTONMAIL_BRIDGE_VERSION} !"

printf "\e[32m================================\e[0m \n"
echo "Building Debian image..."
docker build \
  --build-arg ENV_PROTONMAIL_BRIDGE_VERSION="$PROTONMAIL_BRIDGE_VERSION" \
  --tag "$REGISTRY_IMAGE:latest" \
  --tag "$REGISTRY_IMAGE:debian" \
  --tag "$REGISTRY_IMAGE:$PROTONMAIL_BRIDGE_VERSION" \
  --tag "$REGISTRY_IMAGE:$PROTONMAIL_BRIDGE_VERSION-debian" \
  .

printf "\e[32m================================\e[0m \n"
echo "Building Alpine image..."
docker build \
  --file Dockerfile.alpine \
  --build-arg ENV_PROTONMAIL_BRIDGE_VERSION="$PROTONMAIL_BRIDGE_VERSION" \
  --tag "$REGISTRY_IMAGE:alpine" \
  --tag "$REGISTRY_IMAGE:$PROTONMAIL_BRIDGE_VERSION-alpine" \
  .

printf "\e[32m================================\e[0m \n"
echo "See results:"
docker images "$REGISTRY_IMAGE"

printf "\e[32m================================\e[0m \n"
if [ -z "$PUSH" ]; then
  read -r -p "Push docker images to ghcr.io ? (y/n) " PUSH
fi

case $PUSH in
  [yY])
    echo "Uploading docker images..."
    docker push "$REGISTRY_IMAGE:latest"
    docker push "$REGISTRY_IMAGE:debian"
    docker push "$REGISTRY_IMAGE:$PROTONMAIL_BRIDGE_VERSION"
    docker push "$REGISTRY_IMAGE:$PROTONMAIL_BRIDGE_VERSION-debian"
    docker push "$REGISTRY_IMAGE:alpine"
    docker push "$REGISTRY_IMAGE:$PROTONMAIL_BRIDGE_VERSION-alpine"
    ;;
  *)
    echo "Not pushing. Done."
    ;;
esac
