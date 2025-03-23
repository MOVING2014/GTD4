#!/bin/bash

# 定义颜色
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 无颜色

# 确保所有脚本可执行
chmod +x scripts/*.sh

# 输出标题
echo -e "${BLUE}=================================================${NC}"
echo -e "${BLUE}             Todo应用全面测试套件                  ${NC}"
echo -e "${BLUE}=================================================${NC}"

# 运行静态分析
echo -e "\n${BLUE}[1/3] 运行静态代码分析${NC}"
./scripts/run_static_analysis.sh
STATIC_ANALYSIS_EXIT_CODE=$?

# 运行单元测试
echo -e "\n${BLUE}[2/3] 运行单元测试${NC}"
./scripts/run_unit_tests.sh
UNIT_TESTS_EXIT_CODE=$?

# 检查是否有设备可用于端到端测试
DEVICE_AVAILABLE=$(flutter devices | grep -v "No devices" | head -3 | tail -1 | awk '{print $1}')

if [ -z "$DEVICE_AVAILABLE" ]; then
  echo -e "\n${YELLOW}[3/3] 跳过端到端测试 - 未检测到设备${NC}"
  echo -e "${YELLOW}请连接设备后手动运行: ./scripts/run_e2e_tests.sh${NC}"
  E2E_TESTS_EXIT_CODE=0
else
  # 运行端到端测试
  echo -e "\n${BLUE}[3/3] 运行端到端测试${NC}"
  
  # 检测设备类型
  if flutter devices | grep -E "android|Android" | grep -q "$DEVICE_AVAILABLE"; then
    echo -e "${GREEN}检测到Android设备，使用Android测试脚本${NC}"
    ./scripts/run_android_tests.sh
  elif flutter devices | grep -E "ios|iOS" | grep -q "$DEVICE_AVAILABLE"; then
    echo -e "${GREEN}检测到iOS设备，使用iOS测试脚本${NC}"
    ./scripts/run_ios_tests.sh
  else
    echo -e "${GREEN}使用通用测试脚本${NC}"
    ./scripts/run_e2e_tests.sh "$DEVICE_AVAILABLE"
  fi
  
  E2E_TESTS_EXIT_CODE=$?
fi

# 生成最终报告
echo -e "\n${BLUE}=================================================${NC}"
echo -e "${BLUE}                  测试摘要                        ${NC}"
echo -e "${BLUE}=================================================${NC}"

# 检查各阶段结果
check_result() {
  local exit_code=$1
  local name=$2
  
  if [ $exit_code -eq 0 ]; then
    echo -e "${GREEN}✓ $name 通过${NC}"
  else
    echo -e "${RED}✗ $name 失败${NC}"
  fi
}

check_result $STATIC_ANALYSIS_EXIT_CODE "静态代码分析"
check_result $UNIT_TESTS_EXIT_CODE "单元测试"
check_result $E2E_TESTS_EXIT_CODE "端到端测试"

# 最终结果
FINAL_EXIT_CODE=$((STATIC_ANALYSIS_EXIT_CODE + UNIT_TESTS_EXIT_CODE + E2E_TESTS_EXIT_CODE))

if [ $FINAL_EXIT_CODE -eq 0 ]; then
  echo -e "\n${GREEN}✅ 所有测试和检查通过!${NC}"
  exit 0
else
  echo -e "\n${RED}❌ 存在失败的测试或检查!${NC}"
  exit 1
fi 