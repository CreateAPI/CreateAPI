#!/bin/sh

set -eo pipefail

cd ./Tests
xcodebuild build -scheme 'GeneratedPackages' -destination "OS=15.2,name=iPhone 13"  | xcpretty
