import json
import re

mock_path = 'lib/core/network/mock_data.dart'
with open(mock_path, 'r', encoding='utf-8') as f:
    mock_content = f.read()

# 1. Clean event titles in mock_data.dart
mock_content = mock_content.replace(
    "title: 'ROBO WARS — Combat Robotics Championship',",
    "title: 'Robowars',"
).replace(
    "title: 'ROBO WARS \u2014 Combat Robotics Championship',",
    "title: 'Robowars',"
)

mock_content = mock_content.replace(
    "title: 'Campus Treasure Hunt Challenge',",
    "title: 'Treasure Hunt',"
)

mock_content = mock_content.replace(
    "title: 'AnGD Game Jam (RRR-A Game Jam)',",
    "title: 'RRR - A Game Jam',"
)

mock_content = mock_content.replace(
    "title: 'SPE Event (Stand Tall - Jack Up Challenge)',",
    "title: 'SPE Event',"
)

mock_content = mock_content.replace(
    "title: 'CELEBRITY STAR NIGHT (GRAND FINALE)',",
    "title: 'Star Night',"
)

mock_content = mock_content.replace(
    "title: 'Distinguished Alumni Guest Talk 2',",
    "title: 'Alumni Guest Talk',"
)

mock_content = mock_content.replace(
    "title: 'Innovation Keynote Guest Talk 2',",
    "title: 'Innovation Talk 2',"
)

mock_content = mock_content.replace(
    "title: 'Minute to Win It — Fast Reflex Games',",
    "title: 'Minute to Win It',"
).replace(
    "title: 'Minute to Win It \u2014 Fast Reflex Games',",
    "title: 'Minute to Win It',"
)

mock_content = mock_content.replace(
    "title: 'AeroGlide (Mechismu)',",
    "title: 'AeroGlide',"
)

mock_content = mock_content.replace(
    "title: 'VibeHack ’26 (DevDash)',",
    "title: 'VibeHack ’26',"
).replace(
    "title: 'VibeHack \'26 (DevDash)',",
    "title: 'VibeHack \'26',"
)

mock_content = mock_content.replace(
    "title: 'Reservoir Making — IADC (Crack the Crude)',",
    "title: 'Reservoir Making — IADC',"
).replace(
    "title: 'Reservoir Making \u2014 IADC (Crack the Crude)',",
    "title: 'Reservoir Making \u2014 IADC',"
)

mock_content = mock_content.replace(
    "title: 'Prom Night \'26 — Centenary Kickoff Gala',",
    "title: 'Prom Night \'26',"
).replace(
    "title: 'Prom Night \'26 \u2014 Centenary Kickoff Gala',",
    "title: 'Prom Night \'26',"
)

# 2. Update Kryptoes '26 in mock_data.dart
old_kryptoes = """    EventItem(
      id: 'kryptoes_pre',
      title: 'Kryptoes \\'26 — Solo Dance Showdown',
      category: 'Pre-Event',
      tags: ['Pre-Events', 'Dance', 'Stage', 'Cultural', 'LITM', 'Solo Dance'],
      organizerClub: 'LITM (Legends In The Making)',
      venue: 'Penman Auditorium Stage',
      time: '06:00 PM - 09:30 PM',
      date: 'Oct 6, 2026',
      prizePool: 'TBD',
      teamSize: 'Solo (1 Performer)',
      description: 'The premier solo dance face-off at IIT (ISM) Dhanbad organized by LITM (Legends In The Making). Freshers and campus dancers clash on stage across Hip Hop, Freestyle, Popping, Waacking, and Contemporary styles to crown the ultimate dance champion of Concetto!',
      posterUrl: 'https://www.concetto.in/events/kryptos.png',
      registrationUrl: 'https://docs.google.com/forms/d/e/1FAIpQLSdSvIrxl8SFP16c3nVU4ZvfCux_QbSUCxSosBAMZMCsHnG_jQ/viewform',
      rulebookUrl: '',
      coordinatorName: 'Concetto Organizing Team',
      coordinatorContact: 'litm@iitism.ac.in',
      coordinatorEmail: 'litm@iitism.ac.in',
      coordinatorPhone: '+91 83412 60805',
            specificPassword: 'c26_kryptoespr_8693',
      isVisible: true,
      isFlagship: false,
      isWatchableOnly: false,
    ),"""

new_kryptoes = """    EventItem(
      id: 'kryptoes_pre',
      title: 'Kryptoes \\'26',
      category: 'Stage',
      tags: ['Stage', 'Dance', 'Cultural', 'LITM', 'Pre-Events'],
      organizerClub: 'LITM (Legends In The Making)',
      venue: 'Penman Auditorium Stage',
      time: '06:00 PM - 09:30 PM',
      date: 'Oct 6, 2026',
      prizePool: 'TBD',
      teamSize: '',
      description: 'The premier solo dance face-off at IIT (ISM) Dhanbad organized by LITM (Legends In The Making). Freshers and campus dancers clash on stage across Hip Hop, Freestyle, Popping, Waacking, and Contemporary styles to crown the ultimate dance champion of Concetto! Open stage showcase event.',
      posterUrl: 'https://www.concetto.in/events/kryptoes.png',
      registrationUrl: '',
      rulebookUrl: '',
      coordinatorName: 'Concetto Organizing Team',
      coordinatorContact: 'litm@iitism.ac.in',
      coordinatorEmail: 'litm@iitism.ac.in',
      coordinatorPhone: '+91 83412 60805',
      specificPassword: 'c26_kryptoespr_8693',
      isVisible: true,
      isFlagship: false,
      isWatchableOnly: true,
      isStageExperience: true,
    ),"""

