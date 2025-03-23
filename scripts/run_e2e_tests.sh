#!/bin/bash

# 定义颜色
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 无颜色

# 定义变量
DEVICE_ID=$1
TEST_FILES=(
  "integration_test/task_flow_test.dart"
  "integration_test/app_test.dart"
)

if [ -f "integration_test/project_flow_test.dart" ]; then
  TEST_FILES+=("integration_test/project_flow_test.dart")
fi

OUTPUT_DIR="test_results/$(date +%Y%m%d_%H%M%S)"
TOTAL_TESTS=${#TEST_FILES[@]}
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# 检查设备ID参数
if [ -z "$DEVICE_ID" ]; then
  echo -e "${YELLOW}未指定设备ID，尝试使用第一个可用设备${NC}"
  
  # 查找Android设备
  ANDROID_DEVICE=$(flutter devices | grep -E "android|Android" | head -1 | awk '{print $1}')
  if [ ! -z "$ANDROID_DEVICE" ]; then
    DEVICE_ID=$ANDROID_DEVICE
    echo -e "${GREEN}使用Android设备: $DEVICE_ID${NC}"
  else
    # 查找iOS设备
    IOS_DEVICE=$(flutter devices | grep -E "ios|iOS" | head -1 | awk '{print $1}')
    if [ ! -z "$IOS_DEVICE" ]; then
      DEVICE_ID=$IOS_DEVICE
      echo -e "${GREEN}使用iOS设备: $DEVICE_ID${NC}"
    else
      # 尝试找任何设备
      DEVICE_ID=$(flutter devices | grep -v "No devices" | head -3 | tail -1 | awk '{print $1}')
      
      if [ -z "$DEVICE_ID" ]; then
        echo -e "${RED}错误：未找到可用设备${NC}"
        exit 1
      fi
      
      echo -e "${GREEN}使用设备: $DEVICE_ID${NC}"
    fi
  fi
fi

# 创建输出目录
mkdir -p $OUTPUT_DIR

# 运行前准备
echo -e "${GREEN}准备测试环境...${NC}"
flutter clean
flutter pub get

# 运行测试
echo -e "${GREEN}开始运行端到端测试...${NC}"
echo -e "${GREEN}==========================================${NC}"

for ((i=0; i<${#TEST_FILES[@]}; i++)); do
  TEST_FILE=${TEST_FILES[$i]}
  TEST_NAME=$(basename $TEST_FILE .dart)
  
  # 检查文件是否存在
  if [ ! -f "$TEST_FILE" ]; then
    echo -e "${YELLOW}[$((i+1))/$TOTAL_TESTS] 跳过 $TEST_NAME: 文件不存在${NC}"
    ((SKIPPED_TESTS++))
    continue
  fi
  
  echo -e "${GREEN}[$((i+1))/$TOTAL_TESTS] 运行 $TEST_NAME...${NC}"
  
  # 添加超时处理
  echo -e "${BLUE}测试将在2分钟后超时，以防止挂起${NC}"
  
  # 运行测试并捕获输出和退出码
  LOG_FILE="$OUTPUT_DIR/${TEST_NAME}_log.txt"
  
  # 使用timeout命令限制测试时间
  timeout 120s flutter test $TEST_FILE -d $DEVICE_ID > $LOG_FILE 2>&1
  EXIT_CODE=$?
  
  # 检查超时
  if [ $EXIT_CODE -eq 124 ]; then
    echo -e "${RED}✗ 超时: $TEST_NAME (超过2分钟)${NC}"
    echo "测试超时（2分钟）" >> $LOG_FILE
    ((FAILED_TESTS++))
  # 检查结果
  elif [ $EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✓ 通过: $TEST_NAME${NC}"
    ((PASSED_TESTS++))
  else
    echo -e "${RED}✗ 失败: $TEST_NAME (退出码: $EXIT_CODE)${NC}"
    echo -e "${YELLOW}查看日志: $LOG_FILE${NC}"
    
    # 显示错误摘要
    echo -e "${YELLOW}错误摘要:${NC}"
    grep -A 5 -B 5 "EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK" $LOG_FILE | head -20
    
    ((FAILED_TESTS++))
  fi
  
  echo -e "${GREEN}-----------------------------------------${NC}"
  
  # 在测试之间添加延迟，让设备有时间恢复
  sleep 2
done

# 生成摘要报告
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}测试摘要:${NC}"
echo -e "${GREEN}总测试: $TOTAL_TESTS${NC}"
echo -e "${GREEN}通过: $PASSED_TESTS${NC}"
if [ $FAILED_TESTS -gt 0 ]; then
  echo -e "${RED}失败: $FAILED_TESTS${NC}"
fi
if [ $SKIPPED_TESTS -gt 0 ]; then
  echo -e "${YELLOW}跳过: $SKIPPED_TESTS${NC}"
fi

echo -e "${BLUE}详细日志位于: $OUTPUT_DIR${NC}"

# 创建HTML摘要报告
HTML_REPORT="$OUTPUT_DIR/summary.html"
echo "<html><head><title>端到端测试结果</title>" > $HTML_REPORT
echo "<style>body{font-family:Arial;margin:20px}h1{color:#333}.pass{color:green}.fail{color:red}.skip{color:orange}table{border-collapse:collapse;width:100%}th,td{border:1px solid #ddd;padding:8px}th{background-color:#f2f2f2}</style>" >> $HTML_REPORT
echo "</head><body>" >> $HTML_REPORT
echo "<h1>端到端测试结果 - $(date '+%Y-%m-%d %H:%M:%S')</h1>" >> $HTML_REPORT
echo "<p>设备: $DEVICE_ID</p>" >> $HTML_REPORT
echo "<p><b>摘要:</b> 总计 $TOTAL_TESTS 测试, <span class='pass'>$PASSED_TESTS 通过</span>, <span class='fail'>$FAILED_TESTS 失败</span>, <span class='skip'>$SKIPPED_TESTS 跳过</span></p>" >> $HTML_REPORT

echo "<table><tr><th>测试</th><th>结果</th><th>详情</th></tr>" >> $HTML_REPORT

for TEST_FILE in "${TEST_FILES[@]}"; do
  TEST_NAME=$(basename $TEST_FILE .dart)
  LOG_FILE="$OUTPUT_DIR/${TEST_NAME}_log.txt"
  
  if [ ! -f "$TEST_FILE" ]; then
    echo "<tr><td>$TEST_NAME</td><td class='skip'>跳过</td><td>文件不存在</td></tr>" >> $HTML_REPORT
    continue
  fi
  
  if [ -f "$LOG_FILE" ]; then
    if grep -q "All tests passed" $LOG_FILE; then
      echo "<tr><td>$TEST_NAME</td><td class='pass'>通过</td><td><a href='./${TEST_NAME}_log.txt'>查看日志</a></td></tr>" >> $HTML_REPORT
    else
      ERROR=$(grep -A 3 "EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK" $LOG_FILE | head -4 | sed 's/</\&lt;/g' | sed 's/>/\&gt;/g')
      echo "<tr><td>$TEST_NAME</td><td class='fail'>失败</td><td><pre>$ERROR</pre><a href='./${TEST_NAME}_log.txt'>查看完整日志</a></td></tr>" >> $HTML_REPORT
    fi
  else
    echo "<tr><td>$TEST_NAME</td><td class='skip'>跳过</td><td>日志文件不存在</td></tr>" >> $HTML_REPORT
  fi
done

echo "</table></body></html>" >> $HTML_REPORT

echo -e "${BLUE}HTML摘要报告: $HTML_REPORT${NC}"

# 最终状态
if [ $FAILED_TESTS -gt 0 ]; then
  echo -e "${RED}✗ 存在失败的测试: $FAILED_TESTS${NC}"
  exit 1
elif [ $SKIPPED_TESTS -eq $TOTAL_TESTS ]; then
  echo -e "${YELLOW}⚠ 所有测试都被跳过${NC}"
  exit 2
else
  echo -e "${GREEN}✓ 所有执行的测试通过!${NC}"
  exit 0
fi 