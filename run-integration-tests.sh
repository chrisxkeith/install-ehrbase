#! /bin/bash

# DANGER !
# This script deletes your current local integration-tests repo,
# in an attempt to start with a clean slate.

set -x

# ------------------------------------------------------------
# Build and run integration tests.

cd ehrbase
if [ $? -ne 0 ] ; then
    echo "No ehrbase directory found. Please run this script from the parent directory of your local repo(s)."
    exit -670
fi	
docker rm -f ehrdb
	# Ignore error if container doesn't exist.
docker run --name ehrdb --network ehrbase-net -e POSTGRES_PASSWORD=postgres -d -p 5432:5432 ehrbase/ehrbase-v2-postgres:16.2
if [ $? -ne 0 ] ; then
	echo "Failed postgres docker run."
	exit -669
fi

# TODO: Check if ehrbase server is running. If so, kill it before starting a new one.
# ck@2018-ck-nuc:~/Documents/github$ ps -aux | grep java
# ck         22715  2.7  1.7 12279920 559548 pts/0 Sl   16:13   1:04 java -jar application/target/ehrbase.jar

java -jar application/target/ehrbase.jar 2>&1 | tee ehrbase.log &
sleep 20 # TODO? Check if server is up instead of sleeping.
cd ..
if [ -d "integration-tests" ] ; then
	rm -rf integration-tests
	if [ $? -ne 0 ] ; then
		echo "Failed to delete local integration-tests repo."
		exit -670
	fi	
fi
git clone https://github.com/ehrbase/integration-tests.git
if [ $? -ne 0 ] ; then
	echo "Failed to clone integration-tests repo."
	exit -671
fi
cd integration-tests/tests
sed -i 's/RESTinstance == 1.8.0/RESTinstance/g' requirements.txt
if [ $? -ne 0 ] ; then
	echo "Failed to sed -i 's/RESTinstance == 1.8.0/RESTinstance/g' requirements.txt"
	exit -672
fi
pip install -r ./requirements.txt
if [ $? -ne 0 ] ; then
	echo "Failed to pip install -r requirements.txt"
	exit -673
fi
sed -i 's/-noncritical/-skiponfailure/g' run_local_tests.sh
if [ $? -ne 0 ] ; then
	echo "Failed to sed -i 's/RESTinstance == 1.8.0/RESTinstance/g' run_local_tests.sh"
	exit -672
fi
chmod a+x ./run_local_tests.sh
./run_local_tests.sh
