#!/bin/bash

IMAGE_NAME="database.kmatzen.com:5000/bkovacs_opensurfaces"

# See if we are already running the image
if [ -z "$(docker ps | grep $IMAGE_NAME)" ]; then
	echo "Docker image '$IMAGE_NAME' is not running, nothing to do."
	exit
else
	echo "Docker image '$IMAGE_NAME' is running, stopping it..."
	IMAGE_ID=$(docker ps | grep $IMAGE_NAME | awk '{print $1}')
	docker stop $IMAGE_ID
fi
