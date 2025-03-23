#!/bin/bash

# 定义颜色
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 无颜色

echo -e "${GREEN}开始构建与安装 iOS Release 版本...${NC}"

# 第1步：查找可用的 iOS 设备
echo -e "${BLUE}查找可用的 iOS 设备...${NC}"

# 获取iOS设备
DEVICE_ID=$(flutter devices | grep -E "ios|iOS" | head -1 | awk '{print $1}')

if [ -z "$DEVICE_ID" ]; then
    echo -e "${RED}错误：未找到可用的 iOS 设备${NC}"
    echo -e "${YELLOW}请确保至少有一台 iPhone 或 iPad 已连接${NC}"
    exit 1
fi

echo -e "${GREEN}找到设备: $DEVICE_ID${NC}"

# 第2步：构建并安装到设备
echo -e "${BLUE}正在构建并安装到设备 $DEVICE_ID...${NC}"
echo -e "${YELLOW}注意：此过程可能需要几分钟，并且可能需要在设备上信任开发者证书${NC}"

flutter build ios --release --no-codesign
if [ $? -ne 0 ]; then
    echo -e "${RED}iOS 构建失败!${NC}"
    exit 1
fi

# 安装到设备
flutter install -d $DEVICE_ID

# 检查安装是否成功
if [ $? -ne 0 ]; then
    echo -e "${RED}安装失败!${NC}"
    echo -e "${YELLOW}可能需要在Xcode中手动构建并运行到设备上${NC}"
    echo -e "${YELLOW}提示: 打开ios/Runner.xcworkspace，选择设备，然后构建运行${NC}"
    exit 1
fi

echo -e "${GREEN}✅ 成功安装 Release 版本到 iOS 设备 $DEVICE_ID!${NC}"
echo -e "${YELLOW}注意：如果这是首次安装，你可能需要在设备上进入:${NC}"
echo -e "${YELLOW}设置 -> 通用 -> 设备管理，并信任开发者证书${NC}" 