def compute_quiz_scores(profile):
    """
    Computes:
    - stability_score (0–1)
    - symptom_risk_score (0–1)
    - confidence_boost (0–0.3)
    """

    stability = 0.0
    risk = 0.0

    # -------------------
    # 🩸 FLOW (max 0.25)
    # -------------------
    if profile.flow_intensity in [2, 3]:
        stability += 0.05
    else:
        risk += 0.05

    if profile.pad_change_frequency in [2, 3]:
        stability += 0.05
    else:
        risk += 0.05

    if profile.flooding == 0:
        stability += 0.05
    else:
        risk += 0.05 * profile.flooding

    if profile.clot_size == 0:
        stability += 0.05
    else:
        risk += 0.05 * profile.clot_size

    # -------------------
    # ⏱️ DURATION & CONSISTENCY (max 0.2)
    # -------------------
    if 4 <= profile.period_duration <= 6:
        stability += 0.1
    else:
        risk += 0.1

    if profile.flow_pattern in [2, 3]:
        stability += 0.05
    else:
        risk += 0.05

    if profile.spotting_between == 0:
        stability += 0.05
    else:
        risk += 0.05 * profile.spotting_between

    # -------------------
    # 🔄 CYCLE REGULARITY (max 0.2)
    # -------------------
    if profile.cycle_regular <= 2:
        stability += 0.1
    else:
        risk += 0.1

    if profile.avg_cycle_group in [2, 3]:
        stability += 0.1
    else:
        risk += 0.1

    # -------------------
    # 😖 PAIN (max risk 0.15)
    # -------------------
    risk += 0.05 * profile.pain_level
    risk += 0.05 * profile.pain_interference

    # -------------------
    # 🤢 SYMPTOMS (max risk 0.2)
    # -------------------
    if profile.fatigue:
        risk += 0.05
    if profile.dizziness:
        risk += 0.05
    if profile.nausea:
        risk += 0.05
    if profile.headaches:
        risk += 0.05

    # -------------------
    # 🧠 EMOTIONAL (max risk 0.15)
    # -------------------
    risk += 0.05 * profile.mood_changes
    risk += 0.05 * profile.mood_impact

    # -------------------
    # 🩺 HISTORY (max risk 0.25)
    # -------------------
    if profile.pcos:
        risk += 0.1
    if profile.endometriosis:
        risk += 0.1
    if profile.thyroid:
        risk += 0.05

    risk += 0.05 * profile.anemia_history

    # -------------------
    # 🧮 NORMALIZATION
    # -------------------
    stability = min(round(stability, 2), 1.0)
    risk = min(round(risk, 2), 1.0)

    # -------------------
    # 🔮 CONFIDENCE BOOST
    # -------------------
    confidence_boost = stability * 0.3
    confidence_boost -= risk * 0.15

    confidence_boost = max(round(confidence_boost, 2), 0.0)

    return {
        "stability_score": stability,
        "symptom_risk_score": risk,
        "confidence_boost": confidence_boost,
    }
