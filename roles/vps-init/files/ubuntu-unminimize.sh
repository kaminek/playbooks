#!/bin/sh

set -e

if [ -f /etc/dpkg/dpkg.cfg.d/excludes ] || [ -f /etc/dpkg/dpkg.cfg.d/excludes.dpkg-tmp ]; then
    echo "Re-enabling installation of all documentation in dpkg..."
    if [ -f /etc/dpkg/dpkg.cfg.d/excludes ]; then
        mv /etc/dpkg/dpkg.cfg.d/excludes /etc/dpkg/dpkg.cfg.d/excludes.dpkg-tmp
    fi
    echo "Updating package list and upgrading packages..."
    apt-get update -qy
    # apt-get upgrade asks for confirmation before upgrading packages to let the user stop here
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" --force-yes -qy
    echo "Restoring system documentation..."
    echo "Reinstalling packages with files in /usr/share/man/ ..."
    # Reinstallation takes place in two steps because a single dpkg --verified
    # command generates very long parameter list for "xargs dpkg -S" and may go
    # over ARG_MAX. Since many packages have man pages the second download
    # handles a much smaller amount of packages.
    dpkg -S /usr/share/man/ |sed 's|, |\n|g;s|: [^:]*$||' | DEBIAN_FRONTEND=noninteractive xargs apt-get install --reinstall -y
    echo "Reinstalling packages with system documentation in /usr/share/doc/ .."
    # This step processes the packages which still have missing documentation
    dpkg --verify --verify-format rpm | awk '/..5......   \/usr\/share\/doc/ {print $2}' | sed 's|/[^/]*$||' | sort |uniq \
         | xargs dpkg -S | sed 's|, |\n|g;s|: [^:]*$||' | uniq | DEBIAN_FRONTEND=noninteractive xargs apt-get install --reinstall -y
    if dpkg --verify --verify-format rpm | awk '/..5......   \/usr\/share\/doc/ {exit 1}'; then
        echo "Documentation has been restored successfully."
        rm /etc/dpkg/dpkg.cfg.d/excludes.dpkg-tmp
    else
        echo "There are still files missing from /usr/share/doc/:"
        dpkg --verify --verify-format rpm | awk '/..5......   \/usr\/share\/doc/ {print " " $2}'
        echo "You may want to try running this script again or you can remove"
        echo "/etc/dpkg/dpkg.cfg.d/excludes.dpkg-tmp and restore the files manually."
    fi
fi

if ! dpkg-query --show --showformat='${db:Status-Status}\n' ubuntu-minimal 2> /dev/null | grep -q '^installed$'; then
    echo "Installing ubuntu-minimal package to provide the familiar Ubuntu minimal system..."
    DEBIAN_FRONTEND=noninteractive apt-get install -yq -o Dpkg::Options::="--force-confnew" ubuntu-minimal ubuntu-standard
fi

if dpkg-query --show --showformat='${db:Status-Status}\n' ubuntu-server 2> /dev/null | grep -q '^installed$' \
   && ! dpkg-query --show --showformat='${db:Status-Status}\n' landscape-common 2> /dev/null | grep -q '^installed$'; then
    echo "Installing ubuntu-server recommends..."
    DEBIAN_FRONTEND=noninteractive apt-get install -yq -o Dpkg::Options::="--force-confnew" landscape-common
fi

# unminimization succeeded, there is no need to mention it in motd
rm -f /etc/update-motd.d/60-unminimize
