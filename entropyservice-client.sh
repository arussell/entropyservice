#!/bin/bash
USER="entropyservice"
SERVER="yourserver.tld"
FIFO="/etc/rdcentropyservice"
LOW_WATERMARK=3072
TOPUP_FREQUENCY=3

echo -ne "Starting rngd to stir external entropy into local entropy pool..."
rngd -r $FIFO -W $LOW_WATERMARK -t $TOPUP_FREQUENCY &
echo "done."

echo -ne "Connecting to remote entropy pool..."
ssh $USER@$SERVER "cat /dev/random" > $FIFO &
echo "done."
