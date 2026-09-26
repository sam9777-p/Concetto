import json

with open('tool/events_data.json', 'r', encoding='utf-8') as f:
    events = json.load(f)

print(f"Total events in json: {len(events)}")
for e in events:
    desc = e.get('description', '')
    title = e.get('title', '')
    if any(k in desc.lower() for k in ['timeline', 'round 1', 'round 2', 'prelims', 'finals', 'schedule', 'day 1', 'day 2']):
        print(f"--- {title} ---")
        lines = [line.strip() for line in desc.split('\n') if any(w in line.lower() for w in ['pm', 'am', 'round', 'day', 'timeline', 'stage'])]
        print('\n'.join(lines[:6]))
