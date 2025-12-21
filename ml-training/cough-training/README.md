📄 File Content: README.md
Markdown

# 🫁 Airea: AI-Powered Cough Detection System

⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️

# FOR THIS YOU NEED DATASET: AVAILABLE ON REQUEST !!!

⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️️

**Airea** is an IoT device designed to monitor lung patients by detecting specific cough patterns using TinyML (TensorFlow Lite for Microcontrollers). It runs on an **ESP32** and uses an **INMP441** microphone to listen for coughs in real-time while filtering out background noise.

---

## 📂 Project Structure

This repository is divided into two main sections:

1.  **`ML_Training/`**: Python scripts to train the Artificial Intelligence model.
2.  **`Firmware/`**: C++ code to run on the ESP32 microcontroller.

---

## 🚀 Part 1: Training the AI Model (Python)

If you want to retrain the model with new data, follow these steps.

### 1. Prerequisites

- Python 3.9+ installed.
- Virtual Environment (recommended).

### 2. Setup

Open your terminal in the `ML_Training` folder and install dependencies:

```bash
pip install -r requirements.txt
3. Training
Run the training script to generate a new model:

Bash

python train_model.py
This reads audio from the dataset/ folder.

It trains a lightweight Convolutional Neural Network (CNN).

Output: It generates a file named model.h.



then go to esp32_firmware/src
```
