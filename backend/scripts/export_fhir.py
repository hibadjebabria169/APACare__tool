import json
import os
import uuid
from datetime import datetime

FHIR_VERSION = "4.0.1"
SNOMED_SYSTEM = "http://snomed.info/sct"
ICD10_SYSTEM = "http://hl7.org/fhir/sid/icd-10"

def load_knowledge_graph(path: str) -> dict:
        with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)

def create_fhir_bundle(resources: list, bundle_type: str = "collection") -> dict:
        return {
        "resourceType": "Bundle",
        "id": str(uuid.uuid4()),
        "type": bundle_type,
        "timestamp": datetime.now().isoformat() + "Z",
        "total": len(resources),
        "entry": [{"resource": r} for r in resources]
    }

def create_code_system(kg_data: dict) -> dict:
        concepts = []

    kg = kg_data.get('knowledge_graph', {})
    nodes = kg.get('nodes', {})

    for disease in nodes.get('diseases', []):
        concept = {
            "code": disease['id'],
            "display": disease['label'],
            "designation": []
        }
        if disease.get('snomed_code'):
            concept["designation"].append({
                "use": {"system": SNOMED_SYSTEM, "code": "900000000000003001"},
                "value": disease.get('snomed_term', disease['label'])
            })
        concepts.append(concept)

    for activity in nodes.get('activities', []):
        concept = {
            "code": activity['id'],
            "display": activity['label'],
            "property": []
        }
        if activity.get('intensity'):
            concept["property"].append({
                "code": "intensity",
                "valueString": activity['intensity']
            })
        if activity.get('met'):
            concept["property"].append({
                "code": "met-value",
                "valueDecimal": activity['met']
            })
        concepts.append(concept)

    return {
        "resourceType": "CodeSystem",
        "id": "oncology-kg-codes",
        "url": "http://example.org/fhir/CodeSystem/oncology-kg",
        "version": kg_data.get('snomed_ct_version', '1.0'),
        "name": "OncologyKnowledgeGraphCodeSystem",
        "title": "Oncology Knowledge Graph Code System",
        "status": "active",
        "experimental": True,
        "date": datetime.now().date().isoformat(),
        "publisher": "Oncology KG Project",
        "description": "Code system for oncology physical activity recommendations",
        "content": "complete",
        "count": len(concepts),
        "concept": concepts
    }

def create_activity_definition(activity: dict) -> dict:
        definition = {
        "resourceType": "ActivityDefinition",
        "id": activity['id'],
        "url": f"http://example.org/fhir/ActivityDefinition/{activity['id']}",
        "status": "active",
        "name": activity['id'].replace('_', ' ').title(),
        "title": activity['label'],
        "kind": "ServiceRequest",
        "code": {
            "coding": [{
                "system": "http://example.org/fhir/CodeSystem/oncology-kg",
                "code": activity['id'],
                "display": activity['label']
            }]
        },
        "description": f"Physical activity recommendation: {activity['label']}"
    }

    if activity.get('snomed_code'):
        definition["code"]["coding"].append({
            "system": SNOMED_SYSTEM,
            "code": activity['snomed_code'],
            "display": activity.get('snomed_term', activity['label'])
        })

    if activity.get('intensity'):
        definition["extension"] = definition.get("extension", [])
        definition["extension"].append({
            "url": "http://example.org/fhir/StructureDefinition/activity-intensity",
            "valueCode": activity['intensity']
        })

    if activity.get('met'):
        definition["extension"] = definition.get("extension", [])
        definition["extension"].append({
            "url": "http://example.org/fhir/StructureDefinition/met-value",
            "valueDecimal": activity['met']
        })

    return definition

def create_condition_resource(condition: dict) -> dict:
        resource = {
        "resourceType": "Condition",
        "id": condition['id'],
        "code": {
            "coding": [{
                "system": "http://example.org/fhir/CodeSystem/oncology-kg",
                "code": condition['id'],
                "display": condition['label']
            }],
            "text": condition['label']
        },
        "clinicalStatus": {
            "coding": [{
                "system": "http://terminology.hl7.org/CodeSystem/condition-clinical",
                "code": "active"
            }]
        }
    }

    if condition.get('snomed_code'):
        resource["code"]["coding"].append({
            "system": SNOMED_SYSTEM,
            "code": condition['snomed_code'],
            "display": condition.get('snomed_term', condition['label'])
        })

    return resource

def create_medication_knowledge(drug: dict) -> dict:
        resource = {
        "resourceType": "MedicationKnowledge",
        "id": drug['id'],
        "code": {
            "coding": [{
                "system": "http://example.org/fhir/CodeSystem/oncology-kg",
                "code": drug['id'],
                "display": drug['label']
            }]
        },
        "status": "active",
        "associatedMedication": [],
        "relatedMedicationKnowledge": []
    }

    if drug.get('snomed_code'):
        resource["code"]["coding"].append({
            "system": SNOMED_SYSTEM,
            "code": drug['snomed_code'],
            "display": drug.get('snomed_term', drug['label'])
        })

    if drug.get('drug_class'):
        resource["drugCharacteristic"] = [{
            "type": {
                "coding": [{
                    "system": "http://example.org/fhir/CodeSystem/drug-characteristic",
                    "code": "drug-class"
                }]
            },
            "valueString": drug['drug_class']
        }]

    if drug.get('common_side_effects'):
        resource["contraindication"] = []
        for se in drug['common_side_effects']:
            resource["contraindication"].append({
                "diseaseSymptomProcedure": {
                    "coding": [{
                        "system": "http://example.org/fhir/CodeSystem/oncology-kg",
                        "code": se,
                        "display": se.replace('_', ' ').title()
                    }]
                }
            })

    return resource

