import re

with open('lib/core/network/mock_data.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Verify specific titles to replace
replacements = [
    ("ROBO WARS — Combat Robotics Championship", "Robowars"),
    ("ROBO WARS \u2014 Combat Robotics Championship", "Robowars"),
    ("Campus Treasure Hunt Challenge", "Treasure Hunt"),
    ("AnGD Game Jam (RRR-A Game Jam)", "RRR - A Game Jam"),
    ("SPE Event (Stand Tall - Jack Up Challenge)", "SPE Event"),
    ("CELEBRITY STAR NIGHT (GRAND FINALE)", "Star Night"),
    ("Distinguished Alumni Guest Talk 2", "Alumni Guest Talk"),
    ("Innovation Keynote Guest Talk 2", "Innovation Talk 2"),
    ("Minute to Win It — Fast Reflex Games", "Minute to Win It"),
    ("Minute to Win It \u2014 Fast Reflex Games", "Minute to Win It"),
    ("VibeHack '26 (DevDash)", "VibeHack '26"),
    ("Reservoir Making — IADC (Crack the Crude)", "Reservoir Making — IADC"),
    ("Reservoir Making \u2014 IADC (Crack the Crude)", "Reservoir Making — IADC"),
    ("AeroGlide (Mechismu)", "AeroGlide"),
]

for old, new in replacements:
    if old in content:
        print(f"Found: {old} -> Replacing with {new}")
    else:
        print(f"Not found: {old}")
