TPC-H Greenplum benchmark
==========================
This repository contains a simple implementation that runs a TPC-H-like
benchmark with a PostgreSQL database. It builds on the official TPC-H
benchmark available at http://tpc.org/tpch/default.asp (uses just the
dbgen a qgen parts).


Preparing dbgen and qgen
------------------------

    cd tpch/dbgen
    make

Now you should have `dbgen` and
`qgen` tools that generate data and queries.


preparing data and queries
---------------
Generate 10G test data

    $ ./benchmark_prepare -d 10

Generate queries

    $ ./benchmark_prepare -q

Importing data and Running the benchmark
---------------------

    $ ./benchmark_test.sh results host dbname user_name password

Running the benchmark only
---------------------

    $ ./tpch_test_only.sh results host dbname user_name password

and wait until the benchmark.


Processing the results
----------------------
All the results are written into the output directory (first parameter). To get
useful results (timing of each query, various statistics), you can use script
process.php. It expects two parameters - input dir (with data collected by the
tpch.sh script) and output file (in CSV format). For example like this:

    $ php process.php ./results output.csv

This should give you nicely formatted CSV file.