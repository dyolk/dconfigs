
# ============================================
# Stage 1: Builder
# 静态编译 Nginx + LuaJIT + 常用模块 + 主动健康检测
# ============================================
FROM alpine:3.19 AS builder

# 版本定义
ENV NGINX_VERSION=1.28.0
ENV LUAJIT2_VERSION=2.1-20240314
ENV NGX_DEVEL_KIT_VERSION=0.3.3
ENV LUA_NGINX_MODULE_VERSION=0.10.26
ENV UPSTREAM_CHECK_VERSION=0.4.0
ENV PCRE2_VERSION=10.43
ENV ZLIB_VERSION=1.3.1
ENV OPENSSL_VERSION=3.2.1

# 安装构建工具
RUN apk add --no-cache \
    gcc \
    g++ \
    make \
    linux-headers \
    curl \
    tar \
    gzip \
    patch \
    perl

WORKDIR /src

# 下载所有源码包
RUN curl -fsSL https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz | tar xz && \
    curl -fsSL https://github.com/openresty/luajit2/archive/refs/tags/v${LUAJIT2_VERSION}.tar.gz | tar xz && \
    curl -fsSL https://github.com/vision5/ngx_devel_kit/archive/refs/tags/v${NGX_DEVEL_KIT_VERSION}.tar.gz | tar xz && \
    curl -fsSL https://github.com/openresty/lua-nginx-module/archive/refs/tags/v${LUA_NGINX_MODULE_VERSION}.tar.gz | tar xz && \
    curl -fsSL https://github.com/yaoweibin/nginx_upstream_check_module/archive/refs/tags/v${UPSTREAM_CHECK_VERSION}.tar.gz | tar xz && \
    curl -fsSL https://github.com/PCRE2Project/pcre2/releases/download/pcre2-${PCRE2_VERSION}/pcre2-${PCRE2_VERSION}.tar.gz | tar xz && \
    curl -fsSL https://zlib.net/zlib-${ZLIB_VERSION}.tar.gz | tar xz && \
    curl -fsSL https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz | tar xz

# 编译 LuaJIT（静态库）
WORKDIR /src/luajit2-${LUAJIT2_VERSION}
RUN make -j$(nproc) \
    CFLAGS="-O2 -fPIC" \
    PREFIX=/usr/local/luajit && \
    make install PREFIX=/usr/local/luajit

# 编译 PCRE2（静态库）
WORKDIR /src/pcre2-${PCRE2_VERSION}
RUN ./configure \
    --prefix=/usr/local/pcre2 \
    --disable-shared \
    --enable-static \
    --enable-jit \
    --enable-utf && \
    make -j$(nproc) && \
    make install

# 编译 zlib（静态库）
WORKDIR /src/zlib-${ZLIB_VERSION}
RUN ./configure --static && \
    make -j$(nproc) && \
    make install

# 为 nginx_upstream_check_module 打补丁
WORKDIR /src/nginx-${NGINX_VERSION}
RUN patch -p1 < /src/nginx_upstream_check_module-${UPSTREAM_CHECK_VERSION}/check_1.20.1+.patch

# 编译 Nginx（纯静态链接）
WORKDIR /src/nginx-${NGINX_VERSION}
ENV LUAJIT_LIB=/usr/local/luajit/lib
ENV LUAJIT_INC=/usr/local/luajit/include/luajit-2.1
RUN ./configure \
    --prefix=/etc/nginx \
    --sbin-path=/usr/sbin/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/run/nginx.lock \
    --http-client-body-temp-path=/var/cache/nginx/client_temp \
    --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
    --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
    --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
    --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
    --with-cc-opt="-static -O2 -fPIC -I/usr/local/luajit/include/luajit-2.1" \
    --with-ld-opt="-static -L/usr/local/luajit/lib" \
    --with-pcre=/src/pcre2-${PCRE2_VERSION} \
    --with-zlib=/src/zlib-${ZLIB_VERSION} \
    --with-openssl=/src/openssl-${OPENSSL_VERSION} \
    --with-openssl-opt="no-shared no-tests -fPIC" \
    --with-http_ssl_module \
    --with-http_v2_module \
    --with-http_realip_module \
    --with-http_addition_module \
    --with-http_sub_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_mp4_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_random_index_module \
    --with-http_secure_link_module \
    --with-http_stub_status_module \
    --with-http_auth_request_module \
    --with-http_slice_module \
    --with-mail \
    --with-mail_ssl_module \
    --with-stream \
    --with-stream_ssl_module \
    --with-stream_realip_module \
    --with-threads \
    --with-file-aio \
    --add-module=/src/ngx_devel_kit-${NGX_DEVEL_KIT_VERSION} \
    --add-module=/src/lua-nginx-module-${LUA_NGINX_MODULE_VERSION} \
    --add-module=/src/nginx_upstream_check_module-${UPSTREAM_CHECK_VERSION} && \
    make -j$(nproc) && \
    make install

# 验证静态链接
RUN echo "=== Binary file info ===" && \
    file /usr/sbin/nginx && \
    echo "=== Dynamic dependencies ===" && \
    (ldd /usr/sbin/nginx 2>/dev/null || echo "No dynamic dependencies (fully static)") && \
    echo "=== Nginx version and modules ===" && \
    /usr/sbin/nginx -V

# 创建运行时目录结构
RUN mkdir -p /var/cache/nginx/client_temp \
    /var/cache/nginx/proxy_temp \
    /var/cache/nginx/fastcgi_temp \
    /var/cache/nginx/uwsgi_temp \
    /var/cache/nginx/scgi_temp

# ============================================
# Stage 2: Runtime (distroless/static)
# ============================================
FROM gcr.io/distroless/static

# 复制静态编译的 nginx 二进制文件
COPY --from=builder /usr/sbin/nginx /usr/sbin/nginx

# 复制配置文件和运行时目录
COPY --from=builder /etc/nginx /etc/nginx
COPY --from=builder /var/log/nginx /var/log/nginx
COPY --from=builder /var/run /var/run
COPY --from=builder /var/cache/nginx /var/cache/nginx

EXPOSE 80 443

ENTRYPOINT ["/usr/sbin/nginx"]
CMD ["-g", "daemon off;"]
