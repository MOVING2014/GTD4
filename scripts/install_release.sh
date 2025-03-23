#!/bin/bash

# 定义颜色
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 无颜色

# 定义变量
DEVICE_ID=$1

echo -e "${GREEN}开始构建与安装 Release 版本...${NC}"

# 第1步：构建 Release 版本的 APK
echo -e "${BLUE}正在构建 Release APK...${NC}"
flutter build apk --release

# 检查构建是否成功
if [ $? -ne 0 ]; then
    echo -e "${RED}APK 构建失败!${NC}"
    exit 1
fi

echo -e "${GREEN}APK 构建成功!${NC}"
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"

# 第2步：获取第一个可用设备
echo -e "${BLUE}查找可用的 Android 设备...${NC}"

# 获取Android设备
if [ -z "$DEVICE_ID" ]; then
    DEVICE_ID=$(flutter devices | grep -E "android|Android" | head -1 | awk '{print $1}')

    if [ -z "$DEVICE_ID" ]; then
        echo -e "${RED}错误：未找到可用的 Android 设备${NC}"
        echo -e "${YELLOW}请确保至少有一台 Android 设备已连接并启用了 USB 调试功能${NC}"
        exit 1
    fi
else
    # 验证设备是否存在且是Android设备
    if ! flutter devices | grep -E "android|Android" | grep -q "$DEVICE_ID"; then
        echo -e "${RED}错误：无法找到Android设备 $DEVICE_ID${NC}"
        echo -e "${YELLOW}请确保指定的设备已连接${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}找到设备: $DEVICE_ID${NC}"

# 第3步：安装 APK 到设备
echo -e "${BLUE}正在安装 APK 到设备 $DEVICE_ID...${NC}"
flutter install --release -d $DEVICE_ID

# 检查安装是否成功
if [ $? -ne 0 ]; then
    echo -e "${RED}APK 安装失败!${NC}"
    exit 1
fi

echo -e "${GREEN}✅ 成功安装 Release 版本到设备 $DEVICE_ID!${NC}"
echo -e "${BLUE}应用路径: $APK_PATH${NC}" 