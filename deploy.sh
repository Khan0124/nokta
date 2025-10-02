#!/bin/bash

# ====================================
# Nokta POS System Deployment Script
# Version: 1.0.0
# ====================================

set -e

echo "🚀 Starting Nokta POS Deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️ $1${NC}"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root!"
   exit 1
fi

# Check prerequisites
print_info "Checking prerequisites..."

# Check Flutter
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed!"
    exit 1
fi
print_success "Flutter found"

# Check Node.js
if ! command -v node &> /dev/null; then
    print_error "Node.js is not installed!"
    exit 1
fi
print_success "Node.js found"

# Check Docker
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed!"
    exit 1
fi
print_success "Docker found"

# Check Docker Compose
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed!"
    exit 1
fi
print_success "Docker Compose found"

# Step 1: Setup Flutter Dependencies
print_info "Setting up Flutter dependencies..."
dart pub global activate melos
melos bootstrap
print_success "Flutter dependencies installed"

# Step 2: Build Flutter Apps
print_info "Building Flutter applications..."

# Build POS App
echo "Building POS App..."
cd apps/pos_app
flutter build apk --release
flutter build web --release
cd ../..
print_success "POS App built"

# Build Customer App
echo "Building Customer App..."
cd apps/customer_app
flutter build apk --release
flutter build web --release
cd ../..
print_success "Customer App built"

# Build Driver App
echo "Building Driver App..."
cd apps/driver_app
flutter build apk --release
cd ../..
print_success "Driver App built"

# Build Admin Panel
echo "Building Admin Panel..."
cd apps/admin_panel
flutter build web --release
cd ../..
print_success "Admin Panel built"

# Step 3: Setup Backend
print_info "Setting up Backend..."
cd backend
npm install
cd ..
print_success "Backend dependencies installed"

# Step 4: Setup Database
print_info "Setting up Database..."
docker-compose up -d mysql
sleep 10
print_success "Database container started"

# Step 5: Setup Redis
print_info "Setting up Redis..."
docker-compose up -d redis
print_success "Redis container started"

# Step 6: Start Backend
print_info "Starting Backend API..."
docker-compose up -d backend
print_success "Backend API started"

# Step 7: Setup Nginx
print_info "Setting up Nginx..."
docker-compose up -d nginx
print_success "Nginx started"

# Step 8: Setup phpMyAdmin
print_info "Setting up phpMyAdmin..."
docker-compose up -d phpmyadmin
print_success "phpMyAdmin started"

# Wait for services to be ready
print_info "Waiting for services to be ready..."
sleep 10

# Check services status
print_info "Checking services status..."
docker-compose ps

# Print access information
echo ""
echo "======================================"
echo "🎉 Nokta POS System Deployed Successfully!"
echo "======================================"
echo ""
echo "📱 Access URLs:"
echo "   Admin Panel: http://localhost/admin"
echo "   Customer App: http://localhost"
echo "   Backend API: http://localhost:3001"
echo "   phpMyAdmin: http://localhost:8080"
echo ""
echo "📦 APK Files:"
echo "   POS App: apps/pos_app/build/app/outputs/flutter-apk/app-release.apk"
echo "   Customer App: apps/customer_app/build/app/outputs/flutter-apk/app-release.apk"
echo "   Driver App: apps/driver_app/build/app/outputs/flutter-apk/app-release.apk"
echo ""
echo "🔑 Default Credentials:"
echo "   Admin: admin / admin123"
echo "   MySQL: root / nokta_root_2024"
echo "   Redis: nokta_redis_2024"
echo ""
echo "📚 Documentation: README.md"
echo "======================================"

print_success "Deployment completed!"
