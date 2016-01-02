#!/bin/bash

cd ~/projects/finegrained/code/

IMAGE_NAME="database.kmatzen.com:5000/bkovacs_opensurfaces"

# See if we are already running the image
if [ -z "$(docker ps | grep $IMAGE_NAME)" ]; then
	echo "Docker image '$IMAGE_NAME' is not running, starting..."
	docker pull $IMAGE_NAME
	docker run -t -i -v /lib/modules:/lib/modules -v /usr/local/MATLAB/:/usr/local/MATLAB/ -v $PWD:/host --user=ubuntu --net=host --privileged $IMAGE_NAME zsh
else
	echo "Docker image '$IMAGE_NAME' is running, attaching..."
	IMAGE_ID=$(docker ps | grep $IMAGE_NAME | awk '{print $1}')
	docker attach $IMAGE_ID
fi
