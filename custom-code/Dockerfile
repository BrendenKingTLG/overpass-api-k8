FROM ubuntu/nginx AS builder

ARG version=0.7.62

ENV DEPS="autoconf=2.72-3 \
    automake=1:1.16.5-1.3ubuntu1 \
    bash=5.2.32-1ubuntu1.1 \
    bzip2=1.0.8-6 \
    ca-certificates=20240203 \
    expat=2.6.2-2 \
    g++=4:14.1.0-2ubuntu1\
    libexpat1-dev=2.6.2-2ubuntu0.1 \
    liblz4-1=1.9.4-3 \ 
    liblz4-dev=1.9.4-3 \
    libtool=2.4.7-7build1 \
    m4=1.4.19-4build1 \
    make=4.3-4.1build2 \
    osmium-tool=1.16.0-2 \
    zlib1g=1:1.3.dfsg+really1.3.1-1ubuntu1 \
    zlib1g-dev=1:1.3.dfsg+really1.3.1-1ubuntu1"

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install --no-install-recommends --no-install-suggests -y ${DEPS}

ADD http://dev.overpass-api.de/releases/osm-3s_v${version}.tar.gz /app/src.tar.gz

RUN  mkdir -p /app/src \
    && cd /app/src \
    && tar -x -z --strip-components 1 -f ../src.tar.gz \
    && autoscan \
    && aclocal \
    && autoheader \
    && libtoolize \
    && automake --add-missing  \
    && autoconf \
    && CXXFLAGS='-O2' CFLAGS='-O2' ./configure --prefix=/app --enable-lz4 \
    && make dist install clean \
    && mkdir -p /db/diffs /app/etc \
    && cp -r /app/src/rules /app/etc/rules \
    && rm -rf /app/src /app/src.tar.gz

FROM ubuntu/nginx

ENV OVERPASS_RULES_LOAD=1 \
    OVERPASS_USE_AREAS=true \
    OVERPASS_ALLOW_DUPLICATE_QUERIES=no \
    OVERPASS_SOCKET_DIR=/app/socket \
    DEPS="bash=5.2.32-1ubuntu1.1 \
    bzip2=1.0.8-6 \
    ca-certificates=20240203 \
    curl=8.9.1-2ubuntu2.2 \
    expat=2.6.2-2 \
    fcgiwrap=1.1.0-16 \
    jq=1.7.1-3build1 \ 
    liblz4-1=1.9.4-3 \ 
    osmium-tool=1.16.0-2 \
    python3=3.12.6-0ubuntu1 \ 
    python3-venv=3.12.6-0ubuntu1 \
    wget=1.24.5-1ubuntu2 \ 
    libxml2-utils=2.12.7+dfsg-3ubuntu0.2 \
    zlib1g=1:1.3.dfsg+really1.3.1-1ubuntu1"

COPY --from=builder /app /app

RUN addgroup overpass \
    && adduser --home /db --disabled-password --gecos overpass --ingroup overpass overpass

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install --no-install-recommends -y ${DEPS} \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /app/

RUN python3 -m venv /app/venv \
    && /app/venv/bin/pip install -r /app/requirements.txt --only-binary osmium

RUN mkdir -p /nginx /docker-entrypoint-initdb.d /app/socket /app/db/diffs /var/lib/nginx/body \
    && touch /app/db/replicate_id \
    && chown -R overpass:overpass /db /app /nginx /var/lib/nginx \
    && chmod -R 777 /app /db /app/socket /app/db/diffs /var/lib/nginx/body

COPY etc/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY etc/nginx-overpass.conf.template /etc/nginx/nginx.conf
COPY bin /app/bin
COPY ./*-entrypoint.sh /app/
COPY ./docker-healthcheck.sh /app/

RUN chmod a+rx -R /app/bin /app/*-entrypoint.sh /app/docker-healthcheck.sh

USER 1001

EXPOSE 80

CMD ["/app/docker-entrypoint.sh"]

HEALTHCHECK --start-period=48h CMD /app/docker-healthcheck.sh
