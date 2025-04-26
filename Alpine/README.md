# Proton Mail Bridge docker - Alpine Linux version

A version based on [Alpine Linux](https://www.alpinelinux.org/). Same functionalities but in a lightweight image.

```bash
docker pull ghcr.io/asyncura/proton-mail-bridge-alpine:latest
```
```bash
docker run -d --name=protonmail_bridge_alpine -v /path/to/your/volume/storage-alpine:/root -p 127.0.0.1:14025:25/tcp -p 127.0.0.1:14143:143/tcp --network network20 --restart=unless-stopped ghcr.io/asyncura/proton-mail-bridge-alpine:latest
```
**OR** (docker compose version):
```bash
wget https://raw.githubusercontent.com/asyncura/ProtonMailBridgeDocker/master/Alpine/compose.yaml
docker-compose up -d
```

For installation and setup, see [README](https://github.com/asyncura/ProtonMailBridgeDocker).

## Developers notes

### Automated Builds
This repository uses GitHub Actions to automatically build and push Docker images to GitHub Container Registry (ghcr.io). See the main [README](https://github.com/asyncura/ProtonMailBridgeDocker) for details.

### Manual Builds
For local development and testing, you can use the build.sh script from the parent directory:
```bash
# Build with the latest version from GitHub:
cd /path/to/ProtonMailBridgeDocker/
./build.sh

# Build with a specific version:
./build.sh -v v3.19.0
```

For more details on Docker, see: [Docker documentation](https://docs.docker.com/language/python/containerize/)
```bash
# Local tests:
docker pull golang:1.23-alpine

git clone https://github.com/asyncura/ProtonMailBridgeDocker.git
cd /path/to/ProtonMailBridgeDocker/Alpine/
docker build --build-arg ENV_PROTONMAIL_BRIDGE_VERSION=v3.19.0 --tag=ghcr.io/asyncura/proton-mail-bridge-alpine .
docker images | grep proton-mail

docker run -it --rm --entrypoint /bin/bash ghcr.io/asyncura/proton-mail-bridge-alpine:latest

# (Optional) It is recommended to set up a custom docker network for all of your containers to use, for DNS / network-alias resolution:
sudo docker network create --subnet 172.20.0.0/16 network20

mkdir /path/to/your/volume/storage-alpine
docker run -d --name=protonmail_bridge_alpine -v /path/to/your/volume/storage-alpine:/root -p 127.0.0.1:14025:25/tcp -p 127.0.0.1:14143:143/tcp --network network20 --restart=unless-stopped ghcr.io/asyncura/proton-mail-bridge-alpine:latest

docker container logs protonmail_bridge_alpine
```

## License

Copyright (C) 2024 David BASTIEN

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
