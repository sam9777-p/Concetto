import urllib.request
import urllib.error
import json

project_id = "concetto-a062e"
for rtdb in [f"https://{project_id}-default-rtdb.firebaseio.com/.json", f"https://{project_id}.firebaseio.com/.json"]:
    print(f"Testing RTDB: {rtdb}")
    try:
        req = urllib.request.Request(rtdb)
        with urllib.request.urlopen(req) as resp:
            print(f"Response: {resp.status} - {resp.read().decode('utf-8')[:100]}")
    except urllib.error.HTTPError as e:
        print(f"HTTP Error {e.code}: {e.read().decode('utf-8')[:200]}")
    except Exception as e:
        print(f"Error: {e}")
