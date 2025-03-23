#!/bin/bash

# 获取Android设备ID
ANDROID_DEVICE=$(flutter devices | grep -E "android|Android" | head -1 | awk '{print $1}')

if [ -z "$ANDROID_DEVICE" ]; then
  echo "错误：未找到Android设备"
  echo "请确保已连接Android设备并启用了USB调试"
  exit 1
fi

echo "使用Android设备: $ANDROID_DEVICE"

# 设置执行权限并运行主脚本
chmod +x ./scripts/run_e2e_tests.sh
./scripts/run_e2e_tests.sh "$ANDROID_DEVICE" 