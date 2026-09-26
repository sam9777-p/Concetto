import json

with open('tool/events_data.json', 'r', encoding='utf-8') as f:
    events = json.load(f)

no_form = []
has_form = []

for e in events:
    title = e.get('title', '')
    reg = e.get('registrationUrl', '').strip()
    cat = e.get('category', '')
    if not reg or 'docs.google.com/forms' not in reg:
        no_form.append((title, cat, reg))
    else:
        has_form.append(title)

print(f"Events without Google Form ({len(no_form)}):")
for t, c, r in no_form:
    print(f" - [{c}] {t} (link: {r})")
