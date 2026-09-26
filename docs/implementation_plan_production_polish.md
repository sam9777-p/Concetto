# Production Polish & Feature Enhancement Implementation Plan

## 1. Executive Summary & Objectives
This implementation plan addresses the complete set of requirements to bring the Concetto '26 application to production excellence:
1. **GitHub Sync & Credentials Lockdown**:
   - Hardcode Cloudinary constants (`apiKey`, `apiSecret`, `cloudName: 'dcfjykkek'`).
   - Remove runtime UI editing dialogs (`_showCloudNameDialog`) to prevent credential leakage.
   - Maintain a clean Git state and commit/push updates.
2. **Admin Save Feedback**:
   - Show clear confirmation text (*"Event updated successfully!"*) alongside the checkmark upon editing and saving an event.
3. **Home Page Scroll Damping**:
   - Replace loose bouncy scroll physics with damped `ClampingScrollPhysics` so the viewport sticks firmly at the top without spring rebounds.
4. **Stage Experience / Open Showcase Events**:
   - Add a `isStageExperience` flag in `EventItem`.
   - In the Event Editor, add a toggle for *Stage Experience / Showcase* which hides team size, Google form / registration link, and rulebooks.
   - Mark **Kryptoes '26**, **Star Night**, **Prom Night '26**, and **Guest Talks** as Stage Experiences.
   - Update Kryptoes '26 poster to `https://www.concetto.in/events/kryptoes.png`.
5. **Multi-Stage & Schedule Breakdown System**:
   - Remove dummy/generic schedule breakdowns from `event_detail_screen.dart`.
   - Provide structured multi-stage support (`EventStage` model: name, date, time, venue, synopsis).
   - In the Event Editor, provide a stages manager to add, edit, and remove rounds/stages.
   - Multi-day / multi-stage events will automatically appear under their respective days in `schedule_screen.dart`.
6. **Clean Redundant Admin Instructions**:
   - Remove subtitles like *"Visible in festival schedule & directory"* and *"Use sliders to toggle student visibility"*.
   - Make the `DEV ACTIVE` badge smaller and unobtrusive.
   - Re-arrange the organizer/club filter panel so it is clearly visible and neatly organized.
7. **Schedule Screen Tab Glitch & Text Simplification**:
   - Fix the rapid highlight oscillation glitch (where tab highlights bounce back and forth between Day 2 and Day 3) by ignoring scroll events during page transitions and adding gesture debounce.
   - Change day selector tabs to clean day names (**Thursday**, **Friday**, **Saturday**, **Sunday**).
   - Remove the bottom card *"PULL UP OR TAP TO VIEW DAY X"*.
   - Simplify the floating pull indicator to a minimal arrow and day name (e.g., `↑ SATURDAY`).
8. **Workshops Category & Integration**:
   - Add a dedicated **Workshops** category.
   - Ingest official workshops from `https://www.concetto.in/workshops`:
     - *Cancer Biology* (Biotechnology | Oct 10–11 | Razorpay registration `https://pages.razorpay.com/biodhanbad` | `crispr.jpg`)
     - *Generative & Agentic AI* (Artificial Intelligence | Oct 10–11 | Razorpay registration `https://pages.razorpay.com/techdhanbad` | `agentic_ai.jpg`)
   - Display workshops in both directory and schedule (under Saturday & Sunday).
9. **Clean Event Titles & Home Cleanup**:
   - Remove bracketed club names from event titles (e.g. change `RoboWars (Mechismo)` to `Robowars`, `Treasure Hunt (Club)` to `Treasure Hunt`, `SPE Event`, `RRR - A Game Jam`, `Kryptoes '26`, `Star Night`, `Prom Night '26`, `Minute to Win It`, `Alumni Guest Talk`, `Innovation Talk 2`).
   - Remove redundant subtitle text below *"Pre-Festival Specials"* on the Events screen.
10. **Official Team Directory (from https://www.concetto.in/teams)**:
   - Ingest the 43 team members across 14 teams with designations, phone numbers, emails, and social profiles.
   - Rename **Profile** tab to **About** across the entire app.
