#!/bin/bash
if [ -f /etc/debian_version ]; then
  aptitude install rng-tools -y
fi
if [ -f /etc/redhat-release ]; then
  yum install rng-utils
fi
mknod /etc/rdcentropyservice p
