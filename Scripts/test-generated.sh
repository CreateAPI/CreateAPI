#!/bin/sh

set -eo pipefail

for dir in ./Tests/CreateAPITests/Expected/*/; do
    echo "Validating $dir"
    (cd $dir; swift build)
done
