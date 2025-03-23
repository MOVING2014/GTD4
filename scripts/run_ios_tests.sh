#!/bin/bash

# 获取iOS设备ID
IOS_DEVICE=$(flutter devices | grep -E "ios|iOS" | head -1 | awk '{print $1}')

if [ -z "$IOS_DEVICE" ]; then
  echo "错误：未找到iOS设备"
  echo "请确保已连接iOS设备并已信任此电脑"
  exit 1
fi

echo "使用iOS设备: $IOS_DEVICE"

# 设置执行权限并运行主脚本
chmod +x ./scripts/run_e2e_tests.sh
./scripts/run_e2e_tests.sh "$IOS_DEVICE" 