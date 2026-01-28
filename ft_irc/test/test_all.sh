#!/bin/bash

PORT=6667
SERVER="localhost"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "╔════════════════════════════════════════╗"
echo "║   IRC Server Comprehensive Test Suite  ║"
echo "╔════════════════════════════════════════╗"
echo ""

# 서버가 실행 중인지 확인
if ! nc -z $SERVER $PORT 2>/dev/null; then
    echo -e "${RED}✗ Server is not running on $SERVER:$PORT${NC}"
    echo "Please start the server first: ./ircserv $PORT password"
    exit 1
fi

echo -e "${GREEN}✓ Server is running${NC}"
echo ""

# 함수: 테스트 실행
run_test() {
    local test_name=$1
    local commands=$2
    
    echo -e "${YELLOW}▶ Testing: $test_name${NC}"
    
    echo "$commands" | nc -C -w 2 $SERVER $PORT > /tmp/irc_test_output.txt 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}  ✓ Connection successful${NC}"
        cat /tmp/irc_test_output.txt | head -20
    else
        echo -e "${RED}  ✗ Connection failed${NC}"
    fi
    echo ""
}

# Test 1: 기본 등록
echo "═══════════════════════════════════════"
echo "TEST 1: Basic Registration"
echo "═══════════════════════════════════════"

COMMANDS="NICK alice
USER alice 0 * :Alice Smith
QUIT :Bye"

run_test "Basic Registration" "$COMMANDS"

# Test 2: 중복 닉네임
echo "═══════════════════════════════════════"
echo "TEST 2: Duplicate Nickname"
echo "═══════════════════════════════════════"

# 첫 번째 클라이언트 (백그라운드)
{
    echo "NICK bob"
    echo "USER bob 0 * :Bob"
    sleep 3
} | nc -C $SERVER $PORT &
BOB_PID=$!

sleep 1

# 두 번째 클라이언트 (같은 닉네임)
COMMANDS="NICK bob
USER charlie 0 * :Charlie
QUIT :Bye"

run_test "Duplicate Nickname (should fail)" "$COMMANDS"

kill $BOB_PID 2>/dev/null
sleep 1

# Test 3: JOIN 채널
echo "═══════════════════════════════════════"
echo "TEST 3: Channel JOIN"
echo "═══════════════════════════════════════"

COMMANDS="NICK dave
USER dave 0 * :Dave
JOIN #test
QUIT :Bye"

run_test "JOIN Channel" "$COMMANDS"

# Test 4: PRIVMSG
echo "═══════════════════════════════════════"
echo "TEST 4: Private Message"
echo "═══════════════════════════════════════"

# 수신자 (백그라운드)
{
    echo "NICK receiver"
    echo "USER receiver 0 * :Receiver"
    sleep 3
} | nc -C $SERVER $PORT &
RECEIVER_PID=$!

sleep 1

# 발신자
COMMANDS="NICK sender
USER sender 0 * :Sender
PRIVMSG receiver :Hello, this is a test message!
QUIT :Bye"

run_test "Send Private Message" "$COMMANDS"

kill $RECEIVER_PID 2>/dev/null
sleep 1

# Test 5: 파라미터 오류
echo "═══════════════════════════════════════"
echo "TEST 5: Error Handling"
echo "═══════════════════════════════════════"

COMMANDS="NICK
USER alice
JOIN
PRIVMSG
QUIT :Bye"

run_test "Missing Parameters (should show errors)" "$COMMANDS"

# 정리
rm -f /tmp/irc_test_output.txt

echo ""
echo "╔════════════════════════════════════════╗"
echo "║        All Tests Completed             ║"
echo "╚════════════════════════════════════════╝"
