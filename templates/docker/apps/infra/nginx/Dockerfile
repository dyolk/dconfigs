
FROM alpine AS builder

ENV NGINX_VERSION=1.28.0
RUN wget https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
    tar -zxf nginx-${NGINX_VERSION}.tar.gz

WORKDIR /nginx-${NGINX_VERSION}

RUN ./configure \
    --prefix=/etc/nginx

FROM gcr.io/distroless/static

COPY --from=builder /usr/sbin/nginx /usr/sbin/nginx
