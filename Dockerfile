FROM --platform=linux/amd64 amazonlinux:2
# 1) Install build dependencies, including xz for extracting .tar.xz files and opus libraries
RUN yum update -y && \
    yum install -y gcc gcc-c++ make git pkgconfig autoconf automake libtool \
                   yasm nasm tar gzip zip openssl-devel wget xz && \
    yum clean all

WORKDIR /build

# 2) Install Opus library
RUN wget https://archive.mozilla.org/pub/opus/opus-1.3.1.tar.gz && \
    tar xzf opus-1.3.1.tar.gz && \
    cd opus-1.3.1 && \
    ./configure --prefix=/usr && \
    make -j"$(nproc)" && \
    make install && \
    cd .. && \
    rm -rf opus-1.3.1 opus-1.3.1.tar.gz

# 3) Download FFmpeg 6.0 source
RUN wget https://ffmpeg.org/releases/ffmpeg-6.0.tar.xz && \
    tar xf ffmpeg-6.0.tar.xz
WORKDIR /build/ffmpeg-6.0

# 4) Configure a minimal build that includes only what we need
RUN PKG_CONFIG_PATH=/usr/lib/pkgconfig ./configure \
    --disable-static \
    --enable-shared \
    --disable-debug \
    --disable-doc \
    --disable-ffplay \
    --disable-avdevice \
    --disable-swscale \
    --disable-network \
    --disable-iconv \
    --disable-everything \
    --enable-openssl \
    --enable-protocol=https \
    --enable-protocol=file \
    --enable-protocol=pipe \
    --enable-demuxer=mov \
    --enable-demuxer=mp4 \
    --enable-demuxer=matroska \
    --enable-demuxer=wav \
    --enable-demuxer=ogg \
    --enable-decoder=aac \
    --enable-decoder=aac_fixed \
    --enable-decoder=mp3 \
    --enable-decoder=vorbis \
    --enable-decoder=flac \
    --enable-decoder=pcm_s16le \
    --enable-decoder=libopus \
    --enable-muxer=ogg \
    --enable-muxer=wav \
    --enable-encoder=libopus \
    --enable-encoder=pcm_s16le \
    --enable-avfilter \
    --enable-filter=aresample \
    --enable-swresample \
    --enable-ffmpeg \
    --enable-ffprobe \
    --enable-libopus \
    --arch=x86_64 \
    --target-os=linux \
    --prefix=/opt/ffmpeg && \
    make -j"$(nproc)" && \
    make install && \
    # 5) Strip binaries & libraries to shrink size
    strip --strip-unneeded /opt/ffmpeg/bin/ffmpeg && \
    strip --strip-unneeded /opt/ffmpeg/bin/ffprobe && \
    find /opt/ffmpeg/lib -type f -name "*.so*" -exec strip --strip-unneeded {} \; || true

# 6) Copy the stripped binaries and libraries to /opt
RUN mkdir -p /opt/bin /opt/lib && \
    cp /opt/ffmpeg/bin/ffmpeg /opt/bin/ && \
    cp /opt/ffmpeg/bin/ffprobe /opt/bin/ && \
    cp -P /opt/ffmpeg/lib/*.so* /opt/lib/ && \
    # Also copy opus libraries
    cp -P /usr/lib/libopus.so* /opt/lib/ && \
    chmod -R 755 /opt/bin /opt/lib

# 7) Create the Lambda layer structure  
RUN mkdir -p /lambda-layer/bin /lambda-layer/lib && \
    cp /opt/bin/* /lambda-layer/bin/ && \
    cp /opt/lib/* /lambda-layer/lib/

# 8) Package into a zip
WORKDIR /lambda-layer
RUN zip -r /build/ffmpeg-layer.zip . && \
    du -h /build/ffmpeg-layer.zip

CMD ["bash"]