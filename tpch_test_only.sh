#!/bin/sh

RESULTS=$1
HOST=$2
DBNAME=$3
USER=$4
PWD=$5
# delay between stats collections (iostat, vmstat, ...)
DELAY=15

# DSS queries timeout (5 minutes or something like that)
DSS_TIMEOUT=300000 # 5 minutes in seconds

# log
LOGFILE=bench.log

function benchmark_run() {

	print_log "running TPC-H benchmark"

	benchmark_dss $RESULTS

	print_log "finished TPC-H benchmark"

}

function benchmark_dss() {

	mkdir -p $RESULTS

	mkdir $RESULTS/vmstat-s $RESULTS/vmstat-d $RESULTS/explain $RESULTS/results $RESULTS/errors

	# get bgwriter stats
	psql -h $HOST -U $USER postgres -c "SELECT * FROM pg_stat_bgwriter" > $RESULTS/stats-before.log 2>> $RESULTS/stats-before.err
	psql -h $HOST -U $USER postgres -c "SELECT * FROM pg_stat_database WHERE datname = '$DBNAME'" >> $RESULTS/stats-before.log 2>> $RESULTS/stats-before.err

	vmstat -s > $RESULTS/vmstat-s-before.log 2>&1
	vmstat -d > $RESULTS/vmstat-d-before.log 2>&1

	print_log "running queries defined in TPC-H benchmark"

	for n in `seq 1 22`
	do

		q="dss/queries/$n.sql"
		qe="dss/queries/$n.explain.sql"

		if [ -f "$q" ]; then

			print_log "  running query $n"

			echo "======= query $n =======" >> $RESULTS/data.log 2>&1;

			# run explain
			psql -h $HOST -U $USER $DBNAME < $qe > $RESULTS/explain/$n 2>> $RESULTS/explain.err

			vmstat -s > $RESULTS/vmstat-s/before-$n.log 2>&1
			vmstat -d > $RESULTS/vmstat-d/before-$n.log 2>&1

			# run the query on background
			/usr/bin/time -a -f "$n = %e" -o $RESULTS/results.log psql -h $HOST -U $USER $DBNAME < $q > $RESULTS/results/$n 2> $RESULTS/errors/$n &

			# wait up to the given number of seconds, then terminate the query if still running (don't wait for too long)
			for i in `seq 0 $DSS_TIMEOUT`
			do

				# the query is still running - check the time
				if [ -d "/proc/$!" ]; then

					# the time is over, kill it with fire!
					if [ $i -eq $DSS_TIMEOUT ]; then

						print_log "    killing query $n (timeout)"

						# echo "$q : timeout" >> $RESULTS/results.log
						psql -h $HOST -U $USER postgres -c "SELECT pg_terminate_backend(procpid) FROM pg_stat_activity WHERE datname = 'tpch'" >> $RESULTS/queries.err 2>&1;

						# time to do a cleanup
						sleep 10;

						# just check how many backends are there (should be 0)
						psql -h $HOST -U $USER postgres -c "SELECT COUNT(*) AS tpch_backends FROM pg_stat_activity WHERE datname = 'tpch'" >> $RESULTS/queries.err 2>&1;

					else
						# the query is still running and we have time left, sleep another second
						sleep 1;
					fi;

				else

					# the query finished in time, do not wait anymore
					print_log "    query $n finished OK ($i seconds)"
					break;

				fi;

			done;

			vmstat -s > $RESULTS/vmstat-s/after-$n.log 2>&1
			vmstat -d > $RESULTS/vmstat-d/after-$n.log 2>&1

		fi;

	done;

	# collect stats again
	psql -h $HOST -U $USER  postgres -c "SELECT * FROM pg_stat_bgwriter" > $RESULTS/stats-after.log 2>> $RESULTS/stats-after.err
	psql -h $HOST -U $USER  postgres -c "SELECT * FROM pg_stat_database WHERE datname = '$DBNAME'" >> $RESULTS/stats-after.log 2>> $RESULTS/stats-after.err

	vmstat -s > $RESULTS/vmstat-s-after.log 2>&1
	vmstat -d > $RESULTS/vmstat-d-after.log 2>&1

}



function print_log() {

	local message=$1

	echo `date +"%Y-%m-%d %H:%M:%S"` "["`date +%s`"] : $message" >> $RESULTS/$LOGFILE;

}

mkdir $RESULTS;

export PGPASSWORD=$PWD

# run the benchmark
benchmark_run $RESULTS $DBNAME $USER
