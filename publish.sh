#!/bin/bash
set -e

USERNAME=$1
VERSION=$2

if [[ -z "${USERNAME}" ]]; then
    echo "Please specify valid DockerHub username"
    exit 1
fi

docker login -u $USERNAME

IMAGE_NAME="${USERNAME}/space-engineers-dedicated-server"

if [[ -z "${USERNAME}" ]]; then
    echo "Please specify valid DockerHub username"
    exit 1
fi

docker build -t "$IMAGE_NAME" .

WINE_VERSION=$(docker run --entrypoint="" "$IMAGE_NAME" wine --version)

TAG_CURRENT="$IMAGE_NAME:$VERSION-$WINE_VERSION"
TAG_LATEST="$IMAGE_NAME:latest"

echo $TAG_CURRENT
echo $TAG_LATEST
docker tag $IMAGE_NAME $TAG_CURRENT
docker tag $IMAGE_NAME $TAG_LATEST

docker push $TAG_CURRENT
docker push $TAG_LATEST