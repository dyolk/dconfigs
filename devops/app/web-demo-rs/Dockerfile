
FROM rust:1.94 as builder

WORKDIR /app
COPY . .
RUN cargo build --release

FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=builder /app/target/release/web-demo-rs /app/web-demo-rs

EXPOSE 3000

RUN useradd -m -u 1000 appuser
USER appuser

CMD ["/app/web-demo-rs"]