#!/bin/bash
# original https://github.com/arussell/entropyservice

USER="entropyservice"
SERVER="yourserver.tld"
FIFO="/etc/rdcentropyservice"

# check for and correct $FIFO as a FIFO pipe

if ! [ -p "$FIFO" ]; then
        echo "$FIFO is not a FIFO or is missing"
        if [ -e "$FIFO" ] ; then
                rm "$FIFO"
        fi
        mknod "$FIFO" p && echo "mknod $FIFO created as a FIFO"
else
        echo "$FIFO exists and is a FIFO"
fi

# start filling $FIFO so it's not depleted when we stir entropy into /dev/random using rngd

echo -ne "Connecting to remote entropy pool..."
ssh  $USER@$SERVER "cat /dev/random" > $FIFO &
echo  "done."

echo -ne "Starting rngd to stir external entropy into local entropy pool..."
rngd -r $FIFO --fill-watermark=90% --feed-interval=1 --rng-timeout=0 --random-step=256 &
echo  "done."
