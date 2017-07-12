# Perf-Audit-tool
This tool consolidates all the available tools on performance audit, from terminus finding the org and site url, redis, newrelic data, btool info, server logs, watchdogs, heaviest tables, slow query logs from master and slave db(for elite) with query digest, biggest blobs, number of files  in the files directory and how big they are 

## Requirements
1. Install jq, jq is a lightweight and flexible command-line JSON processor. - https://stedolan.github.io/jq/
2. You need to have a working Terminus - https://pantheon.io/docs/terminus/install/
3. In order to run the biggest blob in your database you need to install a terminus plugin named Terminus Debugging Tool - https://github.com/pantheon-systems/terminus_debugging_tools 
4. In order to run a report on New Relic Slowest Performing sites, you need to install the New Relic Data terminus plugin - https://github.com/fusionx1/terminus-get-newrelic

## Installation

Clone this repository, go to the clonned directory and run the commands below. The output should be displayed on screen.

```
$ chmod +x ./init.sh
```

## Usage

```
$ ./init.sh [SITENAME]
```
