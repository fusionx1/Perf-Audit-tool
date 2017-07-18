# Perf-Audit-tool
This tool consolidates all the available tools for the performance audit, from Terminus finding the org and site url, Redis, New Relic data, btool info, server logs, watchdogs, heaviest tables, slow query logs from master and slave db (for elite) with query digest, biggest blobs, and number of files in the files directory and how big they are. 

## Requirements
1. Install jq. jq is a lightweight and flexible command-line JSON processor. - https://stedolan.github.io/jq/
2. You need to have a working Terminus - https://pantheon.io/docs/terminus/install/
3. In order to run the biggest blob in your database, you need to install the Terminus Debugging Tools plugin - https://github.com/pantheon-systems/terminus_debugging_tools 
4. In order to run a New Relic report on the slowest performing sites, you need to install the New Relic data Terminus plugin - https://github.com/fusionx1/terminus-get-newrelic
5. Working mysql client
6. Working Yubi Key(Tested on gpg2)

## Installation

Clone this repository, go to the cloned directory and run the commands below. The output should be displayed on screen.

```
$ chmod +x ./init.sh
```

## Usage

```
$ ./init.sh [ORG_UUID][SITENAME]
```
