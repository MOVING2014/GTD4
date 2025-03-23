#!/bin/bash

# 定义颜色
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # 无颜色

# 应用包名
APP_PACKAGE="com.example.gtd4_without_clean_achitecture"

# 定义变量
DEVICE_ID=$1
START_APP=${2:-true} # 是否在安装后启动应用，默认为true

echo -e "${GREEN}GTD应用 Release 包安装工具${NC}"
echo -e "${GREEN}----------------------------------------${NC}"

# 检查是否传入设备ID参数
if [ -z "$DEVICE_ID" ]; then
    echo -e "${YELLOW}未指定设备ID，将自动选择第一个可用设备${NC}"
    
    # 列出所有可用设备
    echo -e "${BLUE}可用设备:${NC}"
    flutter devices
    
    # 尝试找到Android设备
    ANDROID_DEVICE=$(flutter devices | grep -E "android|Android" | head -1 | awk '{print $1}')
    
    # 如果没有找到Android设备，尝试找到iOS设备
    if [ -z "$ANDROID_DEVICE" ]; then
        IOS_DEVICE=$(flutter devices | grep -E "ios|iOS" | head -1 | awk '{print $1}')
        
        if [ -z "$IOS_DEVICE" ]; then
            echo -e "${RED}错误：未找到可用的移动设备${NC}"
            echo -e "${YELLOW}请确保至少有一台移动设备已连接${NC}"
            exit 1
        else
            DEVICE_ID=$IOS_DEVICE
            DEVICE_TYPE="ios"
        fi
    else
        DEVICE_ID=$ANDROID_DEVICE
        DEVICE_TYPE="android"
    fi
else
    # 检查指定的设备ID是否存在
    if flutter devices | grep -q "$DEVICE_ID"; then
        # 判断设备类型
        if flutter devices | grep "$DEVICE_ID" | grep -E "android|Android" -q; then
            DEVICE_TYPE="android"
        elif flutter devices | grep "$DEVICE_ID" | grep -E "ios|iOS" -q; then
            DEVICE_TYPE="ios"
        else
            echo -e "${RED}错误：无法确定设备 $DEVICE_ID 的类型${NC}"
            exit 1
        fi
    else
        echo -e "${RED}错误：设备 $DEVICE_ID 不存在${NC}"
        echo -e "${YELLOW}可用设备:${NC}"
        flutter devices
        exit 1
    fi
fi

echo -e "${GREEN}选择$DEVICE_TYPE设备: $DEVICE_ID${NC}"

# 根据设备类型进行构建和安装
if [ "$DEVICE_TYPE" = "android" ]; then
    # Android构建和安装
    echo -e "${BLUE}开始Android Release构建...${NC}"
    flutter build apk --release
    
    # 检查构建是否成功
    if [ $? -ne 0 ]; then
        echo -e "${RED}Android构建失败!${NC}"
        exit 1
    fi
    
    APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
    echo -e "${GREEN}APK构建成功: $APK_PATH${NC}"
    
    # 安装APK到设备
    echo -e "${BLUE}正在安装到Android设备 $DEVICE_ID...${NC}"
    flutter install --release -d $DEVICE_ID
    
    # 检查安装是否成功
    if [ $? -ne 0 ]; then
        echo -e "${RED}安装失败!${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ 成功安装Release版本到Android设备 $DEVICE_ID!${NC}"
    
    # 启动应用
    if [ "$START_APP" = "true" ]; then
        echo -e "${BLUE}正在启动应用...${NC}"
        adb -s $DEVICE_ID shell am start -n "$APP_PACKAGE/com.example.gtd4_without_clean_achitecture.MainActivity"
        if [ $? -ne 0 ]; then
            echo -e "${YELLOW}警告：无法自动启动应用，请手动启动${NC}"
        else
            echo -e "${GREEN}应用已成功启动!${NC}"
        fi
    fi
    
    # 显示安装信息
    echo -e "${CYAN}应用信息:${NC}"
    echo -e "${CYAN}包名: $APP_PACKAGE${NC}"
    echo -e "${CYAN}APK路径: $APK_PATH${NC}"
    echo -e "${CYAN}APK大小: $(du -h $APK_PATH | cut -f1)${NC}"
else
    # iOS构建和安装
    echo -e "${BLUE}开始iOS Release构建...${NC}"
    flutter build ios --release --no-codesign
    
    # 检查构建是否成功
    if [ $? -ne 0 ]; then
        echo -e "${RED}iOS构建失败!${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}iOS构建成功!${NC}"
    
    # 安装到iOS设备
    echo -e "${BLUE}正在安装到iOS设备 $DEVICE_ID...${NC}"
    flutter install -d $DEVICE_ID
    
    # 检查安装是否成功
    if [ $? -ne 0 ]; then
        echo -e "${RED}安装失败!${NC}"
        echo -e "${YELLOW}注意: 如果这是一个真机设备，请确保:${NC}"
        echo -e "${YELLOW}1. 开发者证书已配置${NC}"
        echo -e "${YELLOW}2. 在设备上信任了开发者证书 (设置 -> 通用 -> 设备管理)${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ 成功安装Release版本到iOS设备 $DEVICE_ID!${NC}"
    
    # iOS 无法通过命令行启动应用，提示用户手动启动
    if [ "$START_APP" = "true" ]; then
        echo -e "${YELLOW}注意：iOS设备需要手动启动应用${NC}"
    fi
    
    # 显示安装信息
    echo -e "${CYAN}应用信息:${NC}"
    echo -e "${CYAN}包名: $APP_PACKAGE${NC}"
    echo -e "${CYAN}路径: build/ios/iphoneos/Runner.app${NC}"
fi

echo -e "${GREEN}----------------------------------------${NC}"
echo -e "${GREEN}安装完成!${NC}" 