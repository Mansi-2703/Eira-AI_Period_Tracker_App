import numpy as np
import pandas as pd
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import LSTM, Dense
from sklearn.preprocessing import MinMaxScaler

# Load data
data = pd.read_csv("data/cycles.csv")
values = data["cycle_length"].values.reshape(-1, 1)

# Normalize
scaler = MinMaxScaler()
scaled = scaler.fit_transform(values)

# Create sequences
def create_sequences(data, seq_len=3):
    X, y = [], []
    for i in range(len(data) - seq_len):
        X.append(data[i:i+seq_len])
        y.append(data[i+seq_len])
    return np.array(X), np.array(y)

X, y = create_sequences(scaled)

# Model
model = Sequential([
    LSTM(32, input_shape=(X.shape[1], 1)),
    Dense(1)
])

model.compile(optimizer="adam", loss="mse")
model.fit(X, y, epochs=50, verbose=1)

# Save model
model.save("model/cycle_lstm.h5")
