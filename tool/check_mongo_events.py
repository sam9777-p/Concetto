from pymongo import MongoClient

uri = 'mongodb://concettoapp:lS6Wa1mjNF_nZZNzcCuI1cdwDNiITEaPrM6vwBb6UeqBAfZD@f4a6506a-05dc-49cf-90c6-30e3b01ee57e.asia-south2.firestore.goog:443/concetto?loadBalanced=true&tls=true&authMechanism=SCRAM-SHA-256&retryWrites=false'
client = MongoClient(uri)
db = client['concetto']
count = db.events.count_documents({})
print(f"MongoDB events count: {count}")

# Check sample document keys
sample = db.events.find_one({})
if sample:
    print("Sample keys:", list(sample.keys()))
    print("Sample id:", sample.get('_id'), sample.get('title'))
