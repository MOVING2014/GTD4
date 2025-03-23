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
PRESERVE_DATA=${3:-true} # 是否保留应用数据，默认为true

# 检查是否安装了adb命令
ADB_PATH=$(which adb 2>/dev/null)
if [ -z "$ADB_PATH" ]; then
    echo -e "${YELLOW}警告: 未找到 adb 命令，将使用 flutter install 命令安装${NC}"
    echo -e "${YELLOW}注意: 这将会卸载应用并清除数据${NC}"
    echo -e "${YELLOW}如需保留数据，请先安装 Android Platform Tools:${NC}"
    echo -e "${YELLOW}  brew install --cask android-platform-tools${NC}"
    USE_ADB=false
else
    echo -e "${GREEN}找到 adb 命令: $ADB_PATH${NC}"
    USE_ADB=true
fi

echo -e "${GREEN}GTD应用 Release 包安装工具${NC}"
echo -e "${GREEN}----------------------------------------${NC}"

# 检查是否传入设备ID参数
if [ -z "$DEVICE_ID" ]; then
    echo -e "${YELLOW}未指定设备ID，将自动选择第一个可用设备${NC}"
    
    if [ "$USE_ADB" = true ]; then
        # 使用adb命令获取设备列表
        echo -e "${BLUE}adb可用设备:${NC}"
        adb devices
        
        # 从adb devices输出中获取第一个设备ID
        DEVICE_ID=$(adb devices | grep -v "List" | grep "device" | head -1 | awk '{print $1}')
        
        if [ -z "$DEVICE_ID" ]; then
            echo -e "${RED}错误：未找到可用的Android设备${NC}"
            echo -e "${YELLOW}尝试使用Flutter检测设备...${NC}"
            USE_ADB_DEVICE=false
        else
            echo -e "${BLUE}使用Android设备: $DEVICE_ID${NC}"
            DEVICE_TYPE="android"
            USE_ADB_DEVICE=true
        fi
    fi
    
    # 如果没有找到adb设备，则使用Flutter检测
    if [ "$USE_ADB" = false ] || [ "$USE_ADB_DEVICE" = false ]; then
        # 列出所有Flutter可用设备
        echo -e "${BLUE}Flutter可用设备:${NC}"
        flutter devices
        
        # 尝试找到Android设备
        ANDROID_DEVICE_INFO=$(flutter devices | grep -E "android|Android" | head -1)
        
        # 如果没有找到Android设备，尝试找到iOS设备
        if [ -z "$ANDROID_DEVICE_INFO" ]; then
            IOS_DEVICE_INFO=$(flutter devices | grep -E "ios|iOS" | head -1)
            
            if [ -z "$IOS_DEVICE_INFO" ]; then
                echo -e "${RED}错误：未找到可用的移动设备${NC}"
                echo -e "${YELLOW}请确保至少有一台移动设备已连接${NC}"
                exit 1
            else
                # 使用Flutter设备ID
                FLUTTER_DEVICE_ID=$(echo "$IOS_DEVICE_INFO" | awk '{print $1}')
                DEVICE_ID=$FLUTTER_DEVICE_ID
                DEVICE_TYPE="ios"
                USE_ADB_DEVICE=false
            fi
        else
            # 使用Flutter设备ID
            FLUTTER_DEVICE_ID=$(echo "$ANDROID_DEVICE_INFO" | awk '{print $1}')
            DEVICE_ID=$FLUTTER_DEVICE_ID
            DEVICE_TYPE="android"
            USE_ADB_DEVICE=false
        fi
    fi
