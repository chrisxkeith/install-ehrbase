#! /bin/bash

# DANGER !
# This script deletes a bunch of stuff, e.g., your current local repo,
# in an attempt to start with a clean slate.

# Assumes (some of these assumptions are checked in the script)
# - You have installed maven.
# - You have installed and plan to use Docker.
# - You have installed Java 25+.
# - You are running this script from the parent directory of your (to-be-created) local repo(s).
# - Your github username is in a shell variable called $GITHUB_USERNAME.
# - You are willing to wait a few minutes.
# - Install and build (without integration tests) == "real    2m39.694s"

set -x

# ------------------------------------------------------------
# Verify environment and tools
if [ -z "$GITHUB_USERNAME" ] ; then
	echo "Please set the GITHUB_USERNAME environment variable to your github username."
	echo "Example: export GITHUB_USERNAME=chrisxkeith"
	exit -663
fi
java -version
if [ $? -ne 0 ] ; then
	echo "No java install detected."
	exit -664
fi
v=`java -version 2>&1 | head -1 | sed -E 's/.* version "([0-9]+).*/\1/'`
if [ $v -lt 25 ] ; then
echo "Needs java 25, not $v"
exit -665
fi
mvn --version
if [ $? -ne 0 ] ; then
	echo "No maven install detected."
	exit -666
fi
docker --version
if [ $? -ne 0 ] ; then
	echo "No docker install detected."
	exit -667
fi
python3 --version
if [ $? -ne 0 ] ; then
	echo "No python3 install detected."
	exit -667
fi
pip --version
if [ $? -ne 0 ] ; then
	echo "No pip install detected."
	exit -667
fi

# ------------------------------------------------------------
# Build and run ehrbase.
if [ -d "ehrbase" ] ; then
	rm -rf ehrbase
	if [ $? -ne 0 ] ; then
		echo "Failed to delete local ehrbase repo."
		exit -668
	fi	
fi
git clone https://github.com/ehrbase/ehrbase.git
if [ $? -ne 0 ] ; then
	echo "Failed to clone ehrbase repo."
	exit -669
fi

cd ehrbase
docker rm -f ehrdb
	# Ignore error if container doesn't exist.
docker run --name ehrdb --network ehrbase-net -e POSTGRES_PASSWORD=postgres -d -p 5432:5432 ehrbase/ehrbase-v2-postgres:16.2
if [ $? -ne 0 ] ; then
	echo "Failed postgres docker run."
	exit -669
fi
mvn package
if [ $? -ne 0 ] ; then
	echo "Failed mvn package."
	exit -669
fi

cd ..
# ./install-ehrbase/run-integration-tests.sh
