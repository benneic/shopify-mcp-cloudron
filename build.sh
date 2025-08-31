#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
APP_ID="com.shopify.mcp-server"
VERSION=$(grep '"version"' CloudronManifest.json | cut -d '"' -f 4)
PACKAGE_NAME="${APP_ID}@${VERSION}.tar.gz"

echo -e "${GREEN}Building Shopify MCP Server Cloudron Package v${VERSION}${NC}"
echo "================================================"

# Check prerequisites
echo -e "\n${YELLOW}Checking prerequisites...${NC}"

if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed${NC}"
    exit 1
fi

if ! command -v cloudron &> /dev/null; then
    echo -e "${RED}Error: Cloudron CLI is not installed${NC}"
    echo "Install with: npm install -g cloudron"
    exit 1
fi

# Check for required files
echo -e "\n${YELLOW}Checking required files...${NC}"
required_files=("Dockerfile" "CloudronManifest.json" "README.md")
for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        echo -e "${RED}Error: Missing required file: $file${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓${NC} $file"
done

# Check for icon
if [ ! -f "icon.png" ]; then
    echo -e "${YELLOW}Warning: icon.png not found. Creating placeholder...${NC}"
    # Create a simple placeholder icon using ImageMagick if available
    if command -v convert &> /dev/null; then
        convert -size 256x256 xc:blue -fill white -gravity center \
                -pointsize 48 -annotate +0+0 'MCP' icon.png
        echo -e "${GREEN}✓${NC} Created placeholder icon.png"
    else
        echo -e "${RED}Please add a 256x256 PNG icon as icon.png${NC}"
        exit 1
    fi
fi

# Local testing option
if [ "$1" == "--test" ]; then
    echo -e "\n${YELLOW}Running local test with Docker Compose...${NC}"
    docker-compose down 2>/dev/null || true
    docker-compose up --build -d
    echo -e "${GREEN}Local test instance started at http://localhost:3000${NC}"
    echo "Run 'docker-compose logs -f' to view logs"
    echo "Run 'docker-compose down' to stop"
    exit 0
fi

# Build Docker image
echo -e "\n${YELLOW}Building Docker image...${NC}"
docker build -t ${APP_ID}:${VERSION} .
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Docker image built successfully"
else
    echo -e "${RED}Error: Docker build failed${NC}"
    exit 1
fi

# Test the image
echo -e "\n${YELLOW}Testing Docker image...${NC}"
docker run --rm -d --name test-mcp-server \
    -p 3000:3000 \
    -e PORT=3000 \
    ${APP_ID}:${VERSION}

sleep 5

# Check if container is running
if docker ps | grep -q test-mcp-server; then
    echo -e "${GREEN}✓${NC} Container started successfully"
    docker stop test-mcp-server
else
    echo -e "${RED}Error: Container failed to start${NC}"
    docker logs test-mcp-server 2>/dev/null || true
    exit 1
fi

# Build Cloudron package
echo -e "\n${YELLOW}Building Cloudron package...${NC}"
cloudron build
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Cloudron package built: ${PACKAGE_NAME}"
else
    echo -e "${RED}Error: Cloudron build failed${NC}"
    exit 1
fi

# Verify package
if [ -f "${PACKAGE_NAME}" ]; then
    SIZE=$(du -h "${PACKAGE_NAME}" | cut -f1)
    echo -e "\n${GREEN}Package built successfully!${NC}"
    echo "================================================"
    echo "Package: ${PACKAGE_NAME}"
    echo "Size: ${SIZE}"
    echo ""
    echo "To install on Cloudron:"
    echo "  cloudron install --location mcp.yourdomain.com --image ${PACKAGE_NAME}"
    echo ""
    echo "To update existing installation:"
    echo "  cloudron update --app mcp.yourdomain.com --image ${PACKAGE_NAME}"
else
    echo -e "${RED}Error: Package file not found${NC}"
    exit 1
fi

# Cleanup option
if [ "$2" == "--cleanup" ]; then
    echo -e "\n${YELLOW}Cleaning up Docker images...${NC}"
    docker rmi ${APP_ID}:${VERSION} 2>/dev/null || true
    echo -e "${GREEN}✓${NC} Cleanup complete"
fi

echo -e "\n${GREEN}Build complete!${NC}"