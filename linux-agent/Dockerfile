# Build stage
FROM golang:1.21-alpine AS builder

WORKDIR /build

# Copy go module files
COPY go.mod ./

# Copy source code
COPY . .

# Build the binary
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -ldflags '-w -s' -o agent .

# Final stage
FROM alpine:latest

WORKDIR /app

# Copy binary from builder
COPY --from=builder /build/agent /app/agent

# Expose default port
EXPOSE 9955

# Set entrypoint
ENTRYPOINT ["/app/agent"]
