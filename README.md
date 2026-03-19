# APACare

A mobile application that provides personalized physical activity recommendations for oncology patients, combining a Knowledge Graph (KG), SNOMED-CT clinical codes, and LLM-based reasoning.

---

## Architecture

```
┌─────────────────────────────────┐
│         Flutter App (Frontend)  │
│  Patient Profile → Recommenda-  │
│  tions Screen (LLM + KG based)  │
└────────────┬────────────────────┘
             │ HTTP (REST API)
             ▼
┌─────────────────────────────────┐
│    FastAPI Backend (Python)     │
│                                 │
│  ┌──────────┐  ┌─────────────┐  │
│  │  LLM     │  │ Knowledge   │  │
│  │ Reasoner │  │   Graph     │  │
│  └──────────┘  └──────┬──────┘  │
│                       │         │
│              ┌────────┴───────┐ │
│              │  SNOMED-CT     │ │
│              │  2024-01       │ │
│              └────────────────┘ │
└─────────────────────────────────┘
```

---

## Project Structure

```
apacare/
├── lib/                            # Flutter application
│   ├── main.dart                   # App entry point
│   ├── config/
│   │   └── api_config.dart         # Base URLs and timeouts
│   ├── models/
│   │   └── patient_state.dart      # Patient data model
│   ├── screens/
│   │   ├── patient_profile_screen.dart
│   │   ├── recommendations_screen.dart
│   │   ├── llm_recommendations_screen.dart
│   │   └── dynamic_recommendations_screen.dart
│   ├── services/
│   │   ├── recommendation_service.dart
│   │   └── api_recommendation_service.dart
│   └── theme/
│       └── app_theme.dart
│
├── backend/                        # Python FastAPI backend
│   ├── main.py                     # API server + KG + LLM logic
│   ├── requirements.txt
│   ├── requirements_minimal.txt
│   ├── run_backend.bat             # Windows startup script
│   ├── data/
│   │   ├── medical_guidelines.json # Knowledge Graph data
│   │   ├── sportsantecvl.json      # Sport centers & activities data
│   │   ├── scenarios.json          # Clinical scenarios
│   │   ├── profile.json            # Sample patient profile
│   │   ├── test_patients/          # Patient test fixtures (p01-p10)
│   │   └── test_scenarios/         # Scenario test fixtures (s1-s5)
│   ├── exports/
│   │   ├── oncology_kg.ttl         # RDF/Turtle KG export
│   │   └── fhir/                   # FHIR R4 exports
│   │       ├── oncology_kg_bundle.json
│   │       ├── activity_definitions.json
│   │       └── plan_definitions.json
│   ├── scripts/
│   │   ├── export_rdf.py           # Export KG to RDF/Turtle
│   │   └── export_fhir.py          # Export KG to FHIR R4
│   └── tests/
│       ├── test.py
│       └── test_snomed_kg.py
│
├── docs/                           # Project documentation
├── test/                           # Flutter widget tests
└── pubspec.yaml
```

---

## Knowledge Graph

The KG encodes oncology clinical knowledge as a graph of:
- **Diseases** — cancer types (breast, lung, colorectal, prostate, leukemia, lymphoma...) with SNOMED-CT and ICD-10 codes
- **Conditions** — patient states (fatigue, neuropathy, anemia, cardiac risk...) with severity levels
- **Activities** — physical activities (walking, yoga, swimming, cycling...) with MET values and intensity levels
- **Drugs** — chemotherapy agents and their known side effects
- **Guidelines** — evidence-based rules linking patient state to safe activities

All nodes carry SNOMED-CT 2024-01 codes for clinical interoperability.

---

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | Service info and status |
| GET | `/health` | Health check |
| POST | `/recommendations` | Generate personalized recommendations |
| GET | `/snomed/diseases` | List all diseases with SNOMED-CT codes |
| GET | `/snomed/activities` | List all activities with SNOMED-CT codes |
| GET | `/snomed/conditions` | List all conditions with SNOMED-CT codes |
| GET | `/snomed/lookup/{code}` | Look up a node by SNOMED-CT code |
| GET | `/snomed/info` | SNOMED-CT integration statistics |

### POST `/recommendations` — Request body

```json
{
  "cancer_type": "breast_cancer",
  "treatment_phase": "active_treatment",
  "ecog": 1,
  "fatigue": 3,
  "pain": 2,
  "mood": 4,
  "heart_rate": 72,
  "systolic_bp": 120,
  "steps_today": 3000,
  "conditions": ["fatigue", "nausea"],
  "drugs": ["doxorubicin"]
}
```

---

## Setup

### Backend

**Requirements:** Python 3.10+

```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

Or on Windows:
```bash
run_backend.bat
```

Optional (for full LLM features):
```bash
pip install sentence-transformers transformers torch
```

### Flutter App

**Requirements:** Flutter 3.x, Dart SDK >= 3.4.3

```bash
flutter pub get
flutter run
```

The app connects to the backend at `http://localhost:8000` (configurable in `lib/config/api_config.dart`).

---

## Exports

The KG can be exported to standard clinical formats:

```bash
# RDF/Turtle (for semantic web / ontology tools)
python backend/scripts/export_rdf.py

# FHIR R4 (for clinical system integration)
python backend/scripts/export_fhir.py
```

Outputs are saved to `backend/exports/`.

---

## Testing

```bash
# Backend KG tests
python backend/tests/test_snomed_kg.py

# Flutter widget tests
flutter test
```

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile Frontend | Flutter / Dart |
| Backend API | Python, FastAPI |
| Knowledge Graph | Custom graph + JSON |
| Clinical Coding | SNOMED-CT 2024-01, ICD-10 |
| LLM Reasoning | HuggingFace Transformers (optional) |
| Embeddings | sentence-transformers (optional) |
| Interoperability | RDF/Turtle, FHIR R4 |
