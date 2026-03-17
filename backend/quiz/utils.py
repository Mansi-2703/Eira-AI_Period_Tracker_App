def compute_quiz_scores(profile):
    """
    Computes:
    - stability_score (0–1): Overall cycle health
    - symptom_risk_score (0–1): Symptom severity and disorder risk
    - confidence_boost (0–0.3): Additional confidence for LSTM predictions
    - detected_disorders (list): Potential disorders based on responses
    """

    stability = 0.0
    risk = 0.0
    detected_disorders = []

    # =====================================================================
    # 🩸 FLOW & BLEEDING PATTERN (max contribution: 0.25)
    # =====================================================================
    if profile.flow_intensity in [2, 3]:
        stability += 0.05
    else:
        risk += 0.05
        if profile.flow_intensity >= 4:
            detected_disorders.append("Menorrhagia")

    if profile.pad_change_frequency in [2, 3]:
        stability += 0.05
    else:
        risk += 0.05

    if profile.flooding == 0:
        stability += 0.05
    else:
        risk += 0.05 * profile.flooding
        if profile.flooding == 2:
            detected_disorders.append("Menorrhagia")

    if profile.clot_size == 0:
        stability += 0.05
    else:
        risk += 0.05 * profile.clot_size

    # =====================================================================
    # ⏱️ DURATION & CONSISTENCY (max contribution: 0.2)
    # =====================================================================
    if 4 <= profile.period_duration <= 6:
        stability += 0.1
    elif profile.period_duration > 7:
        risk += 0.15
        if "Menorrhagia" not in detected_disorders:
            detected_disorders.append("Menorrhagia")
    else:
        risk += 0.05

    if profile.flow_pattern in [2, 3]:
        stability += 0.05
    else:
        risk += 0.05

    if profile.spotting_between == 0:
        stability += 0.05
    else:
        risk += 0.05 * profile.spotting_between
        if profile.spotting_between == 2:
            detected_disorders.append("Intermenstrual_Bleeding")

    # =====================================================================
    # 🔄 CYCLE REGULARITY (max contribution: 0.25)
    # Detects: PCOS, Irregularity, Amenorrhea
    # =====================================================================
    if profile.cycle_regular <= 2:
        stability += 0.1
    else:
        risk += 0.1
        if profile.cycle_regular == 4:
            detected_disorders.append("Irregular_Cycles")

    if profile.avg_cycle_group in [2, 3]:
        stability += 0.1
    else:
        risk += 0.1

    # Missed periods indicator
    if profile.missed_periods >= 1:
        risk += 0.1 * profile.missed_periods
        detected_disorders.append("Missed_Periods")

    # =====================================================================
    # 😖 PAIN (max contribution: 0.15)
    # Detects: Dysmenorrhea, Endometriosis
    # =====================================================================
    pain_score = profile.pain_level + profile.pain_interference
    risk += 0.05 * profile.pain_level
    risk += 0.05 * profile.pain_interference

    if pain_score >= 3:  # Moderate to severe pain
        detected_disorders.append("Dysmenorrhea")

    # =====================================================================
    # 🌙 PMS & PMDD SYMPTOMS (max contribution: 0.2)
    # =====================================================================
    pms_emotional_score = profile.pms_mood_swings + profile.pms_irritability
    pms_physical_score = (
        int(profile.pms_breast_tenderness) +
        int(profile.pms_bloating) +
        int(profile.pms_joint_muscle_pain) +
        int(profile.pms_acne_breakouts)
    )

    # PMS detection
    if pms_emotional_score >= 2 or pms_physical_score >= 2:
        detected_disorders.append("PMS")
        risk += 0.05

    # PMDD detection (severe mood symptoms)
    if profile.pms_depression_anxiety >= 2:
        detected_disorders.append("PMDD")
        risk += 0.15  # Higher risk weight for PMDD

    risk += 0.02 * profile.pms_mood_swings
    risk += 0.02 * profile.pms_irritability
    risk += 0.03 * profile.pms_depression_anxiety

    # =====================================================================
    # 🤢 GENERAL SYMPTOMS (max contribution: 0.15)
    # Detects: Anemia, Hormonal issues, Fatigue
    # =====================================================================
    symptom_count = sum([
        profile.fatigue,
        profile.dizziness,
        profile.nausea,
        profile.headaches,
        profile.brain_fog,
    ])

    risk += 0.03 * symptom_count

    # Anemia risk when combined with heavy flow + fatigue/dizziness
    if (profile.flow_intensity >= 4 and
        profile.fatigue and profile.dizziness):
        detected_disorders.append("Possible_Anemia")

    # =====================================================================
    # 🧠 EMOTIONAL & MOOD (max contribution: 0.1)
    # =====================================================================
    risk += 0.03 * profile.mood_changes
    risk += 0.02 * profile.mood_impact

    # =====================================================================
    # 🩺 MEDICAL HISTORY (max contribution: 0.25)
    # =====================================================================
    if profile.pcos:
        risk += 0.12
        detected_disorders.append("PCOS")

    if profile.endometriosis:
        risk += 0.1
        detected_disorders.append("Endometriosis")

    if profile.uterine_fibroids:
        risk += 0.1
        detected_disorders.append("Uterine_Fibroids")

    if profile.thyroid:
        risk += 0.05

    risk += 0.03 * profile.anemia_history

    # =====================================================================
    # 🌟 LIFESTYLE FACTORS (max contribution: 0.1)
    # =====================================================================
    stress_impact = max(0, (profile.stress_level - 2) * 0.03)
    risk += stress_impact

    # Poor sleep or extreme exercise can cause irregular cycles
    if profile.sleep_quality <= 2:
        risk += 0.05

    if profile.exercise_frequency == 1 or profile.exercise_frequency == 4:
        # Either no exercise or extreme exercise can affect cycles
        risk += 0.03

    # Weight changes
    if profile.weight_changes != "stable":
        risk += 0.05

    # =====================================================================
    # NORMALIZE SCORES
    # =====================================================================
    stability = min(stability, 1.0)
    risk = min(risk, 1.0)

    # Calculate confidence boost based on disorder complexity
    confidence_boost = 0.0
    if len(detected_disorders) >= 2:
        confidence_boost = 0.1  # Multiple disorders = less confidence
    elif len(detected_disorders) == 1:
        confidence_boost = 0.15
    else:
        confidence_boost = 0.2  # No disorders = more confidence in LSTM

    confidence_boost = min(confidence_boost, 0.3)

    return {
        "stability_score": round(stability, 2),
        "symptom_risk_score": round(risk, 2),
        "confidence_boost": confidence_boost,
        "detected_disorders": list(set(detected_disorders)),  # Remove duplicates
        "assessment_summary": generate_assessment_summary(profile, detected_disorders, risk),
    }


