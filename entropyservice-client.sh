#!/bin/sh
# Copyright (c) 2014 Raimonds Cicans <ray@apollo.lv>
# Distributed under the terms of the GNU General Public License v2

ERROR_CODE=1

# Check if logger is available
if which logger >/dev/null 2>&1 ; then
  LOGGER="logger -t $0 -s -p daemon.err"
else
  LOGGER="cat"
fi

# Function to print error message and exit
die() {
  echo "$1" | $LOGGER
  exit $ERROR_CODE
}

# Check script's arguments count
if [ $# -lt 2 ] ; then
  echo "Script reads entropy data from server's /dev/random file and feeds into client's /dev/random file"
  echo
  echo "Usage:"
  echo "  $0 username host [port] [path_to_private_key_file]"
  echo
  echo "Defaults:"
  echo "  port = 22"
  echo "  path_to_private_key_file = ~/.ssh/username"
  exit $ERROR_CODE
fi

# Define ssh parameters
USER="$1"
HOST="$2"
PORT=${3-22}
PKEY=${4-"~/.ssh/$USER"}

# Check available ssh clients
if which ssh >/dev/null 2>&1 ; then
  v="$(ssh -V 2>&1)"
  if expr "$v" : '.*OpenSSH' > /dev/null; then
    # Found OpenSSH client
    SSH='ssh'
  elif expr "$v" : '.*Dropbear' > /dev/null; then
    # Found Drop Bear ssh client (dbclient renamed or symlinked to ssh)
    SSH='ssh'
  else
    die "unknown ssh client found: '$v'"
  fi
elif which dbclient >/dev/null 2>&1 ; then
  # Found Drop Bear ssh client
  SSH='dbclient'
else
  die "ssh client not found"
fi

# Check availability of rngd
if ! which rngd >/dev/null 2>&1 ; then
  die "rngd: command not found"
fi

# Check if $PORT is valid
if expr "$PORT" : '[0-9][0-9]*$' > /dev/null; then
  if [ $PORT -lt 1 ] || [ $PORT -gt 65535 ]; then
    die "$PORT: is not valid port number"
  fi
else
  die "$PORT: is not valid port number"
fi

# Check if $PKEY file exists
if [ -e "$PKEY" ]; then
  if [ ! -f "$PKEY" ]; then
    die "$PKEY: wrong key file type"
  fi
else
  die "$PKEY: key file not found"
fi

# Lets run
while true; do
  ( $SSH -T -p $PORT -i "$PKEY" "$USER@$HOST" "cat /dev/random" | rngd -f -r /dev/stdin ) 2>&1 | $LOGGER

  # Something went wrong
  #  ssh failed to connect to server
  #  ssh lost connection to server
  #  rngd thinks random stream is not random enough

  # Lets sleep for a while
  sleep 30

  # Lets try again
done
