import re

with open('lib/core/network/mock_data.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# Add stages and isStageExperience to inauguration_ceremony
inaug_stages = """      isStageExperience: true,
      stages: [
        EventStage(name: 'Chief Guest Arrival', date: 'Oct 8, 2026', time: '04:00 PM - 05:00 PM', venue: 'Penman Auditorium VIP Foyer', synopsis: 'Arrival and formal reception of dignitaries and keynote guests.'),
        EventStage(name: 'Inauguration & Lamp Lighting', date: 'Oct 8, 2026', time: '05:00 PM - 06:00 PM', venue: 'Penman Stage', synopsis: 'Ceremonial lamp lighting and centenary inauguration.'),
        EventStage(name: 'Director Welcome Address', date: 'Oct 8, 2026', time: '06:00 PM - 07:00 PM', venue: 'Penman Auditorium', synopsis: 'Welcome speech by Director, IIT (ISM) Dhanbad and chief guest address.'),
        EventStage(name: 'Fest Overview & Showcase', date: 'Oct 8, 2026', time: '07:00 PM - 08:00 PM', venue: 'Penman Auditorium', synopsis: 'Concetto \\'26 theme film premiere, events overview, and celebrations rollout.'),
      ],"""

if "id: 'inauguration_ceremony'" in text and "inaug_stages" not in text:
    text = re.sub(
        r"(id:\s*'inauguration_ceremony'.*?isWatchableOnly:\s*true,)",
        r"\1\n" + inaug_stages,
        text,
        flags=re.DOTALL
    )

# Add stages and isStageExperience to star_night_celebrity
star_stages = """      isStageExperience: true,
      stages: [
        EventStage(name: 'Sound Check & Prep', date: 'Oct 11, 2026', time: '06:30 PM - 07:30 PM', venue: 'Main Ground', synopsis: 'Final audio engineer balances and pyrotechnic system checks.'),
        EventStage(name: 'Gates Open & Entry', date: 'Oct 11, 2026', time: '07:30 PM - 08:00 PM', venue: 'Main Ground Gates', synopsis: 'Security check and wristband validation for student access.'),
        EventStage(name: 'Star Night Live In-Concert', date: 'Oct 11, 2026', time: '08:00 PM - 11:00 PM', venue: 'Main Ground Stage', synopsis: 'Electrifying headline music and stage concert.'),
      ],"""

if "id: 'star_night_celebrity'" in text and "Sound Check" not in text:
    text = re.sub(
        r"(id:\s*'star_night_celebrity'.*?isWatchableOnly:\s*true,)",
        r"\1\n" + star_stages,
        text,
        flags=re.DOTALL
    )

# Add stages to robowars
robowars_stages = """      stages: [
        EventStage(name: 'Main Tournament Rounds', date: 'Oct 11, 2026', time: '10:00 AM - 12:00 PM', venue: 'Central Arena Polycarbonate Cage', synopsis: 'Heavyweight knockout matches and weapon system clashes.'),
        EventStage(name: 'Grand Championship Final', date: 'Oct 11, 2026', time: '05:00 PM - 06:00 PM', venue: 'Central Arena Stadium Stage', synopsis: 'Championship title clash under stadium floodlights.'),
      ],"""

if "id: 'robowars_combat'" in text and "Main Tournament Rounds" not in text:
    text = re.sub(
        r"(id:\s*'robowars_combat'.*?isWatchableOnly:\s*false,)",
        r"\1\n" + robowars_stages,
        text,
        flags=re.DOTALL
    )

with open('lib/core/network/mock_data.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print("Applied stages successfully!")