def create_plan_definition(profile: dict, recommendations: list) -> dict:

    profile_recs = [r for r in recommendations if r.get('from') == profile['id']]

    actions = []
    for rec in profile_recs:
        action = {
            "title": rec.get('to', '').replace('_', ' ').title(),
            "description": f"Recommended activity based on {rec.get('evidence', 'clinical guidelines')}",
            "definitionCanonical": f"http://example.org/fhir/ActivityDefinition/{rec.get('to')}",
            "condition": [{
                "kind": "applicability",
                "expression": {
                    "language": "text/fhirpath",
                    "expression": f"weight >= {rec.get('weight', 0.5)}"
                }
            }]
        }
        actions.append(action)

    return {
        "resourceType": "PlanDefinition",
        "id": profile['id'],
        "url": f"http://example.org/fhir/PlanDefinition/{profile['id']}",
        "status": "active",
        "name": profile['id'].replace('_', ' ').title(),
        "title": profile['label'],
        "description": profile.get('description', f"Activity recommendations for {profile['label']}"),
        "type": {
            "coding": [{
                "system": "http://terminology.hl7.org/CodeSystem/plan-definition-type",
                "code": "clinical-protocol"
            }]
        },
        "action": actions
    }

def create_library(kg_data: dict) -> dict:
        return {
        "resourceType": "Library",
        "id": "oncology-kg-library",
        "url": "http://example.org/fhir/Library/oncology-kg",
        "version": kg_data.get('snomed_ct_version', '1.0'),
        "name": "OncologyKnowledgeGraphLibrary",
        "title": "Oncology Physical Activity Knowledge Graph Library",
        "status": "active",
        "type": {
            "coding": [{
                "system": "http://terminology.hl7.org/CodeSystem/library-type",
                "code": "logic-library"
            }]
        },
        "date": datetime.now().date().isoformat(),
        "publisher": "Oncology KG Project",
        "description": "FHIR Library containing oncology physical activity recommendation knowledge",
        "relatedArtifact": [
            {
                "type": "derived-from",
                "display": "SNOMED CT",
                "url": "http://snomed.info/sct"
            },
            {
                "type": "derived-from",
                "display": "ACSM Exercise Guidelines for Cancer Survivors",
                "citation": "ACSM Guidelines 2019"
            },
            {
                "type": "derived-from",
                "display": "NCCN Clinical Practice Guidelines",
                "citation": "NCCN Guidelines"
            }
        ]
    }

def export_to_fhir(input_path: str, output_dir: str):
        print(f"Loading knowledge graph from {input_path}...")
    kg_data = load_knowledge_graph(input_path)

    kg = kg_data.get('knowledge_graph', {})
    nodes = kg.get('nodes', {})
    edges = kg.get('edges', {})

    resources = []

    print("Creating Library resource...")
    resources.append(create_library(kg_data))

    print("Creating CodeSystem...")
    resources.append(create_code_system(kg_data))

    print("Creating ActivityDefinitions...")
    for activity in nodes.get('activities', []):
        resources.append(create_activity_definition(activity))

    print("Creating Condition resources...")
    for condition in nodes.get('conditions', []):
        resources.append(create_condition_resource(condition))

    print("Creating MedicationKnowledge resources...")
    for drug in nodes.get('chemotherapy_drugs', []):
        resources.append(create_medication_knowledge(drug))

    print("Creating PlanDefinitions...")
    recommendations = edges.get('recommends', [])
    for profile in nodes.get('profiles', []):
        resources.append(create_plan_definition(profile, recommendations))

    print("Creating FHIR Bundle...")
    bundle = create_fhir_bundle(resources)

    os.makedirs(output_dir, exist_ok=True)
    output_file = os.path.join(output_dir, 'oncology_kg_bundle.json')
    print(f"Writing to {output_file}...")
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(bundle, f, indent=2, ensure_ascii=False)

    print("Writing individual resources...")

    activities_file = os.path.join(output_dir, 'activity_definitions.json')
    activity_resources = [r for r in resources if r.get('resourceType') == 'ActivityDefinition']
    with open(activities_file, 'w', encoding='utf-8') as f:
        json.dump(create_fhir_bundle(activity_resources), f, indent=2, ensure_ascii=False)

    plans_file = os.path.join(output_dir, 'plan_definitions.json')
    plan_resources = [r for r in resources if r.get('resourceType') == 'PlanDefinition']
    with open(plans_file, 'w', encoding='utf-8') as f:
        json.dump(create_fhir_bundle(plan_resources), f, indent=2, ensure_ascii=False)

    print("\n" + "=" * 50)
    print("FHIR Export Summary")
    print("=" * 50)
    print(f"FHIR Version: {FHIR_VERSION}")
    print(f"Total Resources: {len(resources)}")
    print(f"  - Library: 1")
    print(f"  - CodeSystem: 1")
    print(f"  - ActivityDefinitions: {len(activity_resources)}")
    print(f"  - Conditions: {len([r for r in resources if r.get('resourceType') == 'Condition'])}")
    print(f"  - MedicationKnowledge: {len([r for r in resources if r.get('resourceType') == 'MedicationKnowledge'])}")
    print(f"  - PlanDefinitions: {len(plan_resources)}")
    print("=" * 50)
    print(f"[OK] Bundle exported to: {output_file}")
    print(f"[OK] Activities exported to: {activities_file}")
    print(f"[OK] Plans exported to: {plans_file}")

if __name__ == "__main__":
    script_dir = os.path.dirname(os.path.abspath(__file__))
    input_file = os.path.join(script_dir, '..', 'medical_guidelines.json')
    output_directory = os.path.join(script_dir, '..', 'exports', 'fhir')

    export_to_fhir(input_file, output_directory)
