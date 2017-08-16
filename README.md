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
4. Turn on the Google Slides API

  a. Use this wizard to create or select a project in the Google Developers Console and automatically turn on the API. Click Continue, then Go to credentials.
  
  b. On the Add credentials to your project page, click the Cancel button.
  
  c. At the top of the page, select the OAuth consent screen tab. Select an Email address, enter a Product name if not already set, and click the Save button.
  
  d. Select the Credentials tab, click the Create credentials button and select OAuth client ID.
  
  e. Select the application type Other, enter the name "Google Slides API Quickstart", and click the Create button.

  f. Click OK to dismiss the resulting dialog.
  
  g. Click the file_download (Download JSON) button to the right of the client ID.
  
  h. Move this file to your working directory and rename it client_secret.json.
  
 5. Install the Google Client Library by running the following command to install the library using pip:
 
 ```
 pip install --upgrade google-api-python-client
 
 ```
 6. Make sure the shell script is executable

```
$ chmod +x ./init.sh
```

## Usage

```
$ ./init.sh [ORG_UUID][SITENAME]
```
