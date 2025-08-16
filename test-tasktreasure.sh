#!/bin/bash
# Test script for TaskTreasure URL monitoring
# Testing locally before router deployment

echo "=== Testing TaskTreasure URL Monitoring ==="
echo "Target URL: https://tasktreasure-otp1.onrender.com"
echo "Expected interval: 600 seconds (10 minutes)"
echo ""

# Test URL accessibility
echo "🧪 Testing URL accessibility..."
if command -v curl >/dev/null 2>&1; then
    echo "Using curl to test..."
    response=$(curl -s -o /dev/null -w "%{http_code}" --max-time 30 "https://tasktreasure-otp1.onrender.com")
    echo "HTTP Response Code: $response"
    
    if [ "$response" = "200" ]; then
        echo "✅ URL is accessible (HTTP 200)"
    else
        echo "⚠️ URL returned HTTP $response"
    fi
    
    # Test response time
    echo "⏱️ Testing response time..."
    time_total=$(curl -s -o /dev/null -w "%{time_total}" --max-time 30 "https://tasktreasure-otp1.onrender.com")
    echo "Response time: ${time_total}s"
    
elif command -v wget >/dev/null 2>&1; then
    echo "Using wget to test..."
    if wget -q --spider --timeout=30 "https://tasktreasure-otp1.onrender.com"; then
        echo "✅ URL is accessible"
    else
        echo "❌ URL is not accessible"
    fi
else
    echo "❌ Neither curl nor wget available for testing"
fi

echo ""
echo "🔧 Testing Page Reloader script functions..."

# Test if our script can handle the URL
test_url="https://tasktreasure-otp1.onrender.com"
test_interval=600

# Simulate URL encoding for special characters
url_safe=$(echo "$test_url" | sed 's|[^a-zA-Z0-9]|_|g')
echo "URL safe name: $url_safe"
echo "Variable name would be: INTERVAL_$url_safe"

# Test interval calculation
minutes=$((test_interval / 60))
seconds=$((test_interval % 60))
echo "Interval display: ${test_interval}s (${minutes}min)"

echo ""
echo "✅ All tests completed"
echo "📋 Configuration for router:"
echo "  - URL: $test_url"
echo "  - Interval: $test_interval seconds"
echo "  - Timeout: 30 seconds recommended"
echo "  - Retry: 3 attempts recommended"
