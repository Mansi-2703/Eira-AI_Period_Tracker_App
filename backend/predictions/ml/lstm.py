import numpy as np
from tensorflow.keras.models import load_model
from sklearn.preprocessing import MinMaxScaler

MODEL_PATH = "predictions/ml/cycle_lstm.h5"

model = load_model(MODEL_PATH, compile=False)

def predict_cycle_length_lstm(cycle_lengths):
    """
    cycle_lengths: list[int]
    returns: int (predicted cycle length)
    """

    if len(cycle_lengths) < 3:
        return None

    data = np.array(cycle_lengths).reshape(-1, 1)

    scaler = MinMaxScaler()
    scaled = scaler.fit_transform(data)

    X = scaled[-3:].reshape(1, 3, 1)
    pred = model.predict(X, verbose=0)

    predicted = scaler.inverse_transform(pred)[0][0]
    return int(round(predicted))
