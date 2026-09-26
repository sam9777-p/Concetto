import urllib.parse
from pymongo import MongoClient

username = 'concettoapp'
password = 'lS6Wa1mjNF_nZZNzcCuI1cdwDNiITEaPrM6vwBb6UeqBAfZD'
uri = f'mongodb://{urllib.parse.quote_plus(username)}:{urllib.parse.quote_plus(password)}@f4a6506a-05dc-49cf-90c6-30e3b01ee57e.asia-south2.firestore.goog:443/concetto?loadBalanced=true&tls=true&authMechanism=SCRAM-SHA-256&retryWrites=false'

client = MongoClient(uri)
db = client['concetto']
col = db['events']

res = col.update_many({}, {'$set': {'prizePool': 'TBD'}})
print(f'Successfully updated prizePool to TBD for all events!')
print(f'Matched: {res.matched_count}, Modified: {res.modified_count}')

total = col.count_documents({'prizePool': 'TBD'})
print(f'Total events with prizePool == TBD: {total}')
for doc in col.find({}, {'title': 1, 'prizePool': 1}).limit(5):
    print(f" - {doc.get('title')}: prizePool = {doc.get('prizePool')}")
