#!/bin/bash

# 定义颜色
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # 无颜色

# 定义变量
OUTPUT_DIR="test_results/unit_tests/$(date +%Y%m%d_%H%M%S)"
COVERAGE_DIR="$OUTPUT_DIR/coverage"

# 创建输出目录
mkdir -p $COVERAGE_DIR

# 运行前准备
echo -e "${GREEN}准备测试环境...${NC}"
flutter clean
flutter pub get

# 运行所有单元测试并生成覆盖率报告
echo -e "${GREEN}运行单元测试并生成覆盖率报告...${NC}"
echo -e "${GREEN}==========================================${NC}"

# 运行单元测试并生成覆盖率报告
flutter test --coverage --coverage-path=$COVERAGE_DIR/lcov.info > $OUTPUT_DIR/test_output.txt
TEST_EXIT_CODE=$?

# 检查测试结果
if [ $TEST_EXIT_CODE -eq 0 ]; then
  echo -e "${GREEN}✓ 所有单元测试通过${NC}"
else
  echo -e "${RED}✗ 单元测试失败${NC}"
  cat $OUTPUT_DIR/test_output.txt
fi

# 如果lcov已安装，生成HTML报告
if command -v lcov > /dev/null; then
  echo -e "${GREEN}生成HTML覆盖率报告...${NC}"
  lcov --list $COVERAGE_DIR/lcov.info > $COVERAGE_DIR/coverage_summary.txt
  genhtml $COVERAGE_DIR/lcov.info -o $COVERAGE_DIR/html
  
  # 计算总覆盖率
  TOTAL_COVERAGE=$(grep -m 1 "lines" $COVERAGE_DIR/coverage_summary.txt | sed 's/.*: \(.*\)%.*/\1/')
  
  echo -e "${GREEN}代码覆盖率: $TOTAL_COVERAGE%${NC}"
  echo -e "${GREEN}HTML覆盖率报告生成在: $COVERAGE_DIR/html/index.html${NC}"
else
  echo -e "${YELLOW}未安装lcov，跳过HTML报告生成${NC}"
  echo -e "${YELLOW}可以通过 'brew install lcov' (Mac) 或 'apt-get install lcov' (Linux) 来安装lcov${NC}"
fi

# 运行特定目录的测试
run_tests_in_directory() {
  local directory=$1
  local name=$2
  
  echo -e "${GREEN}运行 $name 测试...${NC}"
  if [ -d "test/$directory" ]; then
    flutter test test/$directory > $OUTPUT_DIR/${directory}_tests.txt
    local EXIT_CODE=$?
    
    if [ $EXIT_CODE -eq 0 ]; then
      echo -e "${GREEN}✓ $name 测试通过${NC}"
    else
      echo -e "${RED}✗ $name 测试失败${NC}"
      cat $OUTPUT_DIR/${directory}_tests.txt
    fi
  else
    echo -e "${YELLOW}⚠ 未找到 $name 测试目录${NC}"
  fi
}

echo -e "${GREEN}-----------------------------------------${NC}"
run_tests_in_directory "models" "模型"
echo -e "${GREEN}-----------------------------------------${NC}"
run_tests_in_directory "providers" "状态管理"
echo -e "${GREEN}-----------------------------------------${NC}"
run_tests_in_directory "widgets" "界面组件"

echo -e "${GREEN}==========================================${NC}"

# 最终状态
if [ $TEST_EXIT_CODE -eq 0 ]; then
  echo -e "${GREEN}✓ 单元测试完成，所有测试通过${NC}"
  echo -e "${GREEN}测试结果和覆盖率报告位于: $OUTPUT_DIR${NC}"
  exit 0
else
  echo -e "${RED}✗ 单元测试完成，存在失败的测试${NC}"
  echo -e "${YELLOW}测试结果和覆盖率报告位于: $OUTPUT_DIR${NC}"
  exit 1
fi 