if old_kryptoes in mock_content:
    mock_content = mock_content.replace(old_kryptoes, new_kryptoes)
    print("Replaced old Kryptoes with Stage Experience Kryptoes '26!")
else:
    print("Warning: old_kryptoes not exact match, using regex replacement")
    mock_content = re.sub(
        r"EventItem\(\s*id:\s*'kryptoes_pre'.*?isWatchableOnly:\s*false,\s*\),",
        new_kryptoes,
        mock_content,
        flags=re.DOTALL
    )

# 3. Add Workshops if not present
if "workshop_cancer_biology" not in mock_content:
    workshops_code = """
    EventItem(
      id: 'workshop_cancer_biology',
      title: 'Cancer Biology',
      category: 'Workshops',
      tags: ['Workshops', 'Biotechnology', 'CRISPR', 'Oncology', 'Masterclass'],
      organizerClub: 'Biotechnology Society',
      venue: 'Golden Jubilee Lecture Theatre (GJLT)',
      time: '10:00 AM - 04:00 PM',
      date: 'Oct 10-11, 2026',
      prizePool: '₹1,299 (2-Day) / ₹899 (1-Day)',
      teamSize: 'Individual Registration',
      description: 'Hands-on intensive masterclass exploring next-generation cancer therapeutics, CRISPR-Cas9 gene editing mechanisms, immunotherapy breakthroughs, and computational oncology tools. Certified workshop with clinical research demonstrations.',
      posterUrl: 'https://www.concetto.in/workshops/crispr.jpg',
      registrationUrl: 'https://pages.razorpay.com/biodhanbad',
      rulebookUrl: '',
      coordinatorName: 'Concetto Workshop Cell',
      coordinatorContact: 'workshops@iitism.ac.in',
      coordinatorEmail: 'workshops@iitism.ac.in',
      coordinatorPhone: '+91 94140 12345',
      specificPassword: 'c26_workshop_bio_1026',
      isVisible: true,
      isFlagship: true,
      isWatchableOnly: false,
      isStageExperience: false,
      stages: [
        EventStage(
          name: 'Day 1: Cancer Genetics & CRISPR Foundations',
          date: 'Oct 10, 2026',
          time: '10:00 AM - 04:00 PM',
          venue: 'GJLT Hall 1',
          synopsis: 'CRISPR-Cas9 mechanisms and hands-on bioinformatics session.',
        ),
        EventStage(
          name: 'Day 2: Immunotherapy & Clinical Pipelines',
          date: 'Oct 11, 2026',
          time: '10:00 AM - 04:00 PM',
          venue: 'GJLT Hall 1',
          synopsis: 'Translational oncology and live gene analysis tools.',
        ),
      ],
    ),
    EventItem(
      id: 'workshop_agentic_ai',
      title: 'Generative & Agentic AI',
      category: 'Workshops',
      tags: ['Workshops', 'Artificial Intelligence', 'LLMs', 'Agents', 'RAG'],
      organizerClub: 'Computer Science & Engineering Society',
      venue: 'Computer Centre (CC) Lab 3',
      time: '10:00 AM - 04:00 PM',
      date: 'Oct 10-11, 2026',
      prizePool: '₹1,299 (2-Day) / ₹899 (1-Day)',
      teamSize: 'Individual Registration',
      description: 'Comprehensive hands-on workshop on building Autonomous Multi-Agent Workflows, Function Calling with Gemini 2.0 / LLMs, Vector Databases (RAG), and productionizing AI agents.',
      posterUrl: 'https://www.concetto.in/workshops/agentic_ai.jpg',
      registrationUrl: 'https://pages.razorpay.com/techdhanbad',
      rulebookUrl: '',
      coordinatorName: 'Concetto Tech Workshops',
      coordinatorContact: 'techworkshops@iitism.ac.in',
      coordinatorEmail: 'techworkshops@iitism.ac.in',
      coordinatorPhone: '+91 98765 43210',
      specificPassword: 'c26_workshop_ai_2026',
      isVisible: true,
      isFlagship: true,
      isWatchableOnly: false,
      isStageExperience: false,
      stages: [
        EventStage(
          name: 'Day 1: Multi-Agent Systems & Tool Calling',
          date: 'Oct 10, 2026',
          time: '10:00 AM - 04:00 PM',
          venue: 'CC Lab 3',
          synopsis: 'Agent architectures, tool calling with Gemini, and structured generation.',
        ),
        EventStage(
          name: 'Day 2: Autonomous Agents & Production Deployment',
          date: 'Oct 11, 2026',
          time: '10:00 AM - 04:00 PM',
          venue: 'CC Lab 3',
          synopsis: 'Memory indexing, vector search, and deploying live production agents.',
        ),
      ],
    ),
"""
    # Insert right before the end of mockEvents list
    mock_content = re.sub(
        r"(\s*static final List<CoreTeamMember> team)",
        workshops_code + r"\n  ];\n\1",
        mock_content
    )
    # remove duplicate `];` if matched
    mock_content = mock_content.replace("  ];\n  ];\n", "  ];\n")
    print("Added workshops to mock_data.dart!")

with open(mock_path, 'w', encoding='utf-8') as f:
    f.write(mock_content)

print("Updated mock_data.dart successfully!")
