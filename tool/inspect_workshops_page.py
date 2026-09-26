import re

with open(r'C:\Users\Sentinel\.gemini\antigravity-ide\brain\4310f7bd-0337-4cc2-889e-f0a105c12d80\.system_generated\steps\9372\content.md', 'r', encoding='utf-8') as f:
    text = f.read()

images = re.findall(r'(/_next/image\?url=[^&]+|/[a-zA-Z0-9_\-\./]+\.(?:jpg|png|webp|jpeg))', text)
print("Workshop images:", set(images))

cards = re.findall(r'<div[^>]*>(.*?)</div>', text)
# Look for workshop titles or descriptions
for w in ['Cancer', 'Biology', 'AI', 'Agentic', 'CRISPR', 'Workshop']:
    for m in re.finditer(w, text, re.IGNORECASE):
        idx = m.start()
        print(f"\nMatch {w}:")
        print(text[max(0, idx-100):min(len(text), idx+300)])
        break
