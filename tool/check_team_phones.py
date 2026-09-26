import re

with open('lib/core/network/mock_data.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Find team members
members = re.findall(r'CoreTeamMember\s*\((.*?)\),', content, re.DOTALL)
print(f"Total team members found in mock_data.dart: {len(members)}")

for idx, m in enumerate(members):
    name_m = re.search(r"name:\s*'([^']*)'", m)
    name = name_m.group(1) if name_m else 'Unknown'
    role_m = re.search(r"role:\s*'([^']*)'", m)
    role = role_m.group(1) if role_m else ''
    phone_m = re.search(r"phone:\s*'([^']*)'", m)
    phone = phone_m.group(1) if phone_m else ''
    email_m = re.search(r"email:\s*'([^']*)'", m)
    email = email_m.group(1) if email_m else ''
    print(f"{idx+1}. {name} ({role}) -> phone: '{phone}' | email: '{email}'")
