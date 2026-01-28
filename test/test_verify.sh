#!/bin/bash

PORT=6667
SERVER="localhost"
NUM_CLIENTS=10

echo "╔════════════════════════════════════════╗"
echo "║         Stress Test: $NUM_CLIENTS clients       ║"
echo "╚════════════════════════════════════════╝"
echo ""

for i in $(seq 1 $NUM_CLIENTS); do
    {
        echo "NICK user$i"
        sleep 0.2
        echo "USER user$i 0 * :User $i"
        sleep 0.5
        echo "JOIN #stress"
        sleep 0.5
        echo "PRIVMSG #stress :Hello from user$i!"
        sleep 2
        echo "QUIT :Bye"
    } | nc -C $SERVER $PORT > /dev/null 2>&1 &
    
    echo "Started client $i (PID: $!)"
    sleep 0.2
done

echo ""
echo "All $NUM_CLIENTS clients started!"
echo "Waiting for completion..."

sleep 5

echo ""
echo "✓ Stress test completed"
echo "Check server output for any errors"
