#!/bin/bash

SUDO=
( id -Gn | grep -q docker ) || SUDO=sudo

IMAGES="$(${SUDO} docker images -q zoom)"
if [[ -n $IMAGES ]]; then
	echo 'deleting old images...' >&2
	for img in $IMAGES; do
		echo "cleaning up stopped instances of ${img}..." >&2
		for c in $(${SUDO} docker ps -a -q --filter "ancestor=${img}"); do
			${SUDO} docker rm "$c" || exit 1
		done
		${SUDO} docker rmi $img || exit 1
	done
fi

echo 'building image...' >&2
mkdir -p ${HOME}/.local/bin \
  && ${SUDO} docker build -t zoom . \
  && ${SUDO} docker run -it --rm --volume ${HOME}/.local/bin:/target zoom install
