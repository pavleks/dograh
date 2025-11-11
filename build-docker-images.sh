#!/bin/bash

# Docker Image Build Script for Fully Independent Dograh
# This script builds both API and UI Docker images

set -e  # Exit on error

# Configuration
IMAGE_PREFIX="${IMAGE_PREFIX:-dograh-independent}"
VERSION="${VERSION:-latest}"
PLATFORM="${PLATFORM:-linux/amd64,linux/arm64}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}  Building Dograh Independent Docker Images${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo "Image Prefix: ${IMAGE_PREFIX}"
echo "Version: ${VERSION}"
echo "Platform: ${PLATFORM}"
echo ""

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed or not in PATH${NC}"
    echo "Please install Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if docker buildx is available for multi-platform builds
if docker buildx version &> /dev/null; then
    echo -e "${GREEN}✓ Docker Buildx available - multi-platform build enabled${NC}"
    BUILD_CMD="docker buildx build"
    PLATFORM_FLAG="--platform ${PLATFORM}"
else
    echo -e "${YELLOW}⚠ Docker Buildx not available - building for current platform only${NC}"
    BUILD_CMD="docker build"
    PLATFORM_FLAG=""
fi

echo ""
echo -e "${GREEN}Step 1/3: Building API Docker Image${NC}"
echo "--------------------------------------------"

$BUILD_CMD \
    $PLATFORM_FLAG \
    --build-arg BUILDKIT_INLINE_CACHE=1 \
    -t ${IMAGE_PREFIX}/api:${VERSION} \
    -t ${IMAGE_PREFIX}/api:latest \
    -f api/Dockerfile \
    . || {
        echo -e "${RED}Failed to build API image${NC}"
        exit 1
    }

echo -e "${GREEN}✓ API image built successfully${NC}"
echo ""

echo -e "${GREEN}Step 2/3: Building UI Docker Image${NC}"
echo "--------------------------------------------"

$BUILD_CMD \
    $PLATFORM_FLAG \
    --build-arg BUILDKIT_INLINE_CACHE=1 \
    -t ${IMAGE_PREFIX}/ui:${VERSION} \
    -t ${IMAGE_PREFIX}/ui:latest \
    -f ui/Dockerfile \
    . || {
        echo -e "${RED}Failed to build UI image${NC}"
        exit 1
    }

echo -e "${GREEN}✓ UI image built successfully${NC}"
echo ""

echo -e "${GREEN}Step 3/3: Listing Built Images${NC}"
echo "--------------------------------------------"
docker images | grep "${IMAGE_PREFIX}" || true

echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}  ✓ Build Complete!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo "Images created:"
echo "  • ${IMAGE_PREFIX}/api:${VERSION}"
echo "  • ${IMAGE_PREFIX}/ui:${VERSION}"
echo ""
echo "Next steps:"
echo "  1. Test images locally:"
echo "     docker compose -f docker-compose.yaml up"
echo ""
echo "  2. Save images to tar files:"
echo "     ./save-docker-images.sh"
echo ""
echo "  3. Push to Docker Hub (requires login):"
echo "     docker push ${IMAGE_PREFIX}/api:${VERSION}"
echo "     docker push ${IMAGE_PREFIX}/ui:${VERSION}"
echo ""
echo "  4. Push to GitHub Container Registry:"
echo "     docker tag ${IMAGE_PREFIX}/api:${VERSION} ghcr.io/YOUR_USERNAME/${IMAGE_PREFIX}-api:${VERSION}"
echo "     docker push ghcr.io/YOUR_USERNAME/${IMAGE_PREFIX}-api:${VERSION}"
echo ""
