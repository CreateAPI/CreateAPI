#!/bin/sh

set -eo pipefail

cd ./Tests
xcodebuild clean
xcodebuild build -scheme 'GeneratedPackages' -destination "OS=15.2,name=iPhone 13"
