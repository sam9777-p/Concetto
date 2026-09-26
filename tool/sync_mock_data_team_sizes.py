import re
import json

with open('tool/events_data.json', 'r', encoding='utf-8') as f:
    events_json = json.load(f)

json_map = {e.get('id'): e for e in events_json}

with open('lib/core/network/mock_data.dart', 'r', encoding='utf-8') as f:
    content = f.read()

def update_event_block(match):
    block = match.group(0)
    id_m = re.search(r"id:\s*'([^']*)'", block)
    if not id_m:
        return block
    eid = id_m.group(1)
    
    # Defaults
    min_size = 1
    max_size = 4
    is_open = False
    
    if eid in json_map:
        je = json_map[eid]
        min_size = je.get('minTeamSize', 1)
        max_size = je.get('maxTeamSize', 4)
        is_open = je.get('isOpenRegistration', False)
        new_ts = je.get('teamSize', '1 - 4 Members')
        prize = je.get('prizePool', '')
        poster = je.get('posterUrl', '')
    else:
        ts_m = re.search(r"teamSize:\s*'([^']*)'", block)
        ts = ts_m.group(1) if ts_m else ''
        if 'open' in ts.lower() or 'individual' in ts.lower():
            is_open = True
            new_ts = 'Open Registration'
        else:
            range_m = re.search(r'(\d+)\s*[-–]\s*(\d+)', ts)
            single_m = re.search(r'(\d+)', ts)
            if range_m:
                min_size = int(range_m.group(1))
                max_size = int(range_m.group(2))
                new_ts = f"{min_size} - {max_size} Members"
            elif single_m:
                min_size = int(single_m.group(1))
                max_size = min_size
                new_ts = "Solo (1 Member)" if min_size == 1 else f"{min_size} Members"
            else:
                is_open = True
                new_ts = 'Open Registration'
    
    # If workshop, remove prize money & rulebook
    if 'workshop' in eid.lower() or 'workshop' in block.lower():
        block = re.sub(r"prizePool:\s*'[^']*'", "prizePool: ''", block)
        block = re.sub(r"rulebookUrl:\s*'[^']*'", "rulebookUrl: ''", block)
        is_open = True
        new_ts = 'Open Registration'
        min_size = 1
        max_size = 1
        if 'bio' in eid.lower() or 'cancer' in block.lower():
            block = re.sub(r"posterUrl:\s*'[^']*'", "posterUrl: 'https://www.concetto.in/workshops/crispr.jpg'", block)
        elif 'ai' in eid.lower() or 'agentic' in block.lower():
            block = re.sub(r"posterUrl:\s*'[^']*'", "posterUrl: 'https://www.concetto.in/workshops/agentic_ai.jpg'", block)

    # Replace teamSize
    block = re.sub(r"teamSize:\s*'[^']*'", f"teamSize: '{new_ts}'", block)
    
    # Ensure minTeamSize, maxTeamSize, isOpenRegistration exist in the block
    if 'minTeamSize:' not in block:
        # Insert right after teamSize
        block = re.sub(
            r"(teamSize:\s*'[^']*',)",
            rf"\1\n      minTeamSize: {min_size},\n      maxTeamSize: {max_size},\n      isOpenRegistration: {'true' if is_open else 'false'},",
            block
        )
    else:
        block = re.sub(r"minTeamSize:\s*\d+", f"minTeamSize: {min_size}", block)
        block = re.sub(r"maxTeamSize:\s*\d+", f"maxTeamSize: {max_size}", block)
        block = re.sub(r"isOpenRegistration:\s*(true|false)", f"isOpenRegistration: {'true' if is_open else 'false'}", block)
        
    return block

updated_content = re.sub(r'EventItem\s*\((.*?)\),', update_event_block, content, flags=re.DOTALL)

with open('lib/core/network/mock_data.dart', 'w', encoding='utf-8') as f:
    f.write(updated_content)

print("Updated mock_data.dart successfully with minTeamSize, maxTeamSize, and isOpenRegistration!")
