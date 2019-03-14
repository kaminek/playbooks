#!/usr/bin/env bash

# Generate a blob of ssh client config for the host
# The block of config should be in this layout:

## {{{ HOSTNAME
## ... the configuration
## }}}

if [[ $# -ne 4 ]]; then
  echo "unvalid arguments: ${0##*/} HOST HOSTNAME USER PORT" 1>&2
  exit 1
fi

SSH_CONFIG_FILE="$HOME/.ssh/config"
SED=$(which sed)

if [[ $(uname -s) -eq "Darwin" ]]; then
  SED=$(which gsed)
elif [[ $(uname -s) == "Linux" ]]; then
  SED=$(which sed)
fi

# remove the host config if it exists
# ${SED} -i "/^#{{{ $1/,/^#}}}/d" $SSH_CONFIG_FILE

_begin="\n#{{{\n"
host="Host $1\n"
hostname="\tHostName $2\n"
user="\tUser $3\n"
port="\tPort $4\n"
_end="#}}}"

config_block="$_begin$host$hostname$user$port$_end"
# ${SED} "/#{{{ $1.*/ {N; s/#{{{ $1.*}}}/$config_block/g}" filename
echo -e $config_block
echo -e $config_block >> $SSH_CONFIG_FILE
