# Perf-Audit-tool
This tool consolidates all the available tools on performance audit, from terminus finding the org, newrelic data, btool info, server logs, watchdogs, heaviest tables, slow query logs from master and slave db(for elite) with query digest, biggest blobs, number of files  in the files directory and how big 

## Installation
A valid docker install is required. 

Clone this repository, go to the clonned directory and run the commands below. The output should be displayed on screen.

```
$ chmod +x ./init.sh
```

## Usage

```
$ ./init.sh [SITENAME]
```
