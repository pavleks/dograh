#!/bin/bash

# Docker Image Save Script
# This script saves built Docker images to tar files for distribution

set -e  # Exit on error

# Configuration
IMAGE_PREFIX="${IMAGE_PREFIX:-dograh-independent}"
VERSION="${VERSION:-latest}"
OUTPUT_DIR="${OUTPUT_DIR:-./docker-images}"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}  Saving Docker Images to Tar Files${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""

# Create output directory
mkdir -p "${OUTPUT_DIR}"
echo "Output directory: ${OUTPUT_DIR}"
echo ""

echo -e "${GREEN}Step 1/3: Saving API Image${NC}"
echo "--------------------------------------------"
docker save ${IMAGE_PREFIX}/api:${VERSION} -o "${OUTPUT_DIR}/dograh-independent-api-${VERSION}.tar"
echo -e "${GREEN}✓ API image saved${NC}"
echo ""

echo -e "${GREEN}Step 2/3: Saving UI Image${NC}"
echo "--------------------------------------------"
docker save ${IMAGE_PREFIX}/ui:${VERSION} -o "${OUTPUT_DIR}/dograh-independent-ui-${VERSION}.tar"
echo -e "${GREEN}✓ UI image saved${NC}"
echo ""

echo -e "${GREEN}Step 3/3: Compressing Images${NC}"
echo "--------------------------------------------"
echo "Compressing API image..."
gzip -f "${OUTPUT_DIR}/dograh-independent-api-${VERSION}.tar"
echo "Compressing UI image..."
gzip -f "${OUTPUT_DIR}/dograh-independent-ui-${VERSION}.tar"
echo -e "${GREEN}✓ Images compressed${NC}"
echo ""

# Calculate file sizes
API_SIZE=$(du -h "${OUTPUT_DIR}/dograh-independent-api-${VERSION}.tar.gz" | cut -f1)
UI_SIZE=$(du -h "${OUTPUT_DIR}/dograh-independent-ui-${VERSION}.tar.gz" | cut -f1)

echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}  ✓ Save Complete!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo "Saved images:"
echo "  • ${OUTPUT_DIR}/dograh-independent-api-${VERSION}.tar.gz (${API_SIZE})"
echo "  • ${OUTPUT_DIR}/dograh-independent-ui-${VERSION}.tar.gz (${UI_SIZE})"
echo ""
echo "To load these images on another machine:"
echo "  gunzip dograh-independent-api-${VERSION}.tar.gz"
echo "  docker load -i dograh-independent-api-${VERSION}.tar"
echo ""
echo "  gunzip dograh-independent-ui-${VERSION}.tar.gz"
echo "  docker load -i dograh-independent-ui-${VERSION}.tar"
echo ""
echo "Or use the load script:"
echo "  ./load-docker-images.sh"
echo ""
