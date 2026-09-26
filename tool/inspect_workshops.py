import json

with open('tool/events_data.json', 'r', encoding='utf-8') as f:
    events = json.load(f)

print(f"Total events in events_data.json: {len(events)}")
for e in events:
    cat = e.get('category', '')
    title = e.get('title', '')
    eid = e.get('id', '')
    if 'workshop' in cat.lower() or 'workshop' in eid.lower() or 'workshop' in title.lower():
        print(f"ID: {eid}")
        print(f"  Title: {title}")
        print(f"  Category: {cat}")
        print(f"  PrizePool: {e.get('prizePool')}")
        print(f"  RulebookUrl: {e.get('rulebookUrl')}")
        print(f"  PosterUrl: {e.get('posterUrl')}")
        print(f"  TeamSize: {e.get('teamSize')}")
        print(f"  MinTeamSize: {e.get('minTeamSize')}, MaxTeamSize: {e.get('maxTeamSize')}, OpenReg: {e.get('isOpenRegistration')}")
