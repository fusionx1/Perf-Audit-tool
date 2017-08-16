# Perf-Audit-tool
This tool consolidates all the available tools for the performance audit, from Terminus finding the org and site url, Redis info, New Relic data, btool info, server logs, watchdogs, heaviest tables, slow query logs from master and slave db (for elite) with query digest, biggest blobs, and number of files in the files directory and how big they are. 

## Requirements
1. Install jq. jq is a lightweight and flexible command-line JSON processor. - https://stedolan.github.io/jq/
2. You need to have a working Terminus - https://pantheon.io/docs/terminus/install/
3. In order to run the biggest blob in your database, you need to install the Terminus Debugging Tools plugin - https://github.com/pantheon-systems/terminus_debugging_tools 
4. In order to run a New Relic report on the slowest performing sites, you need to install the New Relic data Terminus plugin - https://github.com/fusionx1/terminus-get-newrelic
5. Working mysql client
6. Working Yubi Key(Tested on gpg2)
7. Edit init.sh and replace line 6 with your terminus path, you may run `which terminus` on your terminal to give you the path) 
8. Setup the new relic image capture https://github.com/fusionx1/newrelic-image-capture-headless-chrome inside Perf-Audit-tool folder
9. You must have a working NodeJS and NPM - https://nodejs.org/en/download/
10. Python 2.6 or greater - https://www.python.org/downloads/
11. The pip package management tool - https://pypi.python.org/pypi/pip
12. A google account

## Installation

1. Clone this repository, go to the cloned directory and run the commands below. The output should be displayed on screen.
2. Clone https://github.com/fusionx1/newrelic-image-capture-headless-chrome inside Perf-Audit-tool folder
  ```
    $> cd Perf-Audit-tool
    $> git@github.com:fusionx1/newrelic-image-capture-headless-chrome.git nr_image_capture
  ```
3. Run this inside nr_image_capture folder
  ```
  npm install --save simple-headless-chrome
  ```  
4. Turn on the Google Slides API and Google Drive API
   You may use this guide - https://docs.google.com/document/d/1kOz7pp7dN-6ISkh-vvVFotJH3J57Avuj9GjTSfyoY0I/edit

6. Make sure shell scripts are executable

Perf-Audit-tool/init.sh and Perf-Audit-tool/nr_image_capture/newrelic_image_capture.sh
```
$ chmod +x ./init.sh
$ chmod +x ./nr_image_capture/newrelic_image_capture.sh
```

## Usage

```
$ ./init.sh [ORG_UUID][SITENAME][YUBI_KEY] 
```
