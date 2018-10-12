FROM resin/armv7hf-debian:stretch as builder

# Fluent Bit version
ENV FLB_MAJOR 0
ENV FLB_MINOR 14
ENV FLB_PATCH 4
ENV FLB_VERSION 0.14.4

ENV DEBIAN_FRONTEND noninteractive

ENV FLB_TARBALL http://github.com/fluent/fluent-bit/archive/v$FLB_VERSION.zip

RUN mkdir -p /fluent-bit/bin /fluent-bit/etc /fluent-bit/log /tmp/src/

RUN apt-get update \
#    && apt-get dist-upgrade -y \
    && apt-get install -y \
       build-essential \
       cmake \
       make \
       wget \
       unzip \
       libsystemd-dev \
       libssl1.0-dev \
       libasl-dev \
    && wget -O "/tmp/fluent-bit-${FLB_VERSION}.zip" ${FLB_TARBALL} \
    && cd /tmp && unzip "fluent-bit-$FLB_VERSION.zip" \
    && cd "fluent-bit-$FLB_VERSION"/build/ \
    && cmake -DFLB_DEBUG=On \
          -DFLB_TRACE=Off \
          -DFLB_JEMALLOC=On \
          -DFLB_BUFFERING=On \
          -DFLB_TLS=On \
          -DFLB_SHARED_LIB=Off \
          -DFLB_EXAMPLES=Off \
          -DFLB_HTTP_SERVER=On \
          -DFLB_OUT_ES=On \
          -DFLB_OUT_TD=Off \
          -DFLB_OUT_KAFKA=Off .. \
    && make \
    && install bin/fluent-bit /fluent-bit/bin/

# Configuration files
COPY fluent-bit.conf \
     parsers.conf \
#     parsers_java.conf \
#     parsers_mult.conf \
#     parsers_openstack.conf \
#     parsers_cinder.conf \
     /fluent-bit/etc/

FROM resin/armv7hf-debian:stretch
MAINTAINER Peter Jakobs <peterjakobs67@gmail.com>

RUN apt-get update \
#    && apt-get dist-upgrade -y \
    && apt-get install --no-install-recommends ca-certificates libssl1.0.2 -y \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get autoclean
COPY --from=builder /fluent-bit /fluent-bit

#
EXPOSE 2020

# Entry point
CMD ["/fluent-bit/bin/fluent-bit", "-c", "/fluent-bit/etc/fluent-bit.conf"]
