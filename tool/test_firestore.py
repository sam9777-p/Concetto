import urllib.request
import urllib.error
import json

api_key = "AIzaSyB1nybc8XznvhWlDymMg7pdEPPOCCCP_bg"
project_id = "concetto-a062e"
url = f"https://firestore.googleapis.com/v1/projects/{project_id}/databases/(default)/documents/events?key={api_key}"

print(f"Checking URL: {url}")
try:
    req = urllib.request.Request(url)
    with urllib.request.urlopen(req) as response:
        data = json.loads(response.read().decode('utf-8'))
        print("Success! Documents found:")
        docs = data.get('documents', [])
        print(f"Total documents: {len(docs)}")
        for d in docs[:5]:
            print(d.get('name'))
except urllib.error.HTTPError as e:
    print(f"HTTP Error: {e.code}")
    print(e.read().decode('utf-8'))
except Exception as e:
    print(f"Error: {e}")
