#!/bin/bash

PORT=6667
SERVER="localhost"

echo "╔════════════════════════════════════════╗"
echo "║   Multi-Client Interactive Test        ║"
echo "╚════════════════════════════════════════╝"
echo ""
echo "This will open 3 terminal windows with IRC clients"
echo "Commands will be sent automatically, watch the output!"
echo ""
echo "Press Enter to start..."
read

# Client 1 (Alice) - 백그라운드
{
    sleep 1
    echo "NICK alice"
    sleep 0.5
    echo "USER alice 0 * :Alice"
    sleep 1
    echo "JOIN #general"
    sleep 2
    echo "PRIVMSG #general :Hello everyone!"
    sleep 2
    echo "MODE #general +t"
    sleep 2
    echo "TOPIC #general :Welcome to General Chat"
    sleep 5
    echo "QUIT :Alice leaving"
} | nc -C $SERVER $PORT > /tmp/alice.log 2>&1 &
ALICE_PID=$!

# Client 2 (Bob) - 백그라운드
{
    sleep 2
    echo "NICK bob"
    sleep 0.5
    echo "USER bob 0 * :Bob"
    sleep 1
    echo "JOIN #general"
    sleep 2
    echo "PRIVMSG #general :Hi Alice!"
    sleep 5
    echo "QUIT :Bob leaving"
} | nc -C $SERVER $PORT > /tmp/bob.log 2>&1 &
BOB_PID=$!

# Client 3 (Charlie) - 백그라운드
{
    sleep 3
    echo "NICK charlie"
    sleep 0.5
    echo "USER charlie 0 * :Charlie"
    sleep 1
    echo "JOIN #general"
    sleep 2
    echo "PRIVMSG #general :Hey guys!"
    sleep 4
    echo "QUIT :Charlie leaving"
} | nc -C $SERVER $PORT > /tmp/charlie.log 2>&1 &
CHARLIE_PID=$!

# 로그 모니터링
echo "Monitoring logs..."
echo ""

sleep 10

echo ""
echo "═══════════════════════════════════════"
echo "Alice's View:"
echo "═══════════════════════════════════════"
cat /tmp/alice.log
echo ""

echo "═══════════════════════════════════════"
echo "Bob's View:"
echo "═══════════════════════════════════════"
cat /tmp/bob.log
echo ""

echo "═══════════════════════════════════════"
echo "Charlie's View:"
echo "═══════════════════════════════════════"
cat /tmp/charlie.log
echo ""

# 정리
kill $ALICE_PID $BOB_PID $CHARLIE_PID 2>/dev/null
rm -f /tmp/alice.log /tmp/bob.log /tmp/charlie.log

echo "Test completed!"
