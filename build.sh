#!/bin/sh
set -e

### Function to do the task of the non-standard realpath utility.  This does
### not expand links, however.
expandpath() {
    (
        cd "$1" && pwd
    )
}

### Ensure >= go1.5 is installed.
go_ver_str="$(go version | cut -d ' ' -f 3)"
go_ver="${go_ver_str#go}"

oldIFS="$IFS"
IFS='.'
set -- $go_ver
IFS="$oldIFS"
go_maj="$1"
go_min="$2"

if [ "$go_maj" = "" ]
then
    printf "* Error: could not extract go version (version string: %s)\n" \
        "$go_ver_str"
    exit 1
fi

if [ "$go_min" = "" ]
then
    go_min=0
fi

if [ ! "$go_maj" -gt 1 ] && [ ! "$go_min" -ge 5 ]
then
    printf "* Error: go 1.5 or later is required (detected version: %s)\n" \
        "$go_maj"."$go_min".X
    exit 1
fi

### Create a temporary go tree in /tmp.
installdir="$(expandpath "$(dirname "$0")")"
godir="$(mktemp -d /tmp/mynewt.XXXXXXXXXX)"
mynewtdir="$godir"/src/mynewt.apache.org
repodir="$mynewtdir"/newt
newtdir="$repodir"/newt
dstfile="$installdir"/newt/newt

mkdir -p "$mynewtdir"
ln -s "$installdir" "$repodir"

### Build newt.
(
    cd "$newtdir"

    printf "Building newt.  This may take a minute...\n"
    GOPATH="$godir" GO15VENDOREXPERIMENT=1 go install

    mv "$godir"/bin/newt "$dstfile"

    printf "Successfully built executable: %s\n" "$dstfile"
)

### Delete the temporary directory.
rm -r "$godir"
