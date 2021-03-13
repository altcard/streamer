#!/bin/sh
complain() {
	echo "$*"
	exit 1
}

command -v python3 > /dev/null 2>&1 || complain "No python3 installation found in PATH"

port=8000
test -z $1 || port=$1

cd "`dirname "$0"`"
pwd
python3 -m http.server $port
exit $?
