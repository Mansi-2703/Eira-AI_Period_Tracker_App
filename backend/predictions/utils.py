from datetime import timedelta, date
from .ml.lstm import predict_cycle_length_lstm
from quiz.models import MenstrualHealthProfile
from quiz.utils import compute_quiz_scores


def predict_next_period(cycles, user):
    """
    Uses LSTM if enough data is available,
    otherwise falls back to rule-based average.
    Returns:
    - predicted_date (date)
    - confidence (float: 0.0–1.0)
    - model_used (str)
    """

    cycles = list(cycles)

    if not cycles:
        return None, 0.0, "none"

    cycle_lengths = [c.cycle_length for c in cycles]
    last_cycle = cycles[0]
    count = len(cycle_lengths)

    # 🧠 Base prediction logic
    if count >= 6:
        predicted_cycle = predict_cycle_length_lstm(cycle_lengths)
        confidence = 0.75
        model_used = "LSTM"
    else:
        predicted_cycle = sum(cycle_lengths) / count
        confidence = 0.35 + (count * 0.05)
        model_used = "Rule-based"

    quiz_scores = None
    quiz_completed = False

    try:
        profile = MenstrualHealthProfile.objects.get(
            user=user,
            completed=True
        )
        quiz_scores = compute_quiz_scores(profile)
        quiz_completed = True
        stability = quiz_scores["stability_score"]
        risk = quiz_scores["symptom_risk_score"]
        adjustment = (risk - stability) * 1.5
        predicted_cycle = max(predicted_cycle + adjustment, 15)
        confidence += quiz_scores["confidence_boost"]
    except MenstrualHealthProfile.DoesNotExist:
        pass

    confidence = min(round(confidence, 2), 0.9)
    predicted_date = last_cycle.start_date + timedelta(
        days=max(round(predicted_cycle), 1)
    )

    return predicted_date, confidence, model_used, quiz_completed, quiz_scores




def get_menstrual_phase(last_period_start, cycle_length, period_length):
    today = date.today()

    cycle_day = (today - last_period_start).days + 1
    ovulation_day = cycle_length - 14

    if cycle_day <= period_length:
        phase = "Menstrual"
    elif cycle_day < ovulation_day:
        phase = "Follicular"
    elif cycle_day == ovulation_day:
        phase = "Ovulation"
    else:
        phase = "Luteal"

    fertile_window = [
        last_period_start + timedelta(days=ovulation_day - 2),
        last_period_start + timedelta(days=ovulation_day + 2),
    ]

    return {
        "current_phase": phase,
        "cycle_day": cycle_day,
        "fertile_window": fertile_window,
    }
