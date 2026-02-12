# Build stage
FROM registry.access.redhat.com/ubi9/go-toolset:latest AS builder

# Build arguments
ARG VERSION=v0.0.0-SNAPSHOT
ARG COMMIT_ID=unknown

# Switch to root to have full permissions
USER root

WORKDIR /workspace

# Allow Go to download the required toolchain version
ENV GOTOOLCHAIN=auto

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build the binary for Linux
RUN CGO_ENABLED=0 GOOS=linux go build \
    -buildvcs=false \
    -ldflags "-X main.version=${VERSION} -X main.commitID=${COMMIT_ID}" \
    -o helmet-ex ./example/helmet-ex

# Runtime stage
FROM registry.access.redhat.com/ubi9-micro:latest
COPY --from=builder /workspace/helmet-ex /usr/local/bin/helmet-ex
ENTRYPOINT ["helmet-ex"]
