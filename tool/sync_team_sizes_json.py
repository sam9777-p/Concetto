import json
import re

with open('tool/events_data.json', 'r', encoding='utf-8') as f:
    events = json.load(f)

print(f"Total events in JSON: {len(events)}")

for e in events:
    ts = e.get('teamSize', '')
    cat = e.get('category', '')
    is_stage = e.get('isStageExperience', False)
    
    # Defaults
    min_size = 1
    max_size = 1
    is_open = False
    
    if is_stage or 'stage' in cat.lower() or 'workshop' in cat.lower() or 'open' in ts.lower() or 'individual' in ts.lower() or not ts:
        is_open = True
        min_size = 1
        max_size = 1
        computed_ts = 'Open Registration' if not is_stage else 'Open Showcase'
    else:
        # Check range pattern: "1 - 4 Members", "2-3", "3 - 5"
        range_m = re.search(r'(\d+)\s*[-–]\s*(\d+)', ts)
        single_m = re.search(r'(\d+)', ts)
        if range_m:
            min_size = int(range_m.group(1))
            max_size = int(range_m.group(2))
            computed_ts = f"{min_size} - {max_size} Members"
        elif single_m:
            min_size = int(single_m.group(1))
            max_size = min_size
            computed_ts = "Solo (1 Member)" if min_size == 1 else f"{min_size} Members"
        else:
            is_open = True
            computed_ts = 'Open Registration'

    e['minTeamSize'] = min_size
    e['maxTeamSize'] = max_size
    e['isOpenRegistration'] = is_open
    e['teamSize'] = computed_ts
    
    # Also clean prize pool for workshops
    if 'workshop' in cat.lower() or 'workshop' in e.get('id', '').lower():
        e['prizePool'] = ''
        e['rulebookUrl'] = ''
        if 'bio' in e.get('id', '').lower() or 'cancer' in e.get('title', '').lower():
            e['posterUrl'] = 'https://www.concetto.in/workshops/crispr.jpg'
        elif 'ai' in e.get('id', '').lower() or 'agentic' in e.get('title', '').lower():
            e['posterUrl'] = 'https://www.concetto.in/workshops/agentic_ai.jpg'

with open('tool/events_data.json', 'w', encoding='utf-8') as f:
    json.dump(events, f, indent=2, ensure_ascii=False)

print("Updated tool/events_data.json successfully with clean team sizes and workshop fixes!")
