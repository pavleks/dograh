#!/bin/bash

# Docker Image Load Script
# This script loads Docker images from tar.gz files

set -e  # Exit on error

# Configuration
IMAGE_DIR="${IMAGE_DIR:-./docker-images}"
VERSION="${VERSION:-latest}"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}  Loading Docker Images from Tar Files${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""

# Check if image directory exists
if [ ! -d "${IMAGE_DIR}" ]; then
    echo -e "${RED}Error: Image directory not found: ${IMAGE_DIR}${NC}"
    echo "Please run ./save-docker-images.sh first or specify IMAGE_DIR"
    exit 1
fi

API_IMAGE="${IMAGE_DIR}/dograh-independent-api-${VERSION}.tar.gz"
UI_IMAGE="${IMAGE_DIR}/dograh-independent-ui-${VERSION}.tar.gz"

# Check if API image exists
if [ ! -f "${API_IMAGE}" ]; then
    echo -e "${RED}Error: API image not found: ${API_IMAGE}${NC}"
    exit 1
fi

# Check if UI image exists
if [ ! -f "${UI_IMAGE}" ]; then
    echo -e "${RED}Error: UI image not found: ${UI_IMAGE}${NC}"
    exit 1
fi

echo -e "${GREEN}Step 1/4: Decompressing API Image${NC}"
echo "--------------------------------------------"
gunzip -k -f "${API_IMAGE}"
echo -e "${GREEN}✓ API image decompressed${NC}"
echo ""

echo -e "${GREEN}Step 2/4: Loading API Image${NC}"
echo "--------------------------------------------"
docker load -i "${IMAGE_DIR}/dograh-independent-api-${VERSION}.tar"
echo -e "${GREEN}✓ API image loaded${NC}"
echo ""

echo -e "${GREEN}Step 3/4: Decompressing UI Image${NC}"
echo "--------------------------------------------"
gunzip -k -f "${UI_IMAGE}"
echo -e "${GREEN}✓ UI image decompressed${NC}"
echo ""

echo -e "${GREEN}Step 4/4: Loading UI Image${NC}"
echo "--------------------------------------------"
docker load -i "${IMAGE_DIR}/dograh-independent-ui-${VERSION}.tar"
echo -e "${GREEN}✓ UI image loaded${NC}"
echo ""

# Clean up decompressed tar files
rm -f "${IMAGE_DIR}/dograh-independent-api-${VERSION}.tar"
rm -f "${IMAGE_DIR}/dograh-independent-ui-${VERSION}.tar"

echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}  ✓ Load Complete!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo "Loaded images:"
docker images | grep "dograh-independent" || echo "No images found"
echo ""
echo "To run the images:"
echo "  docker compose up"
echo ""
