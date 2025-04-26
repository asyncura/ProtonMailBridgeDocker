#!/usr/bin/env bash

# Get the latest version from the Proton Mail Bridge GitHub repository
PROTONMAIL_BRIDGE_VERSION=$(curl -s https://api.github.com/repos/ProtonMail/proton-bridge/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')

if [ -z "$PROTONMAIL_BRIDGE_VERSION" ]; then
  echo "Error: Could not determine the latest Proton Mail Bridge version."
  echo "Please specify a version manually with the -v flag."
  exit 1
fi

# Allow overriding the version with a command-line argument
while getopts "v:" opt; do
  case $opt in
    v)
      PROTONMAIL_BRIDGE_VERSION=$OPTARG
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

echo "Building Proton Mail Bridge docker images ${PROTONMAIL_BRIDGE_VERSION} !"

printf "\e[32m================================\e[0m \n"
printf "\e[32m================================\e[0m \n"
echo "Updating sources images..."
docker pull golang:bookworm
docker pull golang:1.23-alpine

printf "\e[32m================================\e[0m \n"
printf "\e[32m================================\e[0m \n"
echo "Building Debian image..."
docker build --build-arg ENV_PROTONMAIL_BRIDGE_VERSION="$PROTONMAIL_BRIDGE_VERSION" --tag=ghcr.io/asyncura/proton-mail-bridge .
docker image tag ghcr.io/asyncura/proton-mail-bridge:latest ghcr.io/asyncura/proton-mail-bridge:"$PROTONMAIL_BRIDGE_VERSION"

printf "\e[32m================================\e[0m \n"
printf "\e[32m================================\e[0m \n"
echo "Building Alpine image..."
cd Alpine/ || exit

docker build --build-arg ENV_PROTONMAIL_BRIDGE_VERSION="$PROTONMAIL_BRIDGE_VERSION" --tag=ghcr.io/asyncura/proton-mail-bridge-alpine .
docker image tag ghcr.io/asyncura/proton-mail-bridge-alpine:latest ghcr.io/asyncura/proton-mail-bridge-alpine:"$PROTONMAIL_BRIDGE_VERSION"

printf "\e[32m================================\e[0m \n"
printf "\e[32m================================\e[0m \n"
echo "See results:"
docker images | grep proton-mail

# Tests images
# docker stop protonmail_bridge && docker rm protonmail_bridge
# docker stop protonmail_bridge_alpine && docker rm protonmail_bridge_alpine

printf "\e[32m================================\e[0m \n"
printf "\e[32m================================\e[0m \n"
while true; do

read -p "Push docker images to ghcr.io ? (y/n) " yn

case $yn in
  [yY] ) echo "Uploading docker images...";
    docker push ghcr.io/asyncura/proton-mail-bridge:"$PROTONMAIL_BRIDGE_VERSION";
    docker push ghcr.io/asyncura/proton-mail-bridge:latest;
    docker push ghcr.io/asyncura/proton-mail-bridge-alpine:"$PROTONMAIL_BRIDGE_VERSION";
    docker push ghcr.io/asyncura/proton-mail-bridge-alpine:latest;
    break;;
  [nN] ) echo "Exiting...";
    exit;;
  * ) echo "Invalid response";;
esac

done
