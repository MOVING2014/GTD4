#!/bin/bash

# 定义颜色
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # 无颜色

echo -e "${GREEN}开始代码静态分析...${NC}"
echo -e "${GREEN}==========================================${NC}"

# 运行分析
echo -e "${GREEN}运行 flutter analyze...${NC}"
flutter analyze > analyze_results.txt
ANALYZE_EXIT_CODE=$?

if [ $ANALYZE_EXIT_CODE -eq 0 ]; then
  echo -e "${GREEN}✓ 代码分析通过${NC}"
else
  echo -e "${RED}✗ 代码分析发现问题${NC}"
  cat analyze_results.txt
fi

echo -e "${GREEN}-----------------------------------------${NC}"

# 运行格式检查
echo -e "${GREEN}运行 flutter format 检查...${NC}"
FORMATTED_FILES=$(flutter format --dry-run --set-exit-if-changed .)
FORMAT_EXIT_CODE=$?

if [ $FORMAT_EXIT_CODE -eq 0 ]; then
  echo -e "${GREEN}✓ 代码格式检查通过${NC}"
else
  echo -e "${RED}✗ 以下文件需要格式化:${NC}"
  echo "$FORMATTED_FILES"
  echo -e "${YELLOW}运行 'flutter format .' 来修复格式问题${NC}"
fi

echo -e "${GREEN}-----------------------------------------${NC}"

# 检查pub依赖
echo -e "${GREEN}检查过时的依赖...${NC}"
flutter pub outdated > outdated_deps.txt
grep -q "No dependencies are outdated" outdated_deps.txt
OUTDATED_EXIT_CODE=$?

if [ $OUTDATED_EXIT_CODE -eq 0 ]; then
  echo -e "${GREEN}✓ 所有依赖都是最新的${NC}"
else
  echo -e "${YELLOW}⚠ 存在过时的依赖:${NC}"
  grep -A 100 "Dependencies" outdated_deps.txt | grep -B 100 "dev_dependencies" | grep -v "Dependencies" | grep -v "dev_dependencies"
fi

echo -e "${GREEN}==========================================${NC}"

# 最终状态
if [ $ANALYZE_EXIT_CODE -eq 0 ] && [ $FORMAT_EXIT_CODE -eq 0 ]; then
  echo -e "${GREEN}✓ 静态分析完成，代码质量良好${NC}"
  exit 0
else
  echo -e "${RED}✗ 静态分析完成，存在需要修复的问题${NC}"
  exit 1
fi 