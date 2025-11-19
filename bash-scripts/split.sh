#!/bin/bash

# Example string
IMAGE_STRING="$1"

# Split the string into deployment name and tag
DEPLOYMENT_NAME="${IMAGE_STRING%%:*}"
TAG="${IMAGE_STRING##*:}"

echo "Deployment Name: $DEPLOYMENT_NAME"
echo "Tag: $TAG"

