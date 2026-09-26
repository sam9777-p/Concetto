from pymongo import MongoClient

uri = 'mongodb://concettoapp:lS6Wa1mjNF_nZZNzcCuI1cdwDNiITEaPrM6vwBb6UeqBAfZD@f4a6506a-05dc-49cf-90c6-30e3b01ee57e.asia-south2.firestore.goog:443/concetto?loadBalanced=true&tls=true&authMechanism=SCRAM-SHA-256&retryWrites=false'
client = MongoClient(uri)
db = client['concetto']
events = list(db.events.find({'rulebookUrl': {'$ne': ''}}))

for e in events:
    print(f"{e.get('id')}: {e.get('title')} -> {e.get('rulebookUrl')}")
