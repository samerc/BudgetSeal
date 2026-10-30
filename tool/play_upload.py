"""Upload a BudgetSeal build to Google Play through the Play Developer API.

The service-account key stays outside the repo: pass --key or set
BUDGETSEAL_PLAY_KEY (default C:/Users/Samer/Documents/keys/budgetseal-play.json).

  python tool/play_upload.py status
      Every track and its releases (read-only; the edit is thrown away).

  python tool/play_upload.py upload --aab build/app/outputs/bundle/release/app-release.aab \
      --track alpha --track "App Hive Testing" --notes-dir release_notes/0.12.1
      Uploads the bundle once, puts it on every --track given with the notes
      (one file per language: en-US.txt, ar.txt, fr-FR.txt) and sends it for
      review. A custom closed track's id is its name, as `status` prints it.
      --draft leaves it as a draft in Play Console instead.

  python tool/play_upload.py images --icon docs/store_assets/icon_512.png \
      --feature docs/store_assets/feature_graphic.png --screenshots a.png b.png …
      Replaces the en-US listing's icon, feature graphic and phone screenshots
      (the screenshots in the order given).

Needs: pip install google-api-python-client google-auth
"""

import argparse
import os
import pathlib
import sys

from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

PACKAGE = 'com.budgetseal.app'
DEFAULT_KEY = 'C:/Users/Samer/Documents/keys/budgetseal-play.json'


def service(key_path):
    creds = service_account.Credentials.from_service_account_file(
        key_path, scopes=['https://www.googleapis.com/auth/androidpublisher'])
    return build('androidpublisher', 'v3', credentials=creds, cache_discovery=False)


def status(api):
    edits = api.edits()
    edit = edits.insert(packageName=PACKAGE, body={}).execute()
    try:
        tracks = edits.tracks().list(packageName=PACKAGE, editId=edit['id']).execute()
        for track in tracks.get('tracks', []):
            print(f"{track['track']}:")
            for r in track.get('releases', []) or [{'status': '(empty)'}]:
                print(f"  {r.get('status')}  {r.get('name', '')}  codes {r.get('versionCodes', [])}")
    finally:
        edits.delete(packageName=PACKAGE, editId=edit['id']).execute()


def read_notes(notes_dir):
    notes = []
    for f in sorted(pathlib.Path(notes_dir).glob('*.txt')):
        text = f.read_text(encoding='utf-8').strip()
        if len(text) > 500:
            sys.exit(f'{f.name}: {len(text)} characters; Play allows 500')
        notes.append({'language': f.stem, 'text': text})
    if not notes:
        sys.exit(f'No *.txt release notes in {notes_dir}')
    return notes


def upload(api, aab, tracks, notes_dir, draft, name):
    notes = read_notes(notes_dir)
    edits = api.edits()
    edit = edits.insert(packageName=PACKAGE, body={}).execute()
    edit_id = edit['id']
    try:
        print(f'Uploading {aab} …')
        bundle = edits.bundles().upload(
            packageName=PACKAGE, editId=edit_id,
            media_body=MediaFileUpload(aab, mimetype='application/octet-stream',
                                       resumable=True)).execute()
        code = bundle['versionCode']
        print(f'Uploaded version code {code}')
        release = {
            'versionCodes': [str(code)],
            'status': 'draft' if draft else 'completed',
            'releaseNotes': notes,
        }
        if name:
            release['name'] = name
        for track in tracks:
            edits.tracks().update(
                packageName=PACKAGE, editId=edit_id, track=track,
                body={'track': track, 'releases': [release]}).execute()
        edits.commit(packageName=PACKAGE, editId=edit_id).execute()
    except Exception:
        edits.delete(packageName=PACKAGE, editId=edit_id).execute()
        raise
    print(f"{'Saved as a draft on' if draft else 'Sent for review on'} {', '.join(tracks)}: {code}")


def images(api, language, icon, feature, screenshots):
    """Replaces the listing's icon, feature graphic and phone screenshots."""
    edits = api.edits()
    edit_id = edits.insert(packageName=PACKAGE, body={}).execute()['id']
    try:
        def put(kind, path):
            edits.images().upload(
                packageName=PACKAGE, editId=edit_id, language=language,
                imageType=kind, media_body=MediaFileUpload(path, mimetype='image/png')).execute()
            print(f'{kind}: {pathlib.Path(path).name}')

        if icon:
            put('icon', icon)
        if feature:
            put('featureGraphic', feature)
        if screenshots:
            # Upload replaces nothing: clear the old set, then add in order.
            edits.images().deleteall(packageName=PACKAGE, editId=edit_id,
                                     language=language, imageType='phoneScreenshots').execute()
            for s in screenshots:
                put('phoneScreenshots', s)
        edits.commit(packageName=PACKAGE, editId=edit_id).execute()
    except Exception:
        edits.delete(packageName=PACKAGE, editId=edit_id).execute()
        raise
    print('Store listing images sent for review')


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--key', default=os.environ.get('BUDGETSEAL_PLAY_KEY', DEFAULT_KEY))
    sub = p.add_subparsers(dest='cmd', required=True)
    sub.add_parser('status')
    up = sub.add_parser('upload')
    up.add_argument('--aab', required=True)
    up.add_argument('--track', required=True, action='append',
                    help='Repeat to put the build on several tracks')
    up.add_argument('--notes-dir', required=True)
    up.add_argument('--name', help='Release name (Play uses the version name if empty)')
    up.add_argument('--draft', action='store_true')
    im = sub.add_parser('images')
    im.add_argument('--language', default='en-US')
    im.add_argument('--icon')
    im.add_argument('--feature')
    im.add_argument('--screenshots', nargs='+', help='Phone screenshots, in store order')
    args = p.parse_args()

    api = service(args.key)
    if args.cmd == 'status':
        status(api)
    elif args.cmd == 'images':
        images(api, args.language, args.icon, args.feature, args.screenshots)
    else:
        upload(api, args.aab, args.track, args.notes_dir, args.draft, args.name)


if __name__ == '__main__':
    main()
