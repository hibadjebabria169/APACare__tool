import json
import os
from datetime import datetime

NAMESPACES = {
    'rdf': 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
    'rdfs': 'http://www.w3.org/2000/01/rdf-schema#',
    'owl': 'http://www.w3.org/2002/07/owl#',
    'xsd': 'http://www.w3.org/2001/XMLSchema#',
    'snomed': 'http://snomed.info/id/',
    'icd10': 'http://purl.bioontology.org/ontology/ICD10/',
    'onco': 'http://example.org/oncology-kg/',
    'fhir': 'http://hl7.org/fhir/',
    'dcterms': 'http://purl.org/dc/terms/',
}

def load_knowledge_graph(path: str) -> dict:
        with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)

def escape_turtle_string(s: str) -> str:
        return s.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n')

def generate_turtle(kg_data: dict) -> str:
        lines = []

    lines.append("# Oncology Knowledge Graph - RDF Export")
    lines.append(f"# Generated: {datetime.now().isoformat()}")
    lines.append(f"# SNOMED-CT Version: {kg_data.get('snomed_ct_version', 'unknown')}")
    lines.append("")

    for prefix, uri in NAMESPACES.items():
        lines.append(f"@prefix {prefix}: <{uri}> .")
    lines.append("")

    lines.append("# Ontology Metadata")
    lines.append("onco:OncologyKnowledgeGraph a owl:Ontology ;")
    lines.append('    rdfs:label "Oncology Physical Activity Knowledge Graph" ;')
    lines.append(f'    dcterms:created "{datetime.now().date().isoformat()}"^^xsd:date ;')
    lines.append(f'    owl:versionInfo "{kg_data.get("snomed_ct_version", "1.0")}" .')
    lines.append("")

    kg = kg_data.get('knowledge_graph', {})
    nodes = kg.get('nodes', {})

    lines.append("# ===== DISEASES =====")
    for disease in nodes.get('diseases', []):
        disease_uri = f"onco:{disease['id']}"
        lines.append(f"{disease_uri} a onco:Disease ;")
        lines.append(f'    rdfs:label "{escape_turtle_string(disease["label"])}" ;')
        if disease.get('snomed_code'):
            lines.append(f'    onco:snomedCode "{disease["snomed_code"]}" ;')
            lines.append(f'    rdfs:seeAlso snomed:{disease["snomed_code"]} ;')
        if disease.get('icd10'):
            lines.append(f'    onco:icd10Code "{disease["icd10"]}" ;')
        lines.append(f'    onco:snomedTerm "{escape_turtle_string(disease.get("snomed_term", ""))}" .')
        lines.append("")

    lines.append("# ===== CANCER STAGES =====")
    for stage in nodes.get('cancer_stages', []):
        stage_uri = f"onco:{stage['id']}"
        lines.append(f"{stage_uri} a onco:CancerStage ;")
        lines.append(f'    rdfs:label "{escape_turtle_string(stage["label"])}" ;')
        if stage.get('snomed_code'):
            lines.append(f'    onco:snomedCode "{stage["snomed_code"]}" ;')
            lines.append(f'    rdfs:seeAlso snomed:{stage["snomed_code"]} ;')
        lines.append(f'    onco:snomedTerm "{escape_turtle_string(stage.get("snomed_term", ""))}" .')
        lines.append("")

    lines.append("# ===== TREATMENTS =====")
    for treatment in nodes.get('treatments', []):
        treatment_uri = f"onco:{treatment['id']}"
        lines.append(f"{treatment_uri} a onco:Treatment ;")
        lines.append(f'    rdfs:label "{escape_turtle_string(treatment["label"])}" ;')
        if treatment.get('snomed_code'):
            lines.append(f'    onco:snomedCode "{treatment["snomed_code"]}" ;')
            lines.append(f'    rdfs:seeAlso snomed:{treatment["snomed_code"]} ;')
        lines.append(f'    onco:snomedTerm "{escape_turtle_string(treatment.get("snomed_term", ""))}" .')
        lines.append("")

    lines.append("# ===== CHEMOTHERAPY DRUGS =====")
    for drug in nodes.get('chemotherapy_drugs', []):
        drug_uri = f"onco:{drug['id']}"
        lines.append(f"{drug_uri} a onco:ChemotherapyDrug ;")
        lines.append(f'    rdfs:label "{escape_turtle_string(drug["label"])}" ;')
        if drug.get('snomed_code'):
            lines.append(f'    onco:snomedCode "{drug["snomed_code"]}" ;')
            lines.append(f'    rdfs:seeAlso snomed:{drug["snomed_code"]} ;')
        if drug.get('drug_class'):
            lines.append(f'    onco:drugClass "{drug["drug_class"]}" ;')
        for se in drug.get('common_side_effects', []):
            lines.append(f'    onco:hasSideEffect onco:{se} ;')
        lines.append(f'    onco:snomedTerm "{escape_turtle_string(drug.get("snomed_term", ""))}" .')
        lines.append("")

    lines.append("# ===== SIDE EFFECTS =====")
    for effect in nodes.get('side_effects', []):
        effect_uri = f"onco:{effect['id']}"
        lines.append(f"{effect_uri} a onco:SideEffect ;")
        lines.append(f'    rdfs:label "{escape_turtle_string(effect["label"])}" ;')
        if effect.get('snomed_code'):
            lines.append(f'    onco:snomedCode "{effect["snomed_code"]}" ;')
            lines.append(f'    rdfs:seeAlso snomed:{effect["snomed_code"]} ;')
        lines.append(f'    onco:snomedTerm "{escape_turtle_string(effect.get("snomed_term", ""))}" .')
        lines.append("")

    lines.append("# ===== CONDITIONS =====")
    for condition in nodes.get('conditions', []):
        condition_uri = f"onco:{condition['id']}"
        lines.append(f"{condition_uri} a onco:Condition ;")
        lines.append(f'    rdfs:label "{escape_turtle_string(condition["label"])}" ;')
        if condition.get('snomed_code'):
            lines.append(f'    onco:snomedCode "{condition["snomed_code"]}" ;')
            lines.append(f'    rdfs:seeAlso snomed:{condition["snomed_code"]} ;')
        lines.append(f'    onco:snomedTerm "{escape_turtle_string(condition.get("snomed_term", ""))}" .')
        lines.append("")

    lines.append("# ===== ACTIVITIES =====")
    for activity in nodes.get('activities', []):
        activity_uri = f"onco:{activity['id']}"
        lines.append(f"{activity_uri} a onco:PhysicalActivity ;")
        lines.append(f'    rdfs:label "{escape_turtle_string(activity["label"])}" ;')
        if activity.get('snomed_code'):
            lines.append(f'    onco:snomedCode "{activity["snomed_code"]}" ;')
            lines.append(f'    rdfs:seeAlso snomed:{activity["snomed_code"]} ;')
        if activity.get('intensity'):
            lines.append(f'    onco:intensity "{activity["intensity"]}" ;')
        if activity.get('met'):
            lines.append(f'    onco:metValue {activity["met"]} ;')
        lines.append(f'    onco:snomedTerm "{escape_turtle_string(activity.get("snomed_term", ""))}" .')
        lines.append("")

    lines.append("# ===== PATIENT PROFILES =====")
    for profile in nodes.get('profiles', []):
        profile_uri = f"onco:{profile['id']}"
        lines.append(f"{profile_uri} a onco:PatientProfile ;")
        lines.append(f'    rdfs:label "{escape_turtle_string(profile["label"])}" ;')
        for cond in profile.get('conditions', []):
            lines.append(f'    onco:hasCondition onco:{cond} ;')
        lines.append(f'    rdfs:comment "{escape_turtle_string(profile.get("description", ""))}" .')
        lines.append("")

    edges = kg.get('edges', {})
    lines.append("# ===== RECOMMENDATION EDGES =====")
    for i, rec in enumerate(edges.get('recommends', [])):
        rec_uri = f"onco:recommendation_{i}"
        lines.append(f"{rec_uri} a onco:Recommendation ;")
        lines.append(f'    onco:fromProfile onco:{rec["from"]} ;')
        lines.append(f'    onco:toActivity onco:{rec["to"]} ;')
        lines.append(f'    onco:weight {rec["weight"]} ;')
        lines.append(f'    onco:evidence "{escape_turtle_string(rec["evidence"])}" ;')
        if rec.get('snomed_supports'):
            lines.append(f'    onco:snomedSupports snomed:{rec["snomed_supports"]} ;')
        lines.append(".")
        lines.append("")

    lines.append("# ===== CONTRAINDICATION EDGES =====")
    for i, contra in enumerate(edges.get('contraindicates', [])):
        contra_uri = f"onco:contraindication_{i}"
        lines.append(f"{contra_uri} a onco:Contraindication ;")
        lines.append(f'    onco:fromCondition onco:{contra["from"]} ;')
        lines.append(f'    onco:toActivity onco:{contra["to"]} ;')
        lines.append(f'    onco:reason "{escape_turtle_string(contra["reason"])}" ;')
        if contra.get('snomed_reason'):
            lines.append(f'    onco:snomedReason snomed:{contra["snomed_reason"]} ;')
        lines.append(".")
        lines.append("")

    lines.append("# ===== ADAPTATION EDGES =====")
    for i, adapt in enumerate(edges.get('adapts', [])):
        adapt_uri = f"onco:adaptation_{i}"
        lines.append(f"{adapt_uri} a onco:Adaptation ;")
        lines.append(f'    onco:forCondition onco:{adapt["condition"]} ;')
        lines.append(f'    onco:forActivity onco:{adapt["activity"]} ;')
        lines.append(f'    onco:adaptationText "{escape_turtle_string(adapt["adaptation"])}" ;')
        if adapt.get('snomed_condition'):
            lines.append(f'    onco:snomedCondition snomed:{adapt["snomed_condition"]} ;')
        lines.append(".")
        lines.append("")

    return '\n'.join(lines)

def export_to_rdf(input_path: str, output_path: str):
        print(f"Loading knowledge graph from {input_path}...")
    kg_data = load_knowledge_graph(input_path)

    print("Generating RDF/Turtle...")
    turtle_content = generate_turtle(kg_data)

    print(f"Writing to {output_path}...")
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(turtle_content)

    kg = kg_data.get('knowledge_graph', {})
    nodes = kg.get('nodes', {})
    edges = kg.get('edges', {})

    print("\n" + "=" * 50)
    print("RDF Export Summary")
    print("=" * 50)
    print(f"Diseases:      {len(nodes.get('diseases', []))}")
    print(f"Cancer Stages: {len(nodes.get('cancer_stages', []))}")
    print(f"Treatments:    {len(nodes.get('treatments', []))}")
    print(f"Drugs:         {len(nodes.get('chemotherapy_drugs', []))}")
    print(f"Side Effects:  {len(nodes.get('side_effects', []))}")
    print(f"Conditions:    {len(nodes.get('conditions', []))}")
    print(f"Activities:    {len(nodes.get('activities', []))}")
    print(f"Profiles:      {len(nodes.get('profiles', []))}")
    print(f"Recommendations: {len(edges.get('recommends', []))}")
    print(f"Contraindications: {len(edges.get('contraindicates', []))}")
    print(f"Adaptations:   {len(edges.get('adapts', []))}")
    print("=" * 50)
    print(f"[OK] Exported to: {output_path}")

if __name__ == "__main__":
    script_dir = os.path.dirname(os.path.abspath(__file__))
    input_file = os.path.join(script_dir, '..', 'medical_guidelines.json')
    output_file = os.path.join(script_dir, '..', 'exports', 'oncology_kg.ttl')

    os.makedirs(os.path.dirname(output_file), exist_ok=True)

    export_to_rdf(input_file, output_file)
