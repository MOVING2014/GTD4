#!/bin/bash

# 定义颜色
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 无颜色

# 获取参数
PLATFORM=$1

echo -e "${GREEN}GTD应用 Release 包构建工具${NC}"
echo -e "${BLUE}----------------------------------------${NC}"

# 如果未指定平台，显示用法说明
if [ -z "$PLATFORM" ]; then
    echo -e "${YELLOW}用法: $0 <platform>${NC}"
    echo -e "${YELLOW}支持的平台:${NC}"
    echo -e "${YELLOW}  android  - 构建Android APK和AAB${NC}"
    echo -e "${YELLOW}  ios      - 构建iOS应用${NC}"
    echo -e "${YELLOW}  web      - 构建Web应用${NC}"
    echo -e "${YELLOW}  all      - 构建所有平台${NC}"
    exit 1
fi

# 创建输出目录
OUTPUT_DIR="build/releases/$(date +%Y%m%d_%H%M%S)"
mkdir -p $OUTPUT_DIR

# 构建Android应用
build_android() {
    echo -e "${BLUE}开始构建Android Release版本...${NC}"
    
    # 构建APK
    echo -e "${BLUE}构建APK...${NC}"
    flutter build apk --release
    if [ $? -ne 0 ]; then
        echo -e "${RED}APK构建失败!${NC}"
        return 1
    fi
    
    # 复制APK到输出目录
    APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
    cp $APK_PATH "$OUTPUT_DIR/gtd_todo_$(date +%Y%m%d).apk"
    
    # 构建AAB (App Bundle)
    echo -e "${BLUE}构建AAB...${NC}"
    flutter build appbundle --release
    if [ $? -ne 0 ]; then
        echo -e "${RED}AAB构建失败!${NC}"
        return 1
    fi
    
    # 复制AAB到输出目录
    AAB_PATH="build/app/outputs/bundle/release/app-release.aab"
    cp $AAB_PATH "$OUTPUT_DIR/gtd_todo_$(date +%Y%m%d).aab"
    
    echo -e "${GREEN}Android构建完成!${NC}"
    echo -e "${BLUE}APK路径: $OUTPUT_DIR/gtd_todo_$(date +%Y%m%d).apk${NC}"
    echo -e "${BLUE}AAB路径: $OUTPUT_DIR/gtd_todo_$(date +%Y%m%d).aab${NC}"
    return 0
}

# 构建iOS应用
build_ios() {
    echo -e "${BLUE}开始构建iOS Release版本...${NC}"
    
    # 构建iOS应用
    flutter build ios --release --no-codesign
    if [ $? -ne 0 ]; then
        echo -e "${RED}iOS构建失败!${NC}"
        echo -e "${YELLOW}可能需要在Xcode中解决签名或证书问题${NC}"
        return 1
    fi
    
    echo -e "${GREEN}iOS构建完成!${NC}"
    echo -e "${YELLOW}注意: 要创建IPA文件，请在Xcode中使用Archive功能${NC}"
    echo -e "${YELLOW}提示: 打开ios/Runner.xcworkspace，然后选择Product > Archive${NC}"
    return 0
}

# 构建Web应用
build_web() {
    echo -e "${BLUE}开始构建Web Release版本...${NC}"
    
    # 构建Web应用
    flutter build web --release
    if [ $? -ne 0 ]; then
        echo -e "${RED}Web构建失败!${NC}"
        return 1
    fi
    
    # 压缩Web输出
    WEB_DIR="build/web"
    WEB_ZIP="$OUTPUT_DIR/gtd_todo_web_$(date +%Y%m%d).zip"
    echo -e "${BLUE}压缩Web文件...${NC}"
    (cd $WEB_DIR && zip -r $WEB_ZIP *)
    
    echo -e "${GREEN}Web构建完成!${NC}"
    echo -e "${BLUE}Web应用路径: build/web/${NC}"
    echo -e "${BLUE}Web压缩包: $WEB_ZIP${NC}"
    return 0
}

# 根据参数构建相应平台
case $PLATFORM in
    "android")
        build_android
        BUILD_RESULT=$?
        ;;
    "ios")
        build_ios
        BUILD_RESULT=$?
        ;;
    "web")
        build_web
        BUILD_RESULT=$?
        ;;
    "all")
        echo -e "${GREEN}构建所有平台...${NC}"
        
        # 依次构建各平台
        build_android
        ANDROID_RESULT=$?
        
        build_ios
        IOS_RESULT=$?
        
        build_web
        WEB_RESULT=$?
        
        # 汇总结果
        if [ $ANDROID_RESULT -eq 0 ] && [ $IOS_RESULT -eq 0 ] && [ $WEB_RESULT -eq 0 ]; then
            BUILD_RESULT=0
        else
            BUILD_RESULT=1
            echo -e "${YELLOW}部分平台构建失败.${NC}"
        fi
        ;;
    *)
        echo -e "${RED}错误: 不支持的平台 '$PLATFORM'${NC}"
        echo -e "${YELLOW}支持的平台: android, ios, web, all${NC}"
        exit 1
        ;;
esac

echo -e "${BLUE}----------------------------------------${NC}"

# 显示构建结果
if [ $BUILD_RESULT -eq 0 ]; then
    echo -e "${GREEN}✅ Release构建成功!${NC}"
    echo -e "${BLUE}Release文件存放在: $OUTPUT_DIR${NC}"
    exit 0
else
    echo -e "${RED}❌ Release构建存在问题，请检查上面的错误信息${NC}"
    exit 1
fi 