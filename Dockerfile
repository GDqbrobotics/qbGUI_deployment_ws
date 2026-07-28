FROM ubuntu:focal

ARG DEBIAN_FRONTEND=noninteractive

# System build tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    software-properties-common \
    && add-apt-repository ppa:beineri/opt-qt-5.15.0-focal && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    fuse \
    libfuse2 \
    binutils \
    libc6 \
    file \
    git \
    cmake \
    build-essential \
    libgl1-mesa-dev 

# Qt 5.15 from beineri PPA
RUN apt-get update && apt-get install -y --no-install-recommends \
    qt515base \
    qt515charts-no-lgpl \
    qt515connectivity \
    qt515declarative \
    qt515doc \
    qt515gamepad \
    qt515graphicaleffects \
    qt515imageformats \
    qt515location \
    qt515lottie-no-lgpl \
    qt515multimedia \
    qt515networkauth-no-lgpl \
    qt515quickcontrols \
    qt515quickcontrols2 \
    qt515remoteobjects \
    qt515script \
    qt515sensors \
    qt515serialbus \
    qt515serialport \
    qt515svg \
    qt515tools \
    qt515translations \
    qt515virtualkeyboard-no-lgpl \
    qt515webchannel \
    qt515webengine \
    qt515websockets \
    qt515x11extras \
    qt515xmlpatterns \
    && rm -rf /var/lib/apt/lists/*
