#!/bin/bash

echo "🔧 Xcode 프로젝트에 새 파일 추가 중..."

# Xcode 프로젝트 파일 경로
PROJECT_FILE="DontGoMart.xcodeproj/project.pbxproj"

# 새로 추가할 파일들
NEW_FILES=(
    "DontGoMart/Manager/LocationManager.swift"
    "DontGoMart/Manager/FavoriteMartManager.swift"
    "DontGoMart/Manager/OperationStatusManager.swift"
    "DontGoMart/Model/MartStore.swift"
    "DontGoMart/Model/ShoppingReminder.swift"
    "DontGoMart/Screen/ShoppingListView.swift"
)

echo "📁 추가할 파일 목록:"
for file in "${NEW_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✅ $file"
    else
        echo "  ❌ $file (파일이 없습니다)"
    fi
done

echo ""
echo "⚠️  주의: 프로젝트 파일을 자동으로 수정하는 것은 위험할 수 있습니다."
echo "📝 대신 다음 방법을 사용하세요:"
echo ""
echo "1. Xcode에서 DontGoMart.xcodeproj 열기"
echo "2. Manager 폴더 우클릭 > Add Files to DontGoMart"
echo "3. 다음 파일들 선택:"
echo "   - LocationManager.swift"
echo "   - FavoriteMartManager.swift"  
echo "   - OperationStatusManager.swift"
echo ""
echo "4. Model 폴더 우클릭 > Add Files to DontGoMart"
echo "5. 다음 파일들 선택:"
echo "   - MartStore.swift"
echo "   - ShoppingReminder.swift"
echo ""
echo "6. Screen 폴더 우클릭 > Add Files to DontGoMart"
echo "7. ShoppingListView.swift 선택"
echo ""
echo "자세한 내용은 XCODE_SETUP_GUIDE.md 파일을 참조하세요."

