import re

path = 'lib/core/network/mock_data.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace any prizePool: '...' or prizePool: "..." with prizePool: 'TBD',
new_content = re.sub(r"prizePool:\s*['\"][^'\"]*['\"],", "prizePool: 'TBD',", content)

with open(path, 'w', encoding='utf-8') as f:
    f.write(new_content)

matches = len(re.findall(r"prizePool:\s*'TBD',", new_content))
print(f"Successfully updated {matches} events in mock_data.dart with prizePool: 'TBD'!")
