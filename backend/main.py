
import json
import os
from typing import List, Dict, Any, Optional
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import numpy as np

try:
    from sentence_transformers import SentenceTransformer
    EMBEDDINGS_AVAILABLE = True
except ImportError:
    EMBEDDINGS_AVAILABLE = False
    print("Warning: sentence-transformers not installed. Using fallback similarity.")

try:
    from openai import OpenAI
    OPENAI_AVAILABLE = True
except ImportError:
    OPENAI_AVAILABLE = False
    print("Warning: openai not installed. Using rule-based fallback.")

app = FastAPI(
    title="APACare Recommendation API",
    description="LLM + Knowledge Graph based activity recommendations for oncology patients",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class PatientData(BaseModel):
    disease: str = "breast_cancer"
    ecog: int = 1
    fatigue: float = 0.45
    pain: float = 0.25
    mood: float = 0.55
    heart_rate: int = 76
    systolic_bp: int = 138
    diastolic_bp: int = 85
    blood_sugar: float = 102.0
    white_cell_count: float = 4.2
    bmi: float = 27.0
    chemo_cycle: int = 3
    steps_today: int = 3200
    preferred_activities: List[str] = ["walking", "yoga", "breathing"]
    intensity_preference: str = "light"
    environment_preference: str = "outdoor"

class RecommendationRequest(BaseModel):
    patient: PatientData
    previous_params: Optional[Dict[str, Any]] = None

class ActivityRecommendation(BaseModel):
    id: str
    activity_type: str
    title: str
    description: str
    duration_minutes: int
    intensity: str
    utility_score: float
    kg_validation_score: float
    combined_score: float
    reasons: List[str]
    adaptations: List[str]
    kg_evidence: List[str]
    center_name: str
    center_address: str

class RecommendationResponse(BaseModel):
    recommendations: List[ActivityRecommendation]
    patient_profile: str
    kg_matched_profiles: List[str]
    llm_explanation: str
    parameter_changes: List[str]

class KnowledgeGraph:
    def __init__(self, kg_path: str):
        with open(kg_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        self.kg = data['knowledge_graph']
        self.guidelines = data['guidelines']

        self.activities = {a['id']: a for a in self.kg['nodes']['activities']}
        self.conditions = {c['id']: c for c in self.kg['nodes']['conditions']}
        self.profiles = {p['id']: p for p in self.kg['nodes']['profiles']}

        self.recommendations = {}
        for edge in self.kg['edges']['recommends']:
            profile = edge['from']
            if profile not in self.recommendations:
                self.recommendations[profile] = []
            self.recommendations[profile].append({
                'activity': edge['to'],
                'weight': edge['weight'],
                'evidence': edge['evidence']
            })

        self.contraindications = {}
        for edge in self.kg['edges']['contraindicates']:
            condition = edge['from']
            if condition not in self.contraindications:
                self.contraindications[condition] = []
            self.contraindications[condition].append({
                'activity': edge['to'],
                'reason': edge['reason']
            })

        self.adaptations = {}
        for edge in self.kg['edges']['adapts']:
            key = (edge['condition'], edge['activity'])
            self.adaptations[key] = edge['adaptation']

    def get_patient_conditions(self, patient: PatientData) -> List[str]:
        conditions = []

        conditions.append(f"ecog_{patient.ecog}")

        if patient.fatigue < 0.3:
            conditions.append("fatigue_none_mild")
        elif patient.fatigue < 0.6:
            conditions.append("fatigue_moderate")
        else:
            conditions.append("fatigue_severe")

        if patient.systolic_bp >= 180 or patient.diastolic_bp >= 110:
            conditions.append("hypertension_severe")
        elif patient.systolic_bp >= 140 or patient.diastolic_bp >= 90:
            conditions.append("hypertension_moderate")
        elif patient.systolic_bp >= 130 or patient.diastolic_bp >= 85:
            conditions.append("hypertension_mild")

        if patient.white_cell_count < 3.0:
            conditions.append("very_low_wbc")
        elif patient.white_cell_count < 4.0:
            conditions.append("low_wbc")

        if "breast" in patient.disease.lower():
            conditions.append("breast_cancer")
        elif "lung" in patient.disease.lower():
            conditions.append("lung_cancer")
        elif "colon" in patient.disease.lower() or "colorectal" in patient.disease.lower():
            conditions.append("colorectal_cancer")

        return conditions

    def match_profiles(self, conditions: List[str]) -> List[str]:
        matched = []
        for profile_id, profile in self.profiles.items():
            profile_conditions = profile['conditions']
            match = True
            for pc in profile_conditions:

                options = pc.split('|')
                if not any(opt in conditions for opt in options):
                    match = False
                    break
            if match:
                matched.append(profile_id)
        return matched

    def get_recommended_activities(self, profiles: List[str]) -> Dict[str, Dict]:
        activities = {}
        for profile in profiles:
            if profile in self.recommendations:
                for rec in self.recommendations[profile]:
                    act_id = rec['activity']
                    if act_id not in activities or rec['weight'] > activities[act_id]['weight']:
                        activities[act_id] = {
                            'weight': rec['weight'],
                            'evidence': rec['evidence'],
                            'profile': profile
                        }
        return activities

    def get_contraindicated_activities(self, conditions: List[str]) -> Dict[str, str]:
        contraindicated = {}
        for condition in conditions:
            if condition in self.contraindications:
                for contra in self.contraindications[condition]:
                    contraindicated[contra['activity']] = contra['reason']
        return contraindicated

    def get_adaptations(self, conditions: List[str], activity: str) -> List[str]:
        adaptations = []
        for condition in conditions:
            key = (condition, activity)
            if key in self.adaptations:
                adaptations.append(self.adaptations[key])
        return adaptations

    def validate_activity(self, activity_id: str, conditions: List[str], profiles: List[str]) -> Dict:
        contraindicated = self.get_contraindicated_activities(conditions)
        recommended = self.get_recommended_activities(profiles)

        if activity_id in contraindicated:
            return {
                'valid': False,
                'score': 0.0,
                'reason': contraindicated[activity_id],
                'evidence': []
            }

        if activity_id in recommended:
            return {
                'valid': True,
                'score': recommended[activity_id]['weight'],
                'reason': None,
                'evidence': [recommended[activity_id]['evidence']]
            }

        return {
            'valid': True,
            'score': 0.5,
            'reason': None,
            'evidence': []
        }

class LLMRecommender:
    def __init__(self):
        self.embedding_model = None
        self.llm = None

        if EMBEDDINGS_AVAILABLE:
            try:
                self.embedding_model = SentenceTransformer('all-MiniLM-L6-v2')
                print("Loaded embedding model: all-MiniLM-L6-v2")
            except Exception as e:
                print(f"Could not load embedding model: {e}")

        if OPENAI_AVAILABLE:
            try:
                self.llm = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
                print("Loaded LLM: gpt-4-0613 (OpenAI)")
            except Exception as e:
                print(f"Could not initialize OpenAI client: {e}")

    def compute_patient_embedding(self, patient: PatientData) -> np.ndarray:
        profile_text = self._patient_to_text(patient)

        if self.embedding_model:
            return self.embedding_model.encode(profile_text)
        else:

            return np.array([
                patient.fatigue,
                patient.pain,
                1 - patient.mood,
                patient.ecog / 4.0,
                patient.heart_rate / 100.0,
                patient.systolic_bp / 180.0,
                patient.bmi / 40.0,
                patient.white_cell_count / 10.0
            ])

    def compute_activity_embedding(self, activity: Dict) -> np.ndarray:
        activity_text = f"{activity['label']}. Intensity: {activity['intensity']}. MET: {activity['met']}"

        if self.embedding_model:
            return self.embedding_model.encode(activity_text)
        else:

            intensity_map = {'very_light': 0.2, 'light': 0.4, 'moderate': 0.6, 'high': 0.8}
            return np.array([
                intensity_map.get(activity['intensity'], 0.5),
                activity['met'] / 10.0
            ])

    def _patient_to_text(self, patient: PatientData) -> str:
        fatigue_level = "severe" if patient.fatigue > 0.6 else "moderate" if patient.fatigue > 0.3 else "mild"
        pain_level = "severe" if patient.pain > 0.6 else "moderate" if patient.pain > 0.3 else "mild"

        return (
            f"{patient.disease} patient with ECOG {patient.ecog}. "
            f"Currently experiencing {fatigue_level} fatigue and {pain_level} pain. "
            f"Blood pressure {patient.systolic_bp}/{patient.diastolic_bp}. "
            f"BMI {patient.bmi:.1f}. White cell count {patient.white_cell_count}. "
            f"Prefers {', '.join(patient.preferred_activities)} activities. "
            f"Intensity preference: {patient.intensity_preference}."
        )

    def compute_utility(
        self,
        patient_embedding: np.ndarray,
        activity_embedding: np.ndarray,
        kg_score: float,
        epsilon1: float = 0.6,
        epsilon2: float = 0.4
    ) -> float:

        if len(patient_embedding) == len(activity_embedding):
            f1 = np.dot(patient_embedding, activity_embedding) / (
                np.linalg.norm(patient_embedding) * np.linalg.norm(activity_embedding) + 1e-8
            )
        else:

            f1 = 0.5

        f1 = (f1 + 1) / 2

        f2 = kg_score

        utility = epsilon1 * f1 + epsilon2 * f2

        return float(utility)

    def rerank_with_gpt4(self, patient: PatientData, activities: List[Dict]) -> List[Dict]:
        if not self.llm or not activities:
            return activities

        activity_list = "\n".join([
            f"{i+1}. {a['activity']['label']} (intensity: {a['activity']['intensity']}, MET: {a['activity']['met']})"
            for i, a in enumerate(activities)
        ])

        prompt = (
            f"You are an oncology exercise specialist. Rate each activity from 0.0 to 1.0 "
            f"for clinical suitability for this patient:\n"
            f"- Disease: {patient.disease}\n"
            f"- ECOG performance status: {patient.ecog}\n"
            f"- Fatigue: {'severe' if patient.fatigue > 0.6 else 'moderate' if patient.fatigue > 0.3 else 'mild'}\n"
            f"- Blood pressure: {patient.systolic_bp}/{patient.diastolic_bp} mmHg\n"
            f"- Chemotherapy cycle: {patient.chemo_cycle}\n\n"
            f"Activities to rate:\n{activity_list}\n\n"
            f"Respond with only valid JSON in this format: {{\"scores\": [score1, score2, ...]}}"
        )

        try:
            response = self.llm.chat.completions.create(
                model="gpt-4-0613",
                messages=[{"role": "user", "content": prompt}],
                max_tokens=100
            )
            result = json.loads(response.choices[0].message.content)
            gpt_scores = result["scores"]
            for i, act in enumerate(activities):
                if i < len(gpt_scores):
                    act['utility'] = 0.7 * act['utility'] + 0.3 * float(gpt_scores[i])
            activities.sort(key=lambda x: x['utility'], reverse=True)
        except Exception:
            pass

        return activities

    def generate_explanation(self, patient: PatientData, recommendations: List[Dict]) -> str:
        if self.llm:
            prompt = (
                f"Explain why these activities are recommended for a {patient.disease} patient "
                f"with ECOG {patient.ecog} and {'severe' if patient.fatigue > 0.6 else 'moderate' if patient.fatigue > 0.3 else 'mild'} fatigue: "
                f"{', '.join([r['title'] for r in recommendations[:3]])}. "
                f"Be brief and focus on safety and benefits."
            )
            try:
                response = self.llm.chat.completions.create(
                    model="gpt-4-0613",
                    messages=[{"role": "user", "content": prompt}],
                    max_tokens=150
                )
                return response.choices[0].message.content
            except Exception as e:
                return f"Recommendations based on your health profile and medical guidelines."
        else:
            return (
                f"Based on your ECOG status ({patient.ecog}) and current fatigue level, "
                f"these activities have been selected to match your capacity while providing "
                f"therapeutic benefits. Each recommendation has been validated against "
                f"oncology exercise guidelines."
            )

def load_sport_centers(path: str) -> List[Dict]:
    try:
        with open(path, 'r', encoding='utf-8') as f:
            centers = json.load(f)

        cancer_centers = [
            c for c in centers
            if 'cancer' in c.get('Pathologies / Prévention', '').lower()
        ]
        return cancer_centers
    except:
        return []

def match_center_to_activity(activity_type: str, centers: List[Dict]) -> Dict:
    activity_keywords = {
        'walking': ['marche', 'randonnée', 'promenade'],
        'yoga': ['yoga', 'gymnastique douce', 'relaxation'],
        'swimming': ['aqua', 'piscine', 'natation'],
        'breathing': ['respiration', 'relaxation', 'sophrologie'],
        'stretching': ['étirement', 'gymnastique douce', 'souplesse'],
        'cycling': ['vélo', 'cyclisme', 'cycling'],
        'strength': ['renforcement', 'musculation', 'fitness']
    }

    keywords = activity_keywords.get(activity_type, [])

    for center in centers:
        discipline = center.get('Discipline', '').lower()
        description = center.get('Description', '').lower()

        for keyword in keywords:
            if keyword in discipline or keyword in description:
                return {
                    'name': center.get('Name', 'Centre Sport Santé'),
                    'address': center.get('address', 'Adresse non disponible'),
                    'phone': center.get('url', ''),
                    'description': center.get('Description', '')[:100]
                }

    return {
        'name': 'CAMI Sport & Cancer - CHU Tours',
        'address': 'Hôpital Bretonneau, 2 Bd Tonnellé, 37000 Tours',
        'phone': '+33 2 47 47 47 47',
        'description': 'Programme sport adapté pour patients en oncologie'
    }

class RecommendationService:
    def __init__(self, kg_path: str, centers_path: str):
        self.kg = KnowledgeGraph(kg_path)
        self.llm_recommender = LLMRecommender()
        self.centers = load_sport_centers(centers_path)

        self.activity_type_map = {
            'walking_light': 'walking',
            'walking_moderate': 'walking',
            'yoga_gentle': 'yoga',
            'yoga_chair': 'yoga',
            'aquagym': 'swimming',
            'swimming_light': 'swimming',
            'breathing_exercises': 'breathing',
            'stretching': 'stretching',
            'cycling_stationary': 'cycling',
            'strength_light': 'strength',
            'relaxation': 'breathing'
        }

    def generate_recommendations(self, request: RecommendationRequest) -> RecommendationResponse:
        patient = request.patient

        conditions = self.kg.get_patient_conditions(patient)
        matched_profiles = self.kg.match_profiles(conditions)

        kg_recommended = self.kg.get_recommended_activities(matched_profiles)
        kg_contraindicated = self.kg.get_contraindicated_activities(conditions)

        patient_embedding = self.llm_recommender.compute_patient_embedding(patient)

        scored_activities = []

        for act_id, activity in self.kg.activities.items():

            if act_id in kg_contraindicated:
                continue

            kg_validation = self.kg.validate_activity(act_id, conditions, matched_profiles)
            if not kg_validation['valid']:
                continue

            activity_embedding = self.llm_recommender.compute_activity_embedding(activity)

            utility = self.llm_recommender.compute_utility(
                patient_embedding,
                activity_embedding,
                kg_validation['score']
            )

            adaptations = self.kg.get_adaptations(conditions, act_id)

            reasons = []
            if act_id in kg_recommended:
                reasons.append(f"Recommended by medical guidelines")

            activity_type = self.activity_type_map.get(act_id, 'other')
            if activity_type in patient.preferred_activities:
                reasons.append("Matches your activity preferences")
                utility += 0.05

            if activity['intensity'] == patient.intensity_preference:
                reasons.append(f"Matches your {patient.intensity_preference} intensity preference")
                utility += 0.03

            center = match_center_to_activity(activity_type, self.centers)

            scored_activities.append({
                'id': act_id,
                'activity': activity,
                'utility': min(utility, 1.0),
                'kg_score': kg_validation['score'],
                'reasons': reasons,
                'adaptations': adaptations,
                'evidence': kg_validation['evidence'],
                'center': center,
                'activity_type': activity_type
            })

        scored_activities.sort(key=lambda x: x['utility'], reverse=True)
        top_activities = self.llm_recommender.rerank_with_gpt4(patient, scored_activities[:6])

        recommendations = []
        for idx, act in enumerate(top_activities):
            activity = act['activity']

            base_duration = 30 if patient.ecog <= 1 and patient.fatigue < 0.5 else 20 if patient.fatigue < 0.7 else 15

            recommendations.append(ActivityRecommendation(
                id=f"rec_{idx}_{act['id']}",
                activity_type=act['activity_type'],
                title=activity['label'],
                description=self._generate_description(activity, act['adaptations'], patient),
                duration_minutes=base_duration,
                intensity=activity['intensity'],
                utility_score=round(act['utility'], 3),
                kg_validation_score=round(act['kg_score'], 3),
                combined_score=round(act['utility'], 3),
                reasons=act['reasons'] if act['reasons'] else ["Suitable for your current health status"],
                adaptations=act['adaptations'],
                kg_evidence=act['evidence'],
                center_name=act['center']['name'],
                center_address=act['center']['address']
            ))

        explanation = self.llm_recommender.generate_explanation(
            patient,
            [{'title': r.title} for r in recommendations]
        )

        param_changes = self._detect_changes(patient, request.previous_params)

        return RecommendationResponse(
            recommendations=recommendations,
            patient_profile=self.llm_recommender._patient_to_text(patient),
            kg_matched_profiles=[self.kg.profiles[p]['label'] for p in matched_profiles],
            llm_explanation=explanation,
            parameter_changes=param_changes
        )

    def _generate_description(self, activity: Dict, adaptations: List[str], patient: PatientData) -> str:
        desc = activity['label']

        if adaptations:
            desc += f" - {adaptations[0]}"
        elif patient.fatigue > 0.5:
            desc += " - Pace yourself and rest as needed"

        return desc

    def _detect_changes(self, patient: PatientData, previous: Optional[Dict]) -> List[str]:
        if not previous:
            return []

        changes = []

        if 'fatigue' in previous and abs(patient.fatigue - previous['fatigue']) > 0.1:
            direction = "increased" if patient.fatigue > previous['fatigue'] else "decreased"
            changes.append(f"Fatigue {direction}")

        if 'pain' in previous and abs(patient.pain - previous['pain']) > 0.1:
            direction = "increased" if patient.pain > previous['pain'] else "decreased"
            changes.append(f"Pain {direction}")

        if 'ecog' in previous and patient.ecog != previous['ecog']:
            changes.append(f"ECOG changed from {previous['ecog']} to {patient.ecog}")

        if 'systolic_bp' in previous and abs(patient.systolic_bp - previous['systolic_bp']) > 10:
            changes.append(f"Blood pressure changed")

        return changes

BASE_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'data')
KG_PATH = os.path.join(BASE_DIR, 'medical_guidelines.json')
CENTERS_PATH = os.path.join(BASE_DIR, 'sportsantecvl.json')

recommendation_service = None

@app.on_event("startup")
async def startup():
    global recommendation_service
    recommendation_service = RecommendationService(KG_PATH, CENTERS_PATH)
    print(f"Loaded KG from: {KG_PATH}")
    print(f"Loaded centers from: {CENTERS_PATH}")

@app.get("/")
async def root():
    return {
        "service": "APACare Recommendation API",
        "version": "1.0.0",
        "status": "running",
        "embeddings_available": EMBEDDINGS_AVAILABLE,
        "llm_available": OPENAI_AVAILABLE
    }

@app.post("/recommendations", response_model=RecommendationResponse)
async def get_recommendations(request: RecommendationRequest):
    if not recommendation_service:
        raise HTTPException(status_code=503, detail="Service not initialized")

    return recommendation_service.generate_recommendations(request)

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
