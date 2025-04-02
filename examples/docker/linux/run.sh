#!/bin/bash

# Create data directory if it doesn't exist
mkdir -p ./data

docker run -d \
  --name minecraft-server \
  -p 25565:25565/tcp \
  -p 25565:25565/udp \
  # Uncomment if you're using Dynmap
  # -p 8123:8123/tcp \
  -v "$(pwd)/data:/data" \
  --memory 4G \
  --restart unless-stopped \
  lexfrei/papermc:latest
