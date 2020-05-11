#!/bin/bash

SUDO=
( id -Gn | grep -q docker ) || SUDO=sudo

mkdir -p ${HOME}/.local/bin \
  && ${SUDO} docker build -t zoom . \
  && ${SUDO} docker run -it --rm --volume ${HOME}/.local/bin:/target zoom install
