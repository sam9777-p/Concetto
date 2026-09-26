import json
import re

with open('tool/team_profiles.json', 'r', encoding='utf-8') as f:
    profiles = json.load(f)

with open('lib/core/network/mock_data.dart', 'r', encoding='utf-8') as f:
    content = f.read()

def slugify(name):
    clean = re.sub(r'[^a-zA-Z0-9\s]', '', name).lower()
    return '-'.join(clean.split())

# Map each member name to their profile
name_to_profile = {}
for slug, p in profiles.items():
    name_to_profile[slug] = p

count_updated = 0

def replace_member(match):
    global count_updated
    block = match.group(0)
    name_m = re.search(r"name:\s*'([^']*)'", block)
    if not name_m:
        return block
    name = name_m.group(1)
    slug = slugify(name)
    
    profile = None
    if slug in name_to_profile:
        profile = name_to_profile[slug]
    else:
        for p_slug, p_data in name_to_profile.items():
            if p_slug in slug or slug in p_slug:
                profile = p_data
                break
    
    if profile:
        new_phone = profile['phone']
        new_email = profile['email']
        
        # Replace phone
        block = re.sub(r"phone:\s*'[^']*'", f"phone: '{new_phone}'", block)
        # Replace email if member had generic concetto@iitism.ac.in
        if new_email and 'concetto@iitism.ac.in' in block:
            block = re.sub(r"email:\s*'[^']*'", f"email: '{new_email}'", block)
        
        count_updated += 1
        print(f"Updated: {name} -> Phone: {new_phone}, Email: {new_email}")
        
    return block

updated_content = re.sub(r'CoreTeamMember\s*\((.*?)\),', replace_member, content, flags=re.DOTALL)

with open('lib/core/network/mock_data.dart', 'w', encoding='utf-8') as f:
    f.write(updated_content)

print(f"\nDone! Updated {count_updated} members in lib/core/network/mock_data.dart")
