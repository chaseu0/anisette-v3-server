# Base for builder
FROM debian:stable-20250520-slim AS builder
# Deps for builder
RUN apt-get update && apt-get install --no-install-recommends -y ca-certificates ldc git clang dub libz-dev libssl-dev libplist-dev libplist-2.0-4 \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Build for builder
WORKDIR /opt/
COPY . .
RUN DC=ldc2 dub build -c "static" --build-mode allAtOnce -b release --compiler=ldc2

# Base for run
FROM debian:stable-slim
RUN apt-get update && apt-get install --no-install-recommends -y ca-certificates curl libplist-dev libplist-2.0-4\
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Copy build artefacts to run
WORKDIR /opt/
COPY --from=builder /opt/anisette-v3-server /opt/anisette-v3-server

# Create default provisioning folder
RUN mkdir -p /opt/anisette-v3/provisioning

# Setup rootless user which works with the volume mount
RUN useradd -ms /bin/bash Alcoholic \
 && mkdir /home/Alcoholic/.config/anisette-v3/lib/ -p \
 && chown -R Alcoholic /home/Alcoholic/ \
 && chmod -R +wx /home/Alcoholic/ \
 && chown -R Alcoholic /opt/ \
 && chmod -R +wx /opt/

# Run the artefact
# Cloud hosts (Render/Railway) inject PORT; default remains 6969 for local Docker.
USER Alcoholic
EXPOSE 6969
ENTRYPOINT ["/bin/sh", "-c", "exec /opt/anisette-v3-server -n 0.0.0.0 -p ${PORT:-6969}"]
