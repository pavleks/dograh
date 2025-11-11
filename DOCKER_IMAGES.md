# Docker Images Guide - Fully Independent Dograh

This guide explains how to build, distribute, and use Docker images for the fully independent Dograh deployment.

## Overview

The Dograh platform consists of **2 main Docker images**:
1. **API Image** - FastAPI backend with Python services
2. **UI Image** - Next.js frontend

These images are **fully independent** with:
- ❌ No telemetry or analytics
- ❌ No hardcoded Dograh service dependencies
- ✅ Complete privacy and data sovereignty
- ✅ Multi-platform support (amd64, arm64)

## Quick Start

### Option 1: Pre-built Images (Recommended)

Pull pre-built images from GitHub Container Registry:

```bash
# Pull API image
docker pull ghcr.io/pavleks/dograh-independent-api:latest

# Pull UI image
docker pull ghcr.io/pavleks/dograh-independent-ui:latest

# Run with docker-compose
docker compose up
```

### Option 2: Build Locally

Build images on your machine:

```bash
# Clone the repository
git clone https://github.com/pavleks/dograh.git
cd dograh
git checkout claude/fully-independent-011CV2BJhcLN4sVZzRDUFRcb

# Build images
./build-docker-images.sh

# Run
docker compose up
```

### Option 3: Download Tar Files

Download pre-packaged tar.gz files and load:

```bash
# Download from GitHub Releases or your distribution point
wget https://github.com/pavleks/dograh/releases/download/vX.X.X/dograh-independent-api-latest.tar.gz
wget https://github.com/pavleks/dograh/releases/download/vX.X.X/dograh-independent-ui-latest.tar.gz

# Load images
./load-docker-images.sh
```

## Building Docker Images

### Prerequisites

- Docker 20.10+ installed
- Docker Buildx for multi-platform builds (optional)
- At least 10GB free disk space

### Build Both Images

Use the provided build script:

```bash
# Build with defaults
./build-docker-images.sh

# Build with custom prefix and version
IMAGE_PREFIX=my-dograh VERSION=1.0.0 ./build-docker-images.sh

# Build for specific platform
PLATFORM=linux/amd64 ./build-docker-images.sh
```

### Build Individual Images

```bash
# Build API image
docker build -t dograh-independent/api:latest -f api/Dockerfile .

# Build UI image
docker build -t dograh-independent/ui:latest -f ui/Dockerfile .
```

### Multi-Platform Builds

Build for both amd64 and arm64:

```bash
# Create buildx builder (one-time setup)
docker buildx create --name dograh-builder --use

# Build for multiple platforms
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t dograh-independent/api:latest \
  -f api/Dockerfile \
  --push \
  .
```

## Saving and Loading Images

### Save Images to Tar Files

```bash
# Save both images
./save-docker-images.sh

# Images saved to ./docker-images/
# - dograh-independent-api-latest.tar.gz
# - dograh-independent-ui-latest.tar.gz
```

### Load Images from Tar Files

```bash
# Load both images
./load-docker-images.sh

# Or load manually
gunzip dograh-independent-api-latest.tar.gz
docker load -i dograh-independent-api-latest.tar

gunzip dograh-independent-ui-latest.tar.gz
docker load -i dograh-independent-ui-latest.tar
```

### Distribution

Share tar files via:
- USB drives (air-gapped environments)
- Internal file servers
- GitHub Releases
- Private artifact repositories

## Publishing to Registries

### GitHub Container Registry (GHCR)

Automatic via GitHub Actions:

```bash
# Push triggers automatic build
git push origin claude/fully-independent-011CV2BJhcLN4sVZzRDUFRcb
```

Manual push:

```bash
# Login to GHCR
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# Tag images
docker tag dograh-independent/api:latest ghcr.io/USERNAME/dograh-independent-api:latest
docker tag dograh-independent/ui:latest ghcr.io/USERNAME/dograh-independent-ui:latest

# Push
docker push ghcr.io/USERNAME/dograh-independent-api:latest
docker push ghcr.io/USERNAME/dograh-independent-ui:latest
```

