#!/bin/sh

set -eo pipefail

# NOTE: Assuming macOS. Linux is not supported yet.
# $1 == Version
# $2 == Path to binary

version="$1"
if [[ -z "$version" ]]
then
  echo "You must specify a version" 1>&2
  exit 1
fi

input_binary="$2"
if [[ ! -f "$input_binary" ]]
then
  echo "You must specify an input binary path" 1>&2
  exit 1
fi

# Reset the artifactbundle directory
bundle_name=create-api.artifactbundle
rm -rf "$bundle_name"

# Move the binary into the appropriate location
binary_path="$bundle_name/create-api-macos/bin/create-api"
mkdir -p "$(dirname "$binary_path")"
cp "$input_binary" "$binary_path"
echo "Copied binary to $binary_path"

# Write the info.json manifest
info_path="$bundle_name/info.json"
cat > "$info_path" <<-_EOT_
{
  "schemaVersion": "1.0",
  "artifacts": {
    "create-api": {
      "type": "executable",
      "version": "$version",
      "variants": [
        {
          "path": "create-api-macos/bin/create-api",
          "supportedTriples": ["x86_64-apple-macosx", "arm64-apple-macosx"]
        }
      ]
    }
  }
}
_EOT_
echo "Written manifest to $info_path"

# Compress the bundle and cleanup
echo "Compressing..."
rm -f "$bundle_name.zip"
zip -r "$bundle_name.zip" "$bundle_name"
rm -rf "$bundle_name"
echo "Done"
