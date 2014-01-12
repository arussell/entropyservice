#!/bin/bash
USER="entropyservice"
SERVER="yourserver.tld"
FIFO="/etc/rdcentropyservice"

echo -ne "Starting rngd to stir external entropy into local entropy pool..."
rngd -r $FIFO --fill-watermark=90% --feed-interval=1 --rng-timeout=0 --random-step=256 &
echo "done."

echo -ne "Connecting to remote entropy pool..."
ssh $USER@$SERVER "cat /dev/random" > $FIFO &
echo "done."
