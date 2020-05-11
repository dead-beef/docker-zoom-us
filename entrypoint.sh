#!/bin/bash
set -e

USER_UID=${USER_UID:-1000}
USER_GID=${USER_GID:-1000}

ZOOM_US_USER=zoom

echo "entrypoint"

install_zoom_us() {
  echo "Installing zoom-us-wrapper..."
  install -m 0755 /var/cache/zoom-us/zoom-us-wrapper /target/
  echo "Installing zoom-us..."
  ln -sf zoom-us-wrapper /target/zoom
}

uninstall_zoom_us() {
  echo "Uninstalling zoom-us-wrapper..."
  rm -rf /target/zoom-us-wrapper
  echo "Uninstalling zoom-us..."
  rm -rf /target/zoom
}

create_user() {
  echo "create_user"
  # create group with USER_GID
  if ! getent group ${ZOOM_US_USER} >/dev/null; then
    groupadd -f -g ${USER_GID} ${ZOOM_US_USER} >/dev/null 2>&1
  fi

  # create user with USER_UID
  if ! getent passwd ${ZOOM_US_USER} >/dev/null; then
    adduser --disabled-login --uid ${USER_UID} --gid ${USER_GID} \
      --gecos 'ZoomUs' ${ZOOM_US_USER} >/dev/null 2>&1
  fi
  chown ${ZOOM_US_USER}:${ZOOM_US_USER} -R /home/${ZOOM_US_USER}
  adduser ${ZOOM_US_USER} sudo
}

grant_access_to_input_devices() {
  echo "grant_access_to_input_devices"
  for device in /dev/video* /dev/audio* /dev/dsp* /dev/snd/*
  do
    echo "found device $device"
    if [[ -c $device ]]; then
      DEV_GID=$(stat -c %g $device)
      DEV_GROUP=$(stat -c %G $device)
      if [[ ${DEV_GROUP} == "UNKNOWN" ]]; then
        DEV_GROUP=zoomusvideo
        echo "add group '${DEV_GROUP}'"
        groupadd -g ${DEV_GID} ${DEV_GROUP}
      fi
      echo "add user to group '${DEV_GROUP}'"
      usermod -a -G ${DEV_GROUP} ${ZOOM_US_USER}
    fi
  done
}

launch_zoom_us() {
  cd /home/${ZOOM_US_USER}
  exec sudo -HEu ${ZOOM_US_USER} PULSE_SERVER=/run/pulse/native QT_GRAPHICSSYSTEM="native" $@
}

case "$1" in
  install)
    install_zoom_us
    ;;
  uninstall)
    uninstall_zoom_us
    ;;
  zoom)
    create_user
    grant_access_to_input_devices
    echo "$1"
    launch_zoom_us $@
    ;;
  *)
    exec $@
    ;;
esac
