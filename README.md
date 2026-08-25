# Running Training Planner

A personal full-stack project — an iOS app paired with a custom REST API backend — built to plan and log running training. The app is structured around a weekly calendar where activities are mapped to specific days, making it easy to follow a training block leading up to a race.

---

## Screenshots

<!-- Add screenshots here — e.g. HomeView weekly calendar, CreateActivity form, PlansView, DayView -->

| Home | Activity Log | Plans |
|------|-------------|-------|
| _screenshot_ | _screenshot_ | _screenshot_ |

---

## Features

- **Weekly calendar** — page through weeks; each day shows its scheduled activities
- **Training plans** — set a race distance (5K → Marathon), race date, and goal time; activities link back to a plan
- **Activity logging** — log runs, strength training, walks, rock climbs, and more with distance, pace, and notes
- **Pace tagging** — tag runs as Easy, Long Run, or Speed against personal pace targets stored in your profile

---

## Tech Stack

### iOS
| | |
|---|---|
| Language | Swift |
| UI | SwiftUI |
| Auth | Firebase Auth + Google Sign-In |
| Networking | `async`/`await` with `URLSession` |

### Backend
| | |
|---|---|
| Language | Python |
| Framework | FastAPI |
| Database | PostgreSQL (via `asyncpg`) |
| Auth | Firebase Admin SDK (token verification) |
| Package manager | `uv` |

---

## Author

Stella Launay — [stellalaunay6@gmail.com](mailto:stellalaunay6@gmail.com) · [LinkedIn](_link_) · [GitHub](_link_)