def generate_assessment_summary(profile, detected_disorders, risk_score):
    """
    Generate a user-friendly assessment summary based on detected disorders
    and overall risk profile.
    """
    summary = {
        "overall_health": "",
        "key_findings": [],
        "recommendations": [],
        "need_professional_help": False,
    }

    # Overall health assessment
    if risk_score < 0.3:
        summary["overall_health"] = "Your menstrual health looks good! 😊"
    elif risk_score < 0.6:
        summary["overall_health"] = "You have some symptoms worth monitoring 👀"
    else:
        summary["overall_health"] = "You're experiencing significant symptoms 💭"
        summary["need_professional_help"] = True

    # Key findings
    if "Dysmenorrhea" in detected_disorders:
        summary["key_findings"].append(
            "Severe period pain detected - This is Dysmenorrhea"
        )
        summary["recommendations"].append(
            "Explore pain management options: heating pads, ibuprofen, or prescription treatments"
        )

    if "Menorrhagia" in detected_disorders:
        summary["key_findings"].append(
            "Heavy periods detected - This may be Menorrhagia"
        )
        summary["recommendations"].append(
            "Get blood work to check for anemia (iron, ferritin levels)"
        )
        summary["need_professional_help"] = True

    if "Irregular_Cycles" in detected_disorders or "Missed_Periods" in detected_disorders:
        summary["key_findings"].append(
            "Irregular or missed periods detected"
        )
        summary["recommendations"].append(
            "Rule out PCOS, thyroid issues, or hormonal imbalances - see your doctor"
        )
        summary["need_professional_help"] = True

    if "PMDD" in detected_disorders:
        summary["key_findings"].append(
            "Severe pre-menstrual mood symptoms detected - This may be PMDD"
        )
        summary["recommendations"].append(
            "⚠️ PMDD requires professional medical evaluation and treatment"
        )
        summary["need_professional_help"] = True

    if "PMS" in detected_disorders and "PMDD" not in detected_disorders:
        summary["key_findings"].append(
            "Pre-menstrual symptoms (PMS) detected"
        )
        summary["recommendations"].append(
            "Manage PMS through lifestyle: exercise, stress reduction, dietary changes"
        )

    if "Intermenstrual_Bleeding" in detected_disorders:
        summary["key_findings"].append(
            "Spotting between periods detected"
        )
        summary["recommendations"].append(
            "Check with your doctor to rule out fibroids, infections, or hormonal issues"
        )

    if "Possible_Anemia" in detected_disorders:
        summary["key_findings"].append(
            "Risk of anemia based on heavy flow + fatigue/dizziness"
        )
        summary["recommendations"].append(
            "Get comprehensive blood work including iron panel"
        )
        summary["need_professional_help"] = True

    if "PCOS" in detected_disorders:
        summary["key_findings"].append(
            "PCOS diagnosis noted - This affects cycle predictions"
        )
        summary["recommendations"].append(
            "Work with healthcare provider on PCOS management plan"
        )
        summary["need_professional_help"] = True

    if "Endometriosis" in detected_disorders:
        summary["key_findings"].append(
            "Endometriosis diagnosis noted - This requires specialized care"
        )
        summary["recommendations"].append(
            "Consult with a gynecologist on pain management and treatment options"
        )
        summary["need_professional_help"] = True

    # Lifestyle recommendations
    if profile.stress_level >= 4:
        summary["recommendations"].append(
            "High stress detected - Practice stress management: meditation, yoga, or counseling"
        )

    if profile.sleep_quality <= 2:
        summary["recommendations"].append(
            "Poor sleep quality - Prioritize better sleep for hormonal balance"
        )

    if profile.exercise_frequency == 1:
        summary["recommendations"].append(
            "Increase physical activity - Regular exercise helps hormone balance"
        )

    if profile.weight_changes != "stable":
        summary["recommendations"].append(
            "Recent weight changes detected - This can affect cycle regularity"
        )

    return summary
