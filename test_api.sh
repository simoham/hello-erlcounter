#!/bin/bash

echo "Testing Counter HTTP API"
echo "========================"
echo ""

echo "1. Get initial counter value:"
curl -s http://localhost:8080/api/counter | jq '.'
echo ""

echo "2. Increment counter:"
curl -s -X POST http://localhost:8080/api/counter/increment | jq '.'
echo ""

echo "3. Increment again:"
curl -s -X POST http://localhost:8080/api/counter/increment | jq '.'
echo ""

echo "4. Get current value:"
curl -s http://localhost:8080/api/counter | jq '.'
echo ""

echo "5. Decrement counter:"
curl -s -X POST http://localhost:8080/api/counter/decrement | jq '.'
echo ""

echo "6. Set counter to 100:"
curl -s -X POST http://localhost:8080/api/counter/set \
  -H "Content-Type: application/json" \
  -d '{"value": 100}' | jq '.'
echo ""

echo "7. Get final value:"
curl -s http://localhost:8080/api/counter | jq '.'
echo ""

echo "8. Reset counter:"
curl -s -X POST http://localhost:8080/api/counter/reset | jq '.'
echo ""

echo "9. Verify reset:"
curl -s http://localhost:8080/api/counter | jq '.'
echo ""