else
    # 用户指定了设备ID，需要判断是adb设备ID还是Flutter设备ID
    if [ "$USE_ADB" = true ] && adb devices | grep -q "$DEVICE_ID"; then
        echo -e "${BLUE}使用指定的adb设备ID: $DEVICE_ID${NC}"
        DEVICE_TYPE="android"
        USE_ADB_DEVICE=true
    else
        # 检查是否是Flutter设备ID
        if flutter devices | grep -q "$DEVICE_ID"; then
            DEVICE_INFO=$(flutter devices | grep "$DEVICE_ID")
            
            # 判断设备类型
            if echo "$DEVICE_INFO" | grep -E "android|Android" -q; then
                DEVICE_TYPE="android"
                
                # 如果可以使用adb，尝试找到对应的adb设备ID
                if [ "$USE_ADB" = true ]; then
                    # 查找可能的adb设备ID
                    ADB_DEVICE_ID=$(adb devices | grep -v "List" | grep "device" | head -1 | awk '{print $1}')
                    
                    if [ -n "$ADB_DEVICE_ID" ]; then
                        echo -e "${BLUE}发现对应的adb设备ID: $ADB_DEVICE_ID${NC}"
                        DEVICE_ID=$ADB_DEVICE_ID
                        USE_ADB_DEVICE=true
                    else
                        USE_ADB_DEVICE=false
                    fi
                else
                    USE_ADB_DEVICE=false
                fi
            elif echo "$DEVICE_INFO" | grep -E "ios|iOS" -q; then
                DEVICE_TYPE="ios"
                USE_ADB_DEVICE=false
            else
                echo -e "${RED}错误：无法确定设备 $DEVICE_ID 的类型${NC}"
                exit 1
            fi
        else
            echo -e "${RED}错误：设备 $DEVICE_ID 不存在${NC}"
            echo -e "${YELLOW}可用设备:${NC}"
            flutter devices
            
            if [ "$USE_ADB" = true ]; then
                echo -e "${YELLOW}adb设备:${NC}"
                adb devices
            fi
            
            exit 1
        fi
    fi
fi

echo -e "${GREEN}选择设备: $DEVICE_ID (类型: $DEVICE_TYPE)${NC}"

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
    
    # 根据是否能使用adb以及是否需要保留数据来决定安装方式
    if [ "$USE_ADB_DEVICE" = true ] && [ "$PRESERVE_DATA" = "true" ]; then
        echo -e "${BLUE}使用adb进行替换安装，保留应用数据...${NC}"
        adb -s "$DEVICE_ID" install -r "$APK_PATH"
    else
        if [ "$PRESERVE_DATA" = "true" ]; then
            echo -e "${YELLOW}警告: 无法使用adb进行替换安装，将使用Flutter安装方式${NC}"
            echo -e "${YELLOW}注意: 这可能会清除应用数据${NC}"
        fi
        
        if [ "$USE_ADB_DEVICE" = true ]; then
            # 如果是adb设备ID但不需要保留数据，或者不能保留数据
            adb -s "$DEVICE_ID" install "$APK_PATH"
        else
            # 如果是Flutter设备ID
            flutter install --release -d "$DEVICE_ID"
        fi
    fi
    
    # 检查安装是否成功
    if [ $? -ne 0 ]; then
        echo -e "${RED}安装失败!${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ 成功安装Release版本到Android设备 $DEVICE_ID!${NC}"
    
    # 启动应用
    if [ "$START_APP" = "true" ]; then
        echo -e "${BLUE}正在启动应用...${NC}"
        if [ "$USE_ADB_DEVICE" = true ]; then
            echo -e "${BLUE}使用adb启动应用...${NC}"
            adb -s "$DEVICE_ID" shell am start -n "$APP_PACKAGE/com.example.gtd4_without_clean_achitecture.MainActivity"
        else
            echo -e "${BLUE}使用Flutter启动应用...${NC}"
            flutter run -d "$DEVICE_ID" --release --use-application-binary="$APK_PATH"
        fi
        
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
    
    # 对于iOS，目前无法通过命令行方式保留数据安装
    if [ "$PRESERVE_DATA" = "true" ]; then
        echo -e "${YELLOW}注意: iOS设备无法通过命令行保留数据安装${NC}"
        echo -e "${YELLOW}建议使用Xcode进行安装，可以选择保留数据${NC}"
    fi
    
    flutter install -d "$DEVICE_ID"
    
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