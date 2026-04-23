# Stage 1: Build stage
# Uses the official Erlang Alpine image with build tools
FROM erlang:27-alpine AS builder

# Set working directory
WORKDIR /build

# Install additional build dependencies if needed (e.g., for NIFs)
RUN apk update
RUN apk add --no-cache git gcc libc-dev make rebar3 lsof ca-certificates


# Copy project files
COPY . .

# Compile and generate a release using rebar3
RUN rebar3 -v
RUN rm -rf rebar.lock && rm -rf _build
RUN DIAGNOSTIC=1 rebar3 get-deps && rebar3 compile

RUN rebar3 as prod release

# Stage 2: Runtime stage
# Uses a fresh Alpine image for the smallest possible footprint
FROM alpine:3.19

# Install runtime dependencies required by Erlang (openssl, ncurses, etc.)
RUN apk add --no-cache openssl ncurses libstdc++

# Set working directory
WORKDIR /app

# Copy the release from the builder stage
# Adjust the path based on your rebar.config (default: _build/prod/rel/<app_name>)
COPY --from=builder /build/_build/prod/rel/counter ./

# Set the entry point to start your application
EXPOSE 8080

ENTRYPOINT ["/app/bin/counter"]
CMD ["foreground"]

