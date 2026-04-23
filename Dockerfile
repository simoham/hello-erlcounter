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

# Set the entry point to start your application
EXPOSE 8080

ENTRYPOINT ["rebar3", "shell"]