### Docker Hub

```bash
# Login to Docker Hub
docker login

# Tag images
docker tag dograh-independent/api:latest USERNAME/dograh-independent-api:latest
docker tag dograh-independent/ui:latest USERNAME/dograh-independent-ui:latest

# Push
docker push USERNAME/dograh-independent-api:latest
docker push USERNAME/dograh-independent-ui:latest
```

### Private Registry

```bash
# Login to private registry
docker login registry.company.com

# Tag images
docker tag dograh-independent/api:latest registry.company.com/dograh-api:latest
docker tag dograh-independent/ui:latest registry.company.com/dograh-ui:latest

# Push
docker push registry.company.com/dograh-api:latest
docker push registry.company.com/dograh-ui:latest
```

## Using the Images

### With Docker Compose

Update `docker-compose.yaml`:

```yaml
services:
  api:
    image: ghcr.io/pavleks/dograh-independent-api:latest
    # or: dograh-independent/api:latest for local builds
    environment:
      # Add your configuration

  ui:
    image: ghcr.io/pavleks/dograh-independent-ui:latest
    # or: dograh-independent/ui:latest for local builds
```

Then run:

```bash
docker compose up
```

### With Docker Run

```bash
# Run API
docker run -d \
  --name dograh-api \
  -p 8000:8000 \
  -e DATABASE_URL=postgresql://... \
  -e REDIS_URL=redis://... \
  -e OPENAI_API_KEY=sk-xxx \
  ghcr.io/pavleks/dograh-independent-api:latest

# Run UI
docker run -d \
  --name dograh-ui \
  -p 3010:3010 \
  -e BACKEND_URL=http://dograh-api:8000 \
  ghcr.io/pavleks/dograh-independent-ui:latest
```

### In Kubernetes

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dograh-api
spec:
  replicas: 2
  template:
    spec:
      containers:
      - name: api
        image: ghcr.io/pavleks/dograh-independent-api:latest
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: dograh-secrets
              key: database-url
```

## Image Details

### API Image

**Base:** `python:3.12-slim`

**Size:** ~800MB (compressed: ~300MB)

**Includes:**
- Python 3.12
- FastAPI application
- Pipecat with AI providers
- Database migrations
- FFmpeg for audio processing

**Exposed Port:** `8000`

**Healthcheck:** `http://localhost:8000/api/v1/health`

### UI Image

**Base:** `node:20-alpine`

**Size:** ~400MB (compressed: ~150MB)

**Includes:**
- Node.js 20
- Next.js standalone build
- Static assets
- Production optimizations

**Exposed Port:** `3010`

**Healthcheck:** `http://localhost:3010/`

## Environment Variables

### Required for API Image

```bash
DATABASE_URL=postgresql+asyncpg://user:pass@host:5432/db
REDIS_URL=redis://:password@host:6379
OPENAI_API_KEY=sk-proj-xxx
ELEVENLABS_API_KEY=sk_xxx
DEEPGRAM_API_KEY=xxx
```

### Required for UI Image

```bash
BACKEND_URL=http://api:8000
NEXT_PUBLIC_BACKEND_URL=http://localhost:8000
```

### Optional Variables

See [RAILWAY_DEPLOYMENT.md](RAILWAY_DEPLOYMENT.md) for complete list.

## Image Security

### What's NOT Included

- ❌ Hardcoded secrets or API keys
- ❌ Telemetry or analytics code
- ❌ Dograh service dependencies
- ❌ Development dependencies

### Security Best Practices

1. **Scan images regularly:**
   ```bash
   docker scan dograh-independent/api:latest
   ```

2. **Use specific versions in production:**
   ```bash
   docker pull ghcr.io/pavleks/dograh-independent-api:v1.2.0
   ```

3. **Verify image signatures:**
   ```bash
   docker trust inspect ghcr.io/pavleks/dograh-independent-api:latest
   ```

