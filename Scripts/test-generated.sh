#!/bin/sh

// TODO: Reimplement (compile using Swift Package Manager)

#set -eo pipefail
#
#for filename in ./Tests/CreateAPITests/Resources/Expected/*.txt; do
#    cp -- "$filename" "${filename%.txt}.swift"
#done
#
#for filename in ./Tests/CreateAPITests/Resources/Expected/*.swift; do
#    swiftc $filename -o temp-bin
#    rm temp-bin
#done
#
#for filename in ./Tests/CreateAPITests/Resources/Expected/*.swift; do
#    rm "$filename"
#done
