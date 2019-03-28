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
PERL=$(which perl)

_begin="\n#{{{\n"
host="Host $1\n"
hostname="\tHostName $2\n"
user="\tUser $3\n"
port="\tPort $4\n"
_end="#}}}"

new_config_block="$_begin$host$hostname$user$port$_end"

${PERL} -0777p -i -e "s/\n#{{{\n$host(\t.*\n)*#}}}/$new_config_block/g or die 1" $SSH_CONFIG_FILE

if [ "$?" -ne "0" ]; then
    echo -e $new_config_block >> $SSH_CONFIG_FILE
fi

echo -e $new_config_block
exit 0
