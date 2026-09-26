import json

with open('tool/events_data.json', encoding='utf-8') as f:
    events = json.load(f)

for e in events:
    name = e.get('coordinatorName', '')
    contact = e.get('coordinatorContact', '')
    phone = e.get('coordinatorPhone', '')
    email = e.get('coordinatorEmail', '')
    print(f"{e.get('id')}: title='{e.get('title')}' | name='{name}' | contact='{contact}' | phone='{phone}'")
