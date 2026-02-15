import numpy as np
from tensorflow.keras.models import load_model
from sklearn.preprocessing import MinMaxScaler

model = load_model("model/cycle_lstm.h5")

# Example last cycles
last_cycles = np.array([[28], [29], [27]])

scaler = MinMaxScaler()
scaled = scaler.fit_transform(last_cycles)

X = scaled.reshape(1, 3, 1)
pred = model.predict(X)

predicted_cycle_length = int(pred[0][0] * 10 + 20)  # rough denorm
print("Predicted cycle length:", predicted_cycle_length)
