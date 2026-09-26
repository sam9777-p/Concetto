with open(r'C:\Users\Sentinel\.gemini\antigravity-ide\brain\4310f7bd-0337-4cc2-889e-f0a105c12d80\.system_generated\steps\9311\content.md', 'r', encoding='utf-8') as f:
    text = f.read()

import re
team_links = sorted(list(set(re.findall(r'href=[\"\'](/teams/[a-zA-Z0-9-]+)[\"\']', text))))
print(f"Found {len(team_links)} team member profiles:")
for link in team_links:
    print(link)
