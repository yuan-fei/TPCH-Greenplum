#!/bin/sh
set -e

GP_TPCH_HOME=`readlink -f .`
DSS_TEMPLATES=$GP_TPCH_HOME/dss/templates
DSS_QUERIES=$GP_TPCH_HOME/dss/queries
DSS_DATA=$GP_TPCH_HOME/dss/data
DBGEN=$GP_TPCH_HOME/tpch/dbgen

gen_queries=false
gen_data=false
SIZE_G=false

while getopts 'qd:' flag; do
  case "${flag}" in
    q) gen_queries=true ;;
    d) 
		gen_data=true
		SIZE_G="${OPTARG}" ;;
    *) error "Unexpected option ${flag}" ;;
  esac
done


function generate_data(){
	cd $DBGEN
	make
	rm -rf *.tbl
	rm -rf *.csv
	./dbgen -s $SIZE_G
	# pg recognizable format: remove ending '|'
	for i in `ls *.tbl`; do sed 's/|$//' $i > ${i/tbl/csv}; echo $i; done;
	rm -rf $DSS_DATA
	mkdir $DSS_DATA
	mv *.csv $DSS_DATA/
	rm -rf /tmp/dss-data
	ln -s $DSS_DATA /tmp/dss-data
}

function generate_queries(){
	cd $DBGEN
	rm -rf $DSS_QUERIES
	mkdir $DSS_QUERIES
	# generate test queries
	for q in `seq 1 22`
	do
	    DSS_QUERY=$DSS_TEMPLATES ./qgen $q >> $DSS_QUERIES/$q.sql
	    sed 's/^select/explain select/' $DSS_QUERIES/$q.sql > $DSS_QUERIES/$q.explain.sql
	done
}

if $gen_queries; then
	echo 'generate queries'
 	generate_queries
fi
if $gen_data; then
 	echo "generate data with scale $SIZE_G G"
 	generate_data
fi
