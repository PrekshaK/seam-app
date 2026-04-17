#!/bin/bash

# List available iOS simulators

echo "📱 Available iOS Simulators:"
echo ""

xcrun simctl list devices available | grep iPhone | grep -o '"iPhone[^"]*"' | tr -d '"' | sort -u

echo ""
echo "Usage: ./run.sh \"iPhone 16 Pro\""