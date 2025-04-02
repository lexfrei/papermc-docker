@echo off
SETLOCAL

REM Create data directory if it doesn't exist
if not exist data mkdir data

docker run -d ^
  --name minecraft-server ^
  -p 25565:25565/tcp ^
  -p 25565:25565/udp ^
  -p 8123:8123/tcp ^
  --memory 4G ^
  -v "%cd%\data:/data" ^
  --restart unless-stopped ^
  lexfrei/papermc:latest

ENDLOCAL
