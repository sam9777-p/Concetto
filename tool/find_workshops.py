import re

with open('lib/core/network/mock_data.dart', 'r', encoding='utf-8') as f:
    text = f.read()

events = re.findall(r'EventItem\s*\((.*?)\),', text, re.DOTALL)
print(f"Total events in mock_data.dart: {len(events)}")
for e in events:
    if 'workshop' in e.lower():
        title_m = re.search(r"title:\s*'([^']*)'", e)
        cat_m = re.search(r"category:\s*'([^']*)'", e)
        prize_m = re.search(r"prizePool:\s*'([^']*)'", e)
        poster_m = re.search(r"posterUrl:\s*'([^']*)'", e)
        id_m = re.search(r"id:\s*'([^']*)'", e)
        print(f"ID: {id_m.group(1) if id_m else ''} | Title: {title_m.group(1) if title_m else ''} | Cat: {cat_m.group(1) if cat_m else ''} | Prize: {prize_m.group(1) if prize_m else ''} | Poster: {poster_m.group(1) if poster_m else ''}")
