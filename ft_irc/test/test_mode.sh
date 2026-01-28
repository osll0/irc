#!/bin/bash

PORT=6667
SERVER="localhost"

echo "╔════════════════════════════════════════╗"
echo "║        MODE Command Test Suite         ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Operator (Alice)
{
    sleep 1
    echo "NICK alice"
    sleep 0.5
    echo "USER alice 0 * :Alice"
    sleep 0.5
    echo "JOIN #test"
    sleep 1
    
    echo "Testing +i (invite-only)..."
    echo "MODE #test +i"
    sleep 1
    
    echo "Testing +t (topic restricted)..."
    echo "MODE #test +t"
    sleep 1
    
    echo "Testing +k (channel key)..."
    echo "MODE #test +k secretpass"
    sleep 1
    
    echo "Testing +l (user limit)..."
    echo "MODE #test +l 5"
    sleep 1
    
    echo "Testing +o (operator)..."
    echo "MODE #test +o bob"
    sleep 2
    
    echo "Testing -i (remove invite-only)..."
    echo "MODE #test -i"
    sleep 1
    
    echo "Testing combined modes..."
    echo "MODE #test +it-k"
    sleep 2
    
    echo "QUIT :Test done"
} | nc -C $SERVER $PORT > /tmp/mode_test_alice.log 2>&1 &
ALICE_PID=$!

# Regular user (Bob)
{
    sleep 2
    echo "NICK bob"
    sleep 0.5
    echo "USER bob 0 * :Bob"
    sleep 0.5
    echo "JOIN #test"
    sleep 8
    echo "QUIT :Bye"
} | nc -C $SERVER $PORT > /tmp/mode_test_bob.log 2>&1 &
BOB_PID=$!

sleep 10

echo "═══════════════════════════════════════"
echo "Alice (Operator) Output:"
echo "═══════════════════════════════════════"
cat /tmp/mode_test_alice.log
echo ""

echo "═══════════════════════════════════════"
echo "Bob (Member) Output:"
echo "═══════════════════════════════════════"
cat /tmp/mode_test_bob.log
echo ""

kill $ALICE_PID $BOB_PID 2>/dev/null
rm -f /tmp/mode_test_alice.log /tmp/mode_test_bob.log

echo "MODE test completed!"
