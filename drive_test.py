#!/usr/bin/env python

from apiclient.discovery import build
from httplib2 import Http
from oauth2client import file, client, tools
from apiclient.http import MediaFileUpload
import os

CLIENT_SECRET = 'client_secret_xxxxxxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com.json'
SCOPES = 'https://www.googleapis.com/auth/drive.file'

store = file.Storage('storage.json')
creds = store.get()
if not creds or creds.invalid:
    flow = client.flow_from_clientsecrets(CLIENT_SECRET, SCOPES)
    creds = tools.run_flow(flow, store, tools.argparser.parse_args([]))

drive_service = build('drive', 'v2', http=creds.authorize(Http()))
