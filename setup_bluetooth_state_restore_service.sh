#!/bin/sh

help()
{
    echo "Usage: ./setup_bluetooth_state_saver [ -i | --install ]
               [ -u | --uninstall ]
               [ -h | --help  ]"
    exit 2
}

if [ $(id -u) -ne 0 ]
then
    echo "This script should be run as root." > /dev/stderr
    exit 1
fi

install_bluetooth_state_saver()
{
  cat << EOF | sudo tee /usr/local/sbin/bluetooth_state_startup.sh
#!/bin/sh

set -x

echo "Checking whether bluetooth should be turned off."
if test -f "/usr/local/share/.bluetooth_off"
then
    echo "Turning bluetooth off."
    bluetooth off
else
    echo "Keeping bluetooth turned on."
fi
EOF

sudo chmod +x /usr/local/sbin/bluetooth_state_startup.sh

cat << EOF | sudo tee /usr/local/sbin/bluetooth_state_shutdown.sh
#!/bin/sh

set -x

echo "Checking whether bluetooth should be turned off on next boot."

if bluetooth | grep -q 'bluetooth = off (software)'
then
  echo "Creating file to ensure bluetooth is turned off on next boot."
  touch /usr/local/share/.bluetooth_off
else
  echo "Checking whether to remove the file to ensure bluetooth isn't turned off on next boot."
  if test -f "/usr/local/share/.bluetooth_off"
  then
    echo "Removing file to ensure bluetooth isn't turned off on next boot."
    rm /usr/local/share/.bluetooth_off
   fi
fi
EOF

sudo chmod +x /usr/local/sbin/bluetooth_state_shutdown.sh

cat << EOF | sudo tee /etc/systemd/system/bluetooth_state.service
[Unit]
Requires=bluetooth.service
After=bluetooth.service
Description=Restores the bluetooth state after shutdown.
Before=shutdown.target reboot.target

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/bluetooth_state_startup.sh
ExecStop=/usr/local/sbin/bluetooth_state_shutdown.sh
RemainAfterExit=yes

[Install]
WantedBy=bluetooth.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable bluetooth_state.service
sudo systemctl start bluetooth_state.service
}

uninstall_bluetooth_state_saver()
{
  if test -f "/usr/local/share/.bluetooth_off"
  then
    rm /usr/local/share/.bluetooth_off
  fi
  rm /usr/local/sbin/bluetooth_state_startup.sh
  rm /usr/local/sbin/bluetooth_state_shutdown.sh
  service=bluetooth_state.service
  systemctl stop $service && systemctl disable $service && rm /etc/systemd/system/$service && systemctl daemon-reload && systemctl reset-failed
}

SHORT=i,u,h
LONG=install,uninstall,help
OPTS=$(getopt -a -n bluetooth_state_saver --options $SHORT --longoptions $LONG -- "$@")

VALID_ARGUMENTS=$#

if [ "$VALID_ARGUMENTS" -eq 0 ]; then
  help
fi

eval set -- "$OPTS"

while :
do
  case "$1" in
    -i | --install )
      install_bluetooth_state_saver && exit 0
      exit 1
      ;;
    -u | --uninstall )
      uninstall_bluetooth_state_saver && exit 0
      exit 1
      ;;
    -h | --help)
      help
      ;;
    --)
      shift;
      break
      ;;
    *)
      echo "Unexpected option: $1"
      help
      ;;
  esac
done
