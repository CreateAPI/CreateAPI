#!/bin/sh

set -eo pipefail

cd ./Tests
xcodebuild clean
xcodebuild build -scheme 'GeneratedPackages' -destination "generic/platform=iOS Simulator"