4. **Run as non-root:**
   - UI image runs as user `nextjs` (UID 1001)
   - API image runs as `root` (requires database migrations)

## Optimizations

### Build Cache

The build scripts use Docker layer caching:

```bash
# Build with cache
docker build --cache-from dograh-independent/api:latest \
  -t dograh-independent/api:latest \
  -f api/Dockerfile .
```

### Multi-Stage Builds

Both Dockerfiles use multi-stage builds to:
- Minimize final image size
- Separate build and runtime dependencies
- Improve security

### Size Optimization

```bash
# View image layers
docker history dograh-independent/api:latest

# Analyze image size
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  wagoodman/dive:latest dograh-independent/api:latest
```

## Troubleshooting

### Build Fails

**Issue:** Build fails with "no space left on device"

**Solution:**
```bash
# Clean up Docker
docker system prune -a
docker builder prune -a
```

### Image Won't Start

**Issue:** Container exits immediately

**Solution:**
```bash
# Check logs
docker logs dograh-api

# Verify environment variables
docker inspect dograh-api
```

### Push Fails

**Issue:** "denied: requested access to the resource is denied"

**Solution:**
```bash
# Re-login to registry
docker logout ghcr.io
docker login ghcr.io

# Ensure repository exists and you have push access
```

### Large Image Size

**Issue:** Images are too large

**Solution:**
```bash
# Remove build dependencies
# Add to .dockerignore:
# - node_modules
# - .git
# - *.log
# - __pycache__

# Use alpine base images where possible
# Use multi-stage builds
```

## Automated Builds

### GitHub Actions

The repository includes a workflow: `.github/workflows/build-docker-images.yml`

**Triggers:**
- Push to `claude/fully-independent-*` branches
- Pull requests to `main`
- Manual workflow dispatch
- Git tags

**Output:**
- Images pushed to GHCR
- Optionally pushed to Docker Hub
- Build artifacts in Actions

### Enable Auto-Build

1. Fork the repository
2. Enable GitHub Actions
3. (Optional) Add Docker Hub secrets:
   - `DOCKERHUB_USERNAME`
   - `DOCKERHUB_TOKEN`
4. Push to trigger build

## Continuous Deployment

### Update Strategy

**Rolling Update:**
```bash
# Pull latest images
docker compose pull

# Restart with new images
docker compose up -d
```

**Blue-Green Deployment:**
```bash
# Deploy new version
docker compose -f docker-compose.blue.yaml up -d

# Test new version
curl http://localhost:3011/health

# Switch traffic
# Update load balancer or reverse proxy

# Stop old version
docker compose -f docker-compose.green.yaml down
```

## Version Management

### Tagging Strategy

```
ghcr.io/pavleks/dograh-independent-api:latest       # Latest build
ghcr.io/pavleks/dograh-independent-api:v1.2.0      # Specific version
ghcr.io/pavleks/dograh-independent-api:v1.2        # Minor version
ghcr.io/pavleks/dograh-independent-api:v1          # Major version
ghcr.io/pavleks/dograh-independent-api:sha-abc123  # Git commit
```

### Pinning Versions

```yaml
# docker-compose.yaml
services:
  api:
    image: ghcr.io/pavleks/dograh-independent-api:v1.2.0  # Pinned

  ui:
    image: ghcr.io/pavleks/dograh-independent-ui:v1.2.0   # Pinned
```

## Support

- **Build Issues:** Check [build-docker-images.sh](build-docker-images.sh)
- **Deployment Issues:** See [RAILWAY_DEPLOYMENT.md](RAILWAY_DEPLOYMENT.md)
- **Security:** [THIRD_PARTY_CONNECTIONS.md](THIRD_PARTY_CONNECTIONS.md)
- **GitHub Issues:** https://github.com/pavleks/dograh/issues

## License

These Docker images contain software licensed under the BSD 2-Clause License.
See [LICENSE](LICENSE) for details.
