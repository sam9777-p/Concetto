import sys
import json
import urllib.parse
from pymongo import MongoClient
from pymongo.errors import ConnectionFailure, OperationFailure

def main():
    if len(sys.argv) >= 3:
        username = sys.argv[1]
        password = sys.argv[2]
    else:
        print("=== Concetto MongoDB Enterprise Uploader ===")
        username = input("Enter SCRAM Username: ").strip()
        password = input("Enter SCRAM Password: ").strip()

    if not username or not password:
        print("[!] Error: Username and password cannot be empty.")
        print("Usage: python tool/upload_to_mongodb.py <username> <password>")
        sys.exit(1)

    # URL encode credentials in case of special characters
    enc_user = urllib.parse.quote_plus(username)
    enc_pass = urllib.parse.quote_plus(password)

    uri = (
        f"mongodb://{enc_user}:{enc_pass}@f4a6506a-05dc-49cf-90c6-30e3b01ee57e.asia-south2.firestore.goog:443"
        f"/concetto?loadBalanced=true&tls=true&authMechanism=SCRAM-SHA-256&retryWrites=false"
    )

    print(f"\n[1/3] Connecting to Firestore Enterprise (MongoDB API)...")
    print(f"Host: f4a6506a-05dc-49cf-90c6-30e3b01ee57e.asia-south2.firestore.goog:443")
    print(f"Database: concetto")
    print(f"User: {username}\n")

    try:
        client = MongoClient(uri, serverSelectionTimeoutMS=10000)
        db = client["concetto"]
        events_col = db["events"]

        # Test connection with a ping
        print("[2/3] Verifying SCRAM authentication...")
        db.command("ping")
        print("-> Connection & Authentication SUCCESSFUL!\n")

        # Load events from JSON
        with open("tool/events_data.json", "r", encoding="utf-8") as f:
            events = json.load(f)

        print(f"[3/3] Uploading {len(events)} events to collection 'events'...")
        inserted_count = 0
        for ev in events:
            doc_id = ev.get("_id") or ev.get("id")
            # Upsert into collection
            events_col.replace_one({"_id": doc_id}, ev, upsert=True)
            inserted_count += 1

        total_in_db = events_col.count_documents({})
        print(f"\n========================================================")
        print(f"[SUCCESS] Uploaded {inserted_count} events to database 'concetto'!")
        print(f"Total documents now in 'events' collection: {total_in_db}")
        print(f"========================================================")

    except OperationFailure as e:
        print(f"\n[!] Authentication or Permission Error: {e.details}")
        print("Please verify that:")
        print(" 1. The user was created under SCRAM credentials in Firebase Console.")
        print(" 2. The username and password match exactly.")
        print(" 3. The user has readWrite role on 'concetto' database.")
    except ConnectionFailure as e:
        print(f"\n[!] Connection Failed: {e}")
    except Exception as e:
        print(f"\n[!] Unexpected Error: {e}")

if __name__ == "__main__":
    main()
