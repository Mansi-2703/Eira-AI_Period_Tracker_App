"""
HerCycle Quiz Questions - Structured, Professional, Playful
============================================================
Comprehensive quiz questions covering menstrual health disorders and lifestyle factors.
Organized by category with scoring guidance for disorder detection.
"""

QUIZ_SECTIONS = {
    # ============================================================================
    # SECTION 1: FLOW & BLEEDING PATTERN (Detects: Menorrhagia, Hormonal issues)
    # ============================================================================
    "flow_and_bleeding": {
        "title": "Your Period Flow 🩸",
        "description": "Help us understand your flow patterns",
        "questions": [
            {
                "id": "flow_intensity",
                "question": "How would you describe your period flow?",
                "type": "single_choice",
                "field": "flow_intensity",
                "options": [
                    {"value": 1, "label": "Light (barely need protection)"},
                    {"value": 2, "label": "Light-Moderate (fewer changes)"},
                    {"value": 3, "label": "Moderate (normal changes)"},
                    {"value": 4, "label": "Heavy (frequent changes)"},
                    {"value": 5, "label": "Very heavy (need frequent changes)"},
                ],
                "risk_indicator": "Higher values may indicate Menorrhagia or hormonal imbalances",
            },
            {
                "id": "pad_change_frequency",
                "question": "How often do you need to change your pad/tampon during the heaviest days?",
                "type": "single_choice",
                "field": "pad_change_frequency",
                "options": [
                    {"value": 1, "label": "Few times a day"},
                    {"value": 2, "label": "Every few hours"},
                    {"value": 3, "label": "Every 2-3 hours"},
                    {"value": 4, "label": "Hourly"},
                    {"value": 5, "label": "Every 30 minutes - I need double protection"},
                ],
                "risk_indicator": "Values 4-5 may indicate Menorrhagia",
            },
            {
                "id": "flooding",
                "question": "Do you experience flooding (blood soaking through protection)?",
                "type": "single_choice",
                "field": "flooding",
                "options": [
                    {"value": 0, "label": "No, never"},
                    {"value": 1, "label": "Occasionally"},
                    {"value": 2, "label": "Frequently during my period"},
                ],
                "risk_indicator": "Flooding can indicate Menorrhagia or underlying conditions",
            },
            {
                "id": "clot_size",
                "question": "Do you pass blood clots? If yes, how large?",
                "type": "single_choice",
                "field": "clot_size",
                "options": [
                    {"value": 0, "label": "No clots"},
                    {"value": 1, "label": "Yes, smaller than a dime"},
                    {"value": 2, "label": "Yes, larger than a quarter"},
                ],
                "risk_indicator": "Large clots may indicate Menorrhagia or tissue complications",
            },
        ],
    },

    # ============================================================================
    # SECTION 2: CYCLE REGULARITY (Detects: PCOS, Irregular cycles, Amenorrhea)
    # ============================================================================
    "cycle_regularity": {
        "title": "Your Cycle Pattern 🔄",
        "description": "Understanding your cycle consistency",
        "questions": [
            {
                "id": "cycle_regular",
                "question": "How regular is your menstrual cycle?",
                "type": "single_choice",
                "field": "cycle_regular",
                "options": [
                    {"value": 1, "label": "Very regular (comes like clockwork ⏰)"},
                    {"value": 2, "label": "Usually regular (1-3 day variation)"},
                    {"value": 3, "label": "Somewhat irregular (4-7 day variation)"},
                    {"value": 4, "label": "Highly irregular (unpredictable)"},
                ],
                "risk_indicator": "Irregular cycles may suggest PCOS, hormonal imbalances, or lifestyle stress",
            },
            {
                "id": "avg_cycle_group",
                "question": "What's your average cycle length (day 1 of period to day 1 of next)?",
                "type": "single_choice",
                "field": "avg_cycle_group",
                "options": [
                    {"value": 1, "label": "Shorter (under 24 days)"},
                    {"value": 2, "label": "Normal (24-38 days) ✓"},
                    {"value": 3, "label": "Longer (38+ days)"},
                    {"value": 4, "label": "Highly variable (no consistent length)"},
                ],
                "risk_indicator": "Very short or long cycles, or extreme variability, may indicate hormonal issues or PCOS",
            },
            {
                "id": "missed_periods",
                "question": "In the past year, have you had missed or skipped periods?",
                "type": "single_choice",
                "field": "missed_periods",
                "options": [
                    {"value": 0, "label": "No, never (or rarely)"},
                    {"value": 1, "label": "Yes, a few times"},
                    {"value": 2, "label": "Yes, frequently (Amenorrhea/Oligomenorrhea)"},
                ],
                "risk_indicator": "Frequently missed periods suggest hormonal issues, stress, weight loss, or PCOS",
            },
            {
                "id": "spotting_between",
                "question": "Do you experience spotting or bleeding between periods?",
                "type": "single_choice",
                "field": "spotting_between",
                "options": [
                    {"value": 0, "label": "No, my cycle is clean"},
                    {"value": 1, "label": "Rarely, just occasional spots"},
                    {"value": 2, "label": "Yes, regularly (Intermenstrual bleeding)"},
                ],
                "risk_indicator": "Intermenstrual bleeding may indicate hormonal imbalances, infections, or fibroids",
            },
        ],
    },

    # ============================================================================
    # SECTION 3: PERIOD DURATION (Detects: Menorrhagia, Dystonic patterns)
    # ============================================================================
    "period_duration": {
        "title": "Your Period Duration ⏱️",
        "description": "How long your period typically lasts",
        "questions": [
            {
                "id": "period_duration",
                "question": "How many days does your period usually last?",
                "type": "number_input",
                "field": "period_duration",
                "placeholder": "Enter number of days",
                "normal_range": [4, 7],
                "risk_indicator": "Periods lasting over 7 days may indicate Menorrhagia",
            },
            {
                "id": "flow_pattern",
                "question": "How does your flow pattern look over those days?",
                "type": "single_choice",
                "field": "flow_pattern",
                "options": [
                    {"value": 1, "label": "Stable (consistent flow throughout)"},
                    {"value": 2, "label": "Typical (heavy first 2 days, then lighter)"},
                    {"value": 3, "label": "Unpredictable (varies day to day)"},
                    {"value": 4, "label": "Erratic (heavy one day, light the next) 🎢"},
                ],
                "risk_indicator": "Erratic patterns may suggest hormonal imbalances or uterine issues",
            },
        ],
    },

    # ============================================================================
    # SECTION 4: PAIN & CRAMPING (Detects: Dysmenorrhea, Endometriosis)
    # ============================================================================
    "pain_and_cramping": {
        "title": "Period Pain & Cramping 😖",
        "description": "Understanding your menstrual discomfort",
        "questions": [
            {
                "id": "pain_level",
                "question": "How would you rate your period pain intensity?",
                "type": "single_choice",
                "field": "pain_level",
                "options": [
                    {"value": 0, "label": "No pain (lucky you! 🎉)"},
                    {"value": 1, "label": "Mild (noticeable but manageable)"},
                    {"value": 2, "label": "Moderate (takes ibuprofen to manage)"},
                    {"value": 3, "label": "Severe (debilitating, hard to function)"},
                ],
                "risk_indicator": "Severe pain suggests primary Dysmenorrhea or Endometriosis",
            },
            {
                "id": "pain_location",
                "question": "Where do you experience the most pain?",
                "type": "single_choice",
                "field": "pain_location",
                "options": [
                    {"value": "lower_abdomen", "label": "Lower abdomen (cramp zone)"},
                    {"value": "lower_back", "label": "Lower back"},
                    {"value": "thighs", "label": "Thighs"},
                    {"value": "all_of_above", "label": "All of the above 😢"},
                ],
                "risk_indicator": "Pain in multiple areas suggests severe Dysmenorrhea or Endometriosis",
            },
            {
                "id": "pain_type",
                "question": "How would you describe your pain?",
                "type": "single_choice",
                "field": "pain_type",
                "options": [
                    {"value": "cramping", "label": "Cramping (most common)"},
                    {"value": "throbbing", "label": "Throbbing"},
                    {"value": "aching", "label": "Aching"},
                    {"value": "sharp", "label": "Sharp/stabbing pain"},
                ],
                "risk_indicator": "Sharp or throbbing pain may indicate Dysmenorrhea or Endometriosis",
            },
            {
                "id": "pain_interference",
                "question": "How much does pain affect your daily life during your period?",
                "type": "single_choice",
                "field": "pain_interference",
                "options": [
                    {"value": 0, "label": "No impact (I'm good to go)"},
                    {"value": 1, "label": "Mild impact (a little uncomfortable)"},
                    {"value": 2, "label": "Moderate impact (I need to slow down)"},
                    {"value": 3, "label": "Severe impact (I can't function normally) - This is Dysmenorrhea"},
                ],
                "risk_indicator": "Severe interference indicates primary Dysmenorrhea requiring attention",
            },
        ],
    },

    # ============================================================================
    # SECTION 5: PRE-MENSTRUAL SYMPTOMS (Detects: PMS, PMDD)
    # ============================================================================
    "premenstrual_symptoms": {
        "title": "Before Your Period (Week or Two Before?) 🌙",
        "description": "Pre-menstrual symptoms help us detect PMS and PMDD",
        "questions": [
            {
                "id": "pms_mood_swings",
                "question": "Do you experience mood swings in the days before your period?",
                "type": "single_choice",
                "field": "pms_mood_swings",
                "options": [
                    {"value": 0, "label": "No mood changes"},
                    {"value": 1, "label": "Slight mood variations"},
                    {"value": 2, "label": "Noticeable mood swings"},
                    {"value": 3, "label": "Intense mood swings (from happy to sad quickly)"},
                ],
                "risk_indicator": "Intense mood swings are a hallmark of PMS",
            },
            {
                "id": "pms_irritability",
                "question": "Do you feel more irritable or short-tempered before your period?",
                "type": "single_choice",
                "field": "pms_irritability",
                "options": [
                    {"value": 0, "label": "Not really"},
                    {"value": 1, "label": "A little"},
                    {"value": 2, "label": "Yes, noticeably"},
                    {"value": 3, "label": "Yes, severely (road rage level! 😤)"},
                ],
                "risk_indicator": "Severe irritability indicates PMS",
            },
            {
                "id": "pms_depression_anxiety",
                "question": "Do you experience depression, anxiety, or feelings of being overwhelmed before your period?",
                "type": "single_choice",
                "field": "pms_depression_anxiety",
                "options": [
                    {"value": 0, "label": "No"},
                    {"value": 1, "label": "Mild sadness or worry"},
                    {"value": 2, "label": "Moderate depression or anxiety"},
                    {"value": 3, "label": "Severe depression/anxiety (this is PMDD ⚠️)"},
                ],
                "risk_indicator": "Severe depression/anxiety before period indicates PMDD - seek medical advice",
            },
            {
                "id": "pms_breast_tenderness",
                "question": "Do you experience breast tenderness before your period?",
                "type": "toggle",
                "field": "pms_breast_tenderness",
                "risk_indicator": "Breast tenderness is a common PMS symptom",
            },
            {
                "id": "pms_bloating",
                "question": "Do you feel bloated before your period?",
                "type": "toggle",
                "field": "pms_bloating",
                "risk_indicator": "Water retention and bloating are typical PMS symptoms",
            },
            {
                "id": "pms_joint_muscle_pain",
                "question": "Do you experience joint or muscle pain/aches before your period?",
                "type": "toggle",
                "field": "pms_joint_muscle_pain",
                "risk_indicator": "Joint and muscle pain can be associated with PMS",
            },
            {
                "id": "pms_acne_breakouts",
                "question": "Do you get acne breakouts or skin issues before your period?",
                "type": "toggle",
                "field": "pms_acne_breakouts",
                "risk_indicator": "Hormonal acne before period is common PMS",
            },
        ],
    },

    # ============================================================================
    # SECTION 6: GENERAL SYMPTOMS (Detects: Anemia, Hormonal issues, Fatigue)
    # ============================================================================
    "general_symptoms": {
        "title": "During Your Period 💊",
        "description": "General symptoms during your period",
        "questions": [
            {
                "id": "fatigue",
                "question": "Do you feel unusually tired or fatigued during your period?",
                "type": "toggle",
                "field": "fatigue",
                "risk_indicator": "Fatigue can indicate anemia, especially with heavy periods",
            },
            {
                "id": "dizziness",
                "question": "Do you experience dizziness or lightheadedness?",
                "type": "toggle",
                "field": "dizziness",
                "risk_indicator": "Dizziness + heavy flow may indicate iron deficiency anemia",
            },
            {
                "id": "brain_fog",
                "question": "Do you experience brain fog or difficulty concentrating?",
                "type": "toggle",
                "field": "brain_fog",
                "risk_indicator": "Brain fog can be related to hormonal changes or anemia",
            },
            {
                "id": "nausea",
                "question": "Do you feel nauseous during your period?",
                "type": "toggle",
                "field": "nausea",
                "risk_indicator": "Nausea can be related to severe cramping or hormonal changes",
            },
            {
                "id": "headaches",
                "question": "Do you get headaches or migraines during your period?",
                "type": "toggle",
                "field": "headaches",
                "risk_indicator": "Menstrual migraines are common and hormone-related",
            },
        ],
    },

    # ============================================================================
    # SECTION 7: MEDICAL & FAMILY HISTORY (Detects: PCOS, Endometriosis, etc)
    # ============================================================================
    "medical_history": {
        "title": "Your Health History 🏥",
        "description": "Have you been diagnosed with any of these?",
        "questions": [
            {
                "id": "pcos",
                "question": "Have you been diagnosed with PCOS (Polycystic Ovary Syndrome)?",
                "type": "toggle",
                "field": "pcos",
                "note": "PCOS often causes irregular cycles, acne, weight gain",
                "risk_indicator": "PCOS significantly affects cycle predictions",
            },
            {
                "id": "endometriosis",
                "question": "Have you been diagnosed with Endometriosis?",
                "type": "toggle",
                "field": "endometriosis",
                "note": "Endometriosis causes severe period pain and irregular bleeding",
                "risk_indicator": "Endometriosis requires specialized care",
            },
            {
                "id": "uterine_fibroids",
                "question": "Have you been diagnosed with Uterine Fibroids?",
                "type": "toggle",
                "field": "uterine_fibroids",
                "note": "Fibroids often cause heavy bleeding (Menorrhagia)",
                "risk_indicator": "Fibroids can cause abnormal bleeding patterns",
            },
            {
                "id": "thyroid",
                "question": "Do you have a thyroid condition?",
                "type": "toggle",
                "field": "thyroid",
                "note": "Thyroid disorders affect cycle regularity and hormones",
                "risk_indicator": "Thyroid conditions impact menstrual regularity",
            },
            {
                "id": "anemia_history",
                "question": "Do you have a history of anemia?",
                "type": "single_choice",
                "field": "anemia_history",
                "options": [
                    {"value": 0, "label": "No"},
                    {"value": 1, "label": "Yes, mild anemia"},
                    {"value": 2, "label": "Yes, moderate to severe anemia"},
                ],
                "risk_indicator": "Heavy periods can cause or worsen anemia",
            },
        ],
    },

    # ============================================================================
    # SECTION 8: LIFESTYLE FACTORS (Affects: Cycle regularity, Symptom severity)
    # ============================================================================
    "lifestyle_factors": {
        "title": "Your Lifestyle 🌟",
        "description": "Lifestyle factors significantly impact your menstrual health",
        "questions": [
            {
                "id": "stress_level",
                "question": "How would you rate your current stress level?",
                "type": "single_choice",
                "field": "stress_level",
                "options": [
                    {"value": 1, "label": "Low (I'm chill 😌)"},
                    {"value": 2, "label": "Moderate"},
                    {"value": 3, "label": "High"},
                    {"value": 4, "label": "Very high"},
                    {"value": 5, "label": "Extremely high (stressed out 😰)"},
                ],
                "risk_indicator": "High stress can cause irregular cycles and missed periods",
            },
            {
                "id": "exercise_frequency",
                "question": "How often do you exercise or do physical activity?",
                "type": "single_choice",
                "field": "exercise_frequency",
                "options": [
                    {"value": 1, "label": "Rarely or never"},
                    {"value": 2, "label": "1-2 times per week"},
                    {"value": 3, "label": "3-4 times per week"},
                    {"value": 4, "label": "Daily or almost daily"},
                ],
                "risk_indicator": "No exercise or extreme exercise can affect cycles",
            },
            {
                "id": "sleep_quality",
                "question": "How would you rate your sleep quality?",
                "type": "single_choice",
                "field": "sleep_quality",
                "options": [
                    {"value": 1, "label": "Poor (I'm exhausted 😴)"},
                    {"value": 2, "label": "Fair"},
                    {"value": 3, "label": "Good"},
                    {"value": 4, "label": "Excellent (I sleep like a baby 💤)"},
                ],
                "risk_indicator": "Poor sleep affects hormone levels and cycle regularity",
            },
            {
                "id": "weight_changes",
                "question": "Have you experienced significant weight changes recently?",
                "type": "single_choice",
                "field": "weight_changes",
                "options": [
                    {"value": "stable", "label": "No, my weight is stable"},
                    {"value": "recent_weight_loss", "label": "Yes, I've lost weight recently"},
                    {"value": "recent_weight_gain", "label": "Yes, I've gained weight recently"},
                ],
                "risk_indicator": "Extreme weight changes can cause irregular cycles or missed periods",
            },
        ],
    },

    # ============================================================================
    # SECTION 9: EMOTIONAL & MOOD (Already partially covered, but additional context)
    # ============================================================================
    "emotional_wellbeing": {
        "title": "Your Emotional Wellbeing 💭",
        "description": "How your mood is affected by your cycle",
        "questions": [
            {
                "id": "mood_changes",
                "question": "Do you notice your mood changes during your cycle?",
                "type": "single_choice",
                "field": "mood_changes",
                "options": [
                    {"value": 0, "label": "No, my mood is stable"},
                    {"value": 1, "label": "Slight changes"},
                    {"value": 2, "label": "Noticeable changes"},
                    {"value": 3, "label": "Significant changes (very different from my baseline)"},
                ],
                "risk_indicator": "Significant mood changes suggest hormonal sensitivity",
            },
            {
                "id": "mood_impact",
                "question": "How much do these mood changes impact your relationships or work?",
                "type": "single_choice",
                "field": "mood_impact",
                "options": [
                    {"value": 0, "label": "No impact"},
                    {"value": 1, "label": "Minor impact"},
                    {"value": 2, "label": "Significant impact (affects daily life) - PMS indicator"},
                    {"value": 3, "label": "Severe impact - This may be PMDD"},
                ],
                "risk_indicator": "Severe mood impact indicates need for medical evaluation",
            },
        ],
    },
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

def get_all_questions():
    """Flatten all questions into a single list with section context"""
    all_questions = []
    for section_key, section in QUIZ_SECTIONS.items():
        for question in section["questions"]:
            question["section"] = section_key
            question["section_title"] = section["title"]
            all_questions.append(question)
    return all_questions


def get_section_questions(section_key):
    """Get all questions for a specific section"""
    if section_key in QUIZ_SECTIONS:
        return QUIZ_SECTIONS[section_key]
    return None


def get_question_by_id(question_id):
    """Get a specific question by ID"""
    for section in QUIZ_SECTIONS.values():
        for question in section["questions"]:
            if question["id"] == question_id:
                return question
    return None


def get_disorder_screening_summary(profile_data):
    """
    Returns a summary of potential disorders based on quiz responses.
    Used for informational purposes - not for diagnosis.
    """
    potential_issues = []

    # Dysmenorrhea screening
    if profile_data.get("pain_level", 0) >= 2 and profile_data.get("pain_interference", 0) >= 2:
        potential_issues.append({
            "disorder": "Dysmenorrhea (Painful Periods)",
            "severity": "High" if profile_data["pain_level"] == 3 else "Moderate",
            "recommendation": "Consider consulting a healthcare provider about pain management options",
        })

    # Menorrhagia screening
    if (profile_data.get("flow_intensity", 0) >= 4 or
        profile_data.get("pad_change_frequency", 0) >= 4 or
        profile_data.get("period_duration", 0) > 7):
        potential_issues.append({
            "disorder": "Menorrhagia (Heavy Periods)",
            "severity": "High",
            "recommendation": "Get checked for anemia and discuss treatment options with your doctor",
        })

    # Irregular cycles / PCOS / Amenorrhea screening
    if (profile_data.get("cycle_regular", 0) >= 3 or
        profile_data.get("missed_periods", 0) >= 1):
        potential_issues.append({
            "disorder": "Irregular or Missed Periods",
            "severity": "Moderate" if profile_data.get("missed_periods") == 1 else "High",
            "recommendation": "Discuss with your doctor to rule out PCOS, hormonal imbalances, or other conditions",
        })

    # PMS screening
    pms_score = (profile_data.get("pms_mood_swings", 0) +
                 profile_data.get("pms_irritability", 0) +
                 int(profile_data.get("pms_breast_tenderness", False)) +
                 int(profile_data.get("pms_bloating", False)))
    if pms_score >= 3:
        potential_issues.append({
            "disorder": "Premenstrual Syndrome (PMS)",
            "severity": "Moderate",
            "recommendation": "Track symptoms, manage stress, and discuss symptom relief strategies",
        })

    # PMDD screening (severe mood/emotional symptoms)
    if profile_data.get("pms_depression_anxiety", 0) >= 2:
        potential_issues.append({
            "disorder": "PMDD (Severe PMS)",
            "severity": "High",
            "recommendation": "⚠️ PMDD requires medical evaluation. Consult your healthcare provider soon.",
        })

    # Intermenstrual bleeding screening
    if profile_data.get("spotting_between", 0) >= 1:
        potential_issues.append({
            "disorder": "Intermenstrual Bleeding",
            "severity": "Moderate",
            "recommendation": "Rule out infections, fibroids, or hormonal imbalances with your doctor",
        })

    # Anemia risk screening
    if (profile_data.get("fatigue", False) and
        profile_data.get("dizziness", False) and
        profile_data.get("flow_intensity", 0) >= 3):
        potential_issues.append({
            "disorder": "Possible Iron Deficiency Anemia",
            "severity": "Moderate",
            "recommendation": "Get blood work done to check iron, ferritin, and hemoglobin levels",
        })

    # Lifestyle impact screening
    stress_level = profile_data.get("stress_level", 2)
    if stress_level >= 4 and profile_data.get("cycle_regular", 0) >= 2:
        potential_issues.append({
            "disorder": "Stress-Related Cycle Irregularity",
            "severity": "Moderate",
            "recommendation": "Focus on stress management through exercise, meditation, and sleep",
        })

    return potential_issues
