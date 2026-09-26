import re

with open('lib/core/network/mock_data.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# Only extract titles of EventItem
event_blocks = re.findall(r'EventItem\((.*?)\),', text, re.DOTALL)
print(f"Total events found: {len(event_blocks)}")
for i, block in enumerate(event_blocks):
    m_title = re.search(r'title:\s*[\'"](.*?)[\'"]', block)
    m_cat = re.search(r'category:\s*[\'"](.*?)[\'"]', block)
    m_club = re.search(r'organizerClub:\s*[\'"](.*?)[\'"]', block)
    if m_title:
        title = m_title.group(1)
        cat = m_cat.group(1) if m_cat else ''
        club = m_club.group(1) if m_club else ''
        print(f"{i+1}. [{cat}] {title} (Club: {club})")
