import urllib.request
import ssl
import re
import json
import time

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

with open(r'C:\Users\Sentinel\.gemini\antigravity-ide\brain\4310f7bd-0337-4cc2-889e-f0a105c12d80\.system_generated\steps\9311\content.md', 'r', encoding='utf-8') as f:
    text = f.read()

team_links = sorted(list(set(re.findall(r'href=[\"\'](/teams/[a-zA-Z0-9-]+)[\"\']', text))))
print(f"Fetching {len(team_links)} profiles...")

results = {}

for link in team_links:
    slug = link.replace('/teams/', '')
    url = f"https://www.concetto.in{link}"
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    for attempt in range(3):
        try:
            with urllib.request.urlopen(req, context=ctx, timeout=12) as resp:
                html = resp.read().decode('utf-8', errors='ignore')
                
                # Extract phones from tel: links or general patterns
                raw_phones = re.findall(r'tel:([^\'\"\s\\]+)', html)
                clean_phone = ''
                if raw_phones:
                    clean_phone = raw_phones[0].strip()
                else:
                    m = re.search(r'(\+?91[\s-]?\d{10}|\b[6-9]\d{9}\b)', html)
                    if m:
                        clean_phone = m.group(1).strip()

                # Extract email
                raw_emails = re.findall(r'mailto:([^\'\"\s\\]+)', html)
                clean_email = ''
                for em in raw_emails:
                    if 'iitism.ac.in' in em and 'concetto@' not in em and 'sponsorship' not in em:
                        clean_email = em
                        break
                if not clean_email and raw_emails:
                    clean_email = raw_emails[0]

                # Extract name
                name_m = re.search(r'<title>(.*?)(\||—|-)', html)
                title_name = name_m.group(1).strip() if name_m else slug

                results[slug] = {
                    'slug': slug,
                    'phone': clean_phone,
                    'email': clean_email,
                }
                print(f"[{len(results)}/{len(team_links)}] {slug}: phone='{clean_phone}', email='{clean_email}'")
                break
        except Exception as e:
            print(f"Attempt {attempt+1} failed for {slug}: {e}")
            time.sleep(1)

with open('tool/team_profiles.json', 'w', encoding='utf-8') as f:
    json.dump(results, f, indent=2)

print(f"\nDone! Saved {len(results)} profiles to tool/team_profiles.json")
