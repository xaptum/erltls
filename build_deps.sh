#!/usr/bin/env bash

DEPS_LOCATION=deps
DESTINATION=boringssl

if [ -f "$DEPS_LOCATION/$DESTINATION/lib/libssl.a" ]; then
    echo "BoringSSL fork already exist. delete $DEPS_LOCATION/$DESTINATION for a fresh checkout."
    exit 0
fi

REPO=http://dl.bintray.com/xaptum-eng/tar-bundles


DEBIAN_VERSION=$(cat /etc/debian_version)
if [[ $DEBIAN_VERSION =~ 9\.* ]]; then
    PKG=boringssl-441efad-stretch.tar.gz
elif [[ $DEBIAN_VERSION =~ 8\.* ]]; then
    PKG=boringssl-441efad-jessie.tar.gz
else
    PKG=boringssl-441efad-linux.tar.gz
fi

function fail_check
{
    "$@"
    local status=$?
    if [ $status -ne 0 ]; then
        echo "error with $1" >&2
        exit 1
    fi
}

function DownloadBoringSsl()
{
	echo "repo=$REPO pkg=$PKG"

	mkdir -p $DEPS_LOCATION
	pushd $DEPS_LOCATION

	if [ ! -d "$DESTINATION" ]; then
	    mkdir -p $DESTINATION
	fi

	pushd $DESTINATION

	# Download the file
	fail_check curl -sLO $REPO/$PKG

	popd
	popd
}

function BuildBoringSsl()
{
	pushd $DEPS_LOCATION
	pushd $DESTINATION

	tar -zxvf $PKG
	rm -rf $PKG

	popd
	popd
}

DownloadBoringSsl
BuildBoringSsl
