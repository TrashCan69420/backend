FROM rustlang/rust:nightly-alpine AS chef
USER root
RUN apk add --no-cache g++
RUN cargo install cargo-chef
WORKDIR /app

FROM chef AS planner
COPY . .
RUN cargo chef prepare --recipe-path recipe.json

FROM chef AS builder
COPY --from=planner /app/recipe.json recipe.json

RUN cargo chef cook --release  --recipe-path recipe.json
COPY . .
RUN cargo build --release --locked --all-features  --bin polyfrost-api

# ---------------------------------------------------------------------------------------------

FROM alpine:3

COPY --from=builder /app/target/release/polyfrost-api /usr/local/bin/polyfrost-api

# Use an unprivileged user
RUN adduser --home /nonexistent --no-create-home --disabled-password polyfrost-api
USER polyfrost-api

HEALTHCHECK --interval=10s --timeout=3s --retries=5 CMD wget --spider --q http://localhost:$PORT/ || exit 1

CMD ["polyfrost-api"]