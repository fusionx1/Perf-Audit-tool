from __future__ import print_function
import sys

from apiclient import discovery
from httplib2 import Http
from oauth2client import file, client, tools


IMG_FILE = 'no-logo.png'      # use your own!
IMG_FILE2 = 'nr-3month-sla.png'
IMG_FILE3 = 'metrics-90days.png'
TMPLFILE = 'QBR_teaser'   # use your own!
SCOPES = (
    'https://www.googleapis.com/auth/drive',
    'https://www.googleapis.com/auth/presentations',
)

store = file.Storage('storage.json')
creds = store.get()
if not creds or creds.invalid:
    flow = client.flow_from_clientsecrets('client_secret_175695254613-9gc9uakkgsl1hnul2viipfp82v5517cu.apps.googleusercontent.com.json', SCOPES)
    creds = tools.run_flow(flow, store)
HTTP = creds.authorize(Http())
DRIVE  = discovery.build('drive',  'v3', http=HTTP)
SLIDES = discovery.build('slides', 'v1', http=HTTP)
clean_clientname = sys.argv[1].replace(".", " ")
clean_sitename = sys.argv[2].replace(".", " ")

rsp = DRIVE.files().list(q="name='%s'" % TMPLFILE).execute().get('files')[0]
DATA = {'name': '%s' % clean_sitename }
print('** Copying template %r as %r' % (rsp['name'], DATA['name']))
DECK_ID = DRIVE.files().copy(body=DATA, fileId=rsp['id']).execute().get('id')

print('** Get slide objects, search for image placeholder')
slide = SLIDES.presentations().get(presentationId=DECK_ID,
        fields='slides').execute().get('slides')[0]
obj = None
for obj in slide['pageElements']:
    if obj['shape']['shapeType'] == 'RECTANGLE':
        break

print('** Searching for icon file')

rsp = DRIVE.files().list(q="name='%s'" % IMG_FILE).execute().get('files')[0]
print(' - Found image %r' % rsp['name'])
img_url = '%s&access_token=%s' % (
        DRIVE.files().get_media(fileId=rsp['id']).uri, creds.access_token)

rsp2 = DRIVE.files().list(q="name='%s'" % IMG_FILE2).execute().get('files')[0]
print(' - Found image %r' % rsp2['name'])
img_url2 = '%s&access_token=%s' % (
        DRIVE.files().get_media(fileId=rsp2['id']).uri, creds.access_token)

rsp3 = DRIVE.files().list(q="name='%s'" % IMG_FILE3).execute().get('files')[0]
print(' - Found image %r' % rsp3['name'])
img_url3 = '%s&access_token=%s' % (
        DRIVE.files().get_media(fileId=rsp3['id']).uri, creds.access_token)

print('** Replacing placeholder text and icon')



reqs = [
    {'replaceAllText': {
        'containsText': {'text': '{{CLIENTNAME}}'},
        'replaceText': clean_clientname
    }},

    {'replaceAllText': {
        'containsText': {'text': '{{SITENAME}}'},
        'replaceText': clean_sitename
    }},

    {'replaceAllShapesWithImage': {
        'imageUrl': img_url,
        'replaceMethod': 'CENTER_INSIDE',
        'containsText': {
            'text': '{{COMPANY_LOGO}}',
            'matchCase': True
        }
    }},

    {'replaceAllShapesWithImage': {
        'imageUrl': img_url2,
        'replaceMethod': 'CENTER_INSIDE',
        'containsText': {
            'text': '{{3MONTH_SLA}}',
            'matchCase': True
        }
    }},

    {'replaceAllShapesWithImage': {
        'imageUrl': img_url3,
        'replaceMethod': 'CENTER_INSIDE',
        'containsText': {
            'text': '{{90DAY_METRIC}}',
            'matchCase': True
        }
    }},
]
SLIDES.presentations().batchUpdate(body={'requests': reqs},
        presentationId=DECK_ID).execute()
print('DONE')
