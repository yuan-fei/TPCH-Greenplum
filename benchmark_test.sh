RESULTS=$1
HOST=$2
DBNAME=$3
USER=$4
PWD=$5

# benchmark testing
./tpch.sh $RESULTS $HOST $DBNAME $USER $PWD
# format result
php process.php $RESULTS $RESULTS/output.csv