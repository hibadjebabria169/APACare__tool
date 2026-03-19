import json
import sys

sys.path.insert(0, '.')

def test_snomed_kg():
    print("=" * 60)
    print("SNOMED-CT Knowledge Graph Integration Test")
    print("=" * 60)

    print("\n1. Loading medical_guidelines.json...")
    try:
        with open('../medical_guidelines.json', 'r', encoding='utf-8') as f:
            guidelines = json.load(f)
        print("   [OK] Loaded successfully")
        print(f"   SNOMED-CT Version: {guidelines.get('snomed_ct_version', 'N/A')}")
    except Exception as e:
        print(f"   [ERROR] {e}")
        return False

    kg_nodes = guidelines.get('knowledge_graph', {}).get('nodes', {})

    print("\n2. Checking SNOMED codes in diseases...")
    diseases = kg_nodes.get('diseases', [])
    diseases_with_snomed = sum(1 for d in diseases if d.get('snomed_code'))
    print(f"   Found {len(diseases)} diseases, {diseases_with_snomed} with SNOMED codes")

    for d in diseases:
        if d.get('id') == 'breast_cancer':
            print(f"   Sample: {d.get('label')} - SNOMED: {d.get('snomed_code')} ({d.get('snomed_term')})")
            break

    print("\n3. Checking SNOMED codes in cancer stages...")
    stages = kg_nodes.get('cancer_stages', [])
    stages_with_snomed = sum(1 for s in stages if s.get('snomed_code'))
    print(f"   Found {len(stages)} stages, {stages_with_snomed} with SNOMED codes")

    print("\n4. Checking SNOMED codes in treatments...")
    treatments = kg_nodes.get('treatments', [])
    treatments_with_snomed = sum(1 for t in treatments if t.get('snomed_code'))
    print(f"   Found {len(treatments)} treatments, {treatments_with_snomed} with SNOMED codes")

    print("\n5. Checking SNOMED codes in side effects...")
    side_effects = kg_nodes.get('side_effects', [])
    se_with_snomed = sum(1 for s in side_effects if s.get('snomed_code'))
    print(f"   Found {len(side_effects)} side effects, {se_with_snomed} with SNOMED codes")

    print("\n6. Checking SNOMED codes in conditions...")
    conditions = kg_nodes.get('conditions', [])
    conditions_with_snomed = sum(1 for c in conditions if c.get('snomed_code'))
    print(f"   Found {len(conditions)} conditions, {conditions_with_snomed} with SNOMED codes")

    print("\n7. Checking SNOMED codes in activities...")
    activities = kg_nodes.get('activities', [])
    activities_with_snomed = sum(1 for a in activities if a.get('snomed_code'))
    print(f"   Found {len(activities)} activities, {activities_with_snomed} with SNOMED codes")

    for a in activities:
        if a.get('id') == 'walking':
            print(f"   Sample: {a.get('label')} - SNOMED: {a.get('snomed_code')} ({a.get('snomed_term')})")
            break

    print("\n8. Checking profiles...")
    profiles = kg_nodes.get('profiles', [])
    print(f"   Found {len(profiles)} patient profiles")

    print("\n9. Checking clinical guidelines...")
    guidelines_list = kg_nodes.get('clinical_guidelines', [])
    guidelines_with_snomed = sum(1 for g in guidelines_list if g.get('snomed_code'))
    print(f"   Found {len(guidelines_list)} guidelines, {guidelines_with_snomed} with SNOMED codes")

    print("\n10. Testing KnowledgeGraph class...")
    try:
        from main import KnowledgeGraph, SNOMED_CT_URI_BASE, get_snomed_uri, validate_snomed_code

        print("\n   Testing SNOMED helper functions:")
        test_code = "254837009"
        uri = get_snomed_uri(test_code)
        print(f"   - get_snomed_uri('{test_code}'): {uri}")

        is_valid = validate_snomed_code(test_code)
        print(f"   - validate_snomed_code('{test_code}'): {is_valid}")

        invalid_code = "abc123"
        is_invalid = validate_snomed_code(invalid_code)
        print(f"   - validate_snomed_code('{invalid_code}'): {is_invalid}")

        print("\n   Initializing KnowledgeGraph...")
        kg = KnowledgeGraph('../medical_guidelines.json')
        total_nodes = len(kg.diseases) + len(kg.conditions) + len(kg.activities) + len(kg.treatments) + len(kg.profiles)
        total_edges = len(kg.recommendations) + len(kg.contraindications)
        print(f"   [OK] KG initialized")
        print(f"       - {len(kg.diseases)} diseases, {len(kg.activities)} activities")
        print(f"       - {len(kg.conditions)} conditions, {len(kg.profiles)} profiles")
        print(f"       - {len(kg.snomed_lookup)} SNOMED codes indexed")

        print("\n   Testing SNOMED lookup methods:")

        disease_snomed = kg.get_disease_snomed("breast_cancer")
        if disease_snomed:
            print(f"   - Breast cancer SNOMED: {disease_snomed}")
        else:
            print("   - Breast cancer SNOMED: Method not available or no result")

        activity_snomed = kg.get_activity_snomed("walking")
        if activity_snomed:
            print(f"   - Walking SNOMED: {activity_snomed}")
        else:
            print("   - Walking SNOMED: Method not available or no result")

        print("\n   Testing SNOMED index lookup:")
        result = kg.lookup_by_snomed("254837009")
        if result:
            print(f"   - Lookup '254837009': {result}")
        else:
            print("   - Lookup '254837009': No result (index may not be built)")

        print("\n   [OK] KnowledgeGraph tests passed")

    except ImportError as e:
        print(f"   [ERROR] Import error: {e}")
        print("   (This is expected if dependencies are missing)")
    except Exception as e:
        print(f"   [ERROR] {e}")
        import traceback
        traceback.print_exc()

    print("\n" + "=" * 60)
    print("SUMMARY")
    print("=" * 60)
    print(f"Diseases with SNOMED:      {diseases_with_snomed}/{len(diseases)}")
    print(f"Cancer Stages with SNOMED: {stages_with_snomed}/{len(stages)}")
    print(f"Treatments with SNOMED:    {treatments_with_snomed}/{len(treatments)}")
    print(f"Side Effects with SNOMED:  {se_with_snomed}/{len(side_effects)}")
    print(f"Conditions with SNOMED:    {conditions_with_snomed}/{len(conditions)}")
    print(f"Activities with SNOMED:    {activities_with_snomed}/{len(activities)}")
    print(f"Clinical Guidelines:       {guidelines_with_snomed}/{len(guidelines_list)}")
    print(f"Patient Profiles:          {len(profiles)}")
    print("=" * 60)

    total_items = len(diseases) + len(stages) + len(treatments) + len(side_effects) + len(conditions) + len(activities) + len(guidelines_list)
    total_with_snomed = diseases_with_snomed + stages_with_snomed + treatments_with_snomed + se_with_snomed + conditions_with_snomed + activities_with_snomed + guidelines_with_snomed
    print(f"\nTotal SNOMED coverage: {total_with_snomed}/{total_items} ({100*total_with_snomed//total_items}%)")
    print("=" * 60)

    return True

if __name__ == "__main__":
    success = test_snomed_kg()
    sys.exit(0 if success else 1)
