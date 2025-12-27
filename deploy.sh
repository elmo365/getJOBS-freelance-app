#!/bin/bash
# Job Workflow Completion - Deployment Script
# This script deploys all changes to Firebase and builds the Flutter app

set -e

echo "🚀 Job Workflow Completion - Deployment Script"
echo "=============================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Verify Firebase CLI
echo -e "${BLUE}Step 1: Verifying Firebase CLI...${NC}"
if ! command -v firebase &> /dev/null; then
    echo -e "${YELLOW}Firebase CLI not found. Installing...${NC}"
    npm install -g firebase-tools
fi
echo -e "${GREEN}✓ Firebase CLI verified${NC}"
echo ""

# Step 2: Verify Flutter
echo -e "${BLUE}Step 2: Verifying Flutter...${NC}"
if ! command -v flutter &> /dev/null; then
    echo -e "${YELLOW}Flutter not found. Please install Flutter SDK.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Flutter verified${NC}"
echo ""

# Step 3: Deploy Firestore Rules
echo -e "${BLUE}Step 3: Deploying Firestore Rules...${NC}"
firebase deploy --only firestore:rules
echo -e "${GREEN}✓ Firestore Rules deployed${NC}"
echo ""

# Step 4: Deploy Firestore Indexes
echo -e "${BLUE}Step 4: Deploying Firestore Indexes...${NC}"
firebase deploy --only firestore:indexes
echo -e "${GREEN}✓ Firestore Indexes deployed${NC}"
echo ""

# Step 5: Get Flutter dependencies
echo -e "${BLUE}Step 5: Getting Flutter dependencies...${NC}"
flutter pub get
echo -e "${GREEN}✓ Dependencies installed${NC}"
echo ""

# Step 6: Build Flutter app
echo -e "${BLUE}Step 6: Building Flutter app...${NC}"
echo "Select build target:"
echo "1) Android (APK)"
echo "2) iOS (IPA)"
echo "3) Web"
echo "4) All"
read -p "Enter choice (1-4): " choice

case $choice in
    1)
        echo -e "${BLUE}Building Android APK...${NC}"
        flutter build apk --release
        echo -e "${GREEN}✓ Android APK built${NC}"
        echo "Output: build/app/outputs/flutter-apk/app-release.apk"
        ;;
    2)
        echo -e "${BLUE}Building iOS IPA...${NC}"
        flutter build ios --release
        echo -e "${GREEN}✓ iOS IPA built${NC}"
        echo "Output: build/ios/iphoneos/Runner.app"
        ;;
    3)
        echo -e "${BLUE}Building Web...${NC}"
        flutter build web --release
        echo -e "${GREEN}✓ Web built${NC}"
        echo "Output: build/web"
        ;;
    4)
        echo -e "${BLUE}Building all platforms...${NC}"
        flutter build apk --release
        flutter build ios --release
        flutter build web --release
        echo -e "${GREEN}✓ All platforms built${NC}"
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac
echo ""

# Step 7: Verification
echo -e "${BLUE}Step 7: Verifying deployment...${NC}"
echo "Please verify the following:"
echo "  ✓ Firestore Rules deployed"
echo "  ✓ Firestore Indexes deployed"
echo "  ✓ Flutter app built successfully"
echo ""

# Step 8: Post-deployment checklist
echo -e "${BLUE}Step 8: Post-deployment checklist${NC}"
echo "Please test the following features:"
echo "  [ ] Job posting with multiple positions"
echo "  [ ] Hiring applicants"
echo "  [ ] Rating system (company → job seeker)"
echo "  [ ] Rating system (job seeker → company)"
echo "  [ ] Profile displays ratings"
echo "  [ ] Completed jobs screen"
echo "  [ ] Admin statistics dashboard"
echo ""

echo -e "${GREEN}🎉 Deployment Complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Upload APK/IPA to app stores"
echo "2. Test all features in production"
echo "3. Monitor Firestore for any issues"
echo "4. Collect user feedback"
echo ""
