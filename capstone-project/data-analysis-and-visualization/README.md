# Convoy Fuel Consumption Prediction App

This project implements a linear regression model to predict fuel usage for military convoys.

## Files Included
- convoy_model.py — Python script that loads the dataset and computes a fuel prediction.
- app.R — Shiny web application for interactive predictions.
- convoy_data_clean.csv — Dataset of 150 convoy trips.

---

## How to Run the Python Script
1. Install Python 3.
2. Place `project7_python.ipynb` and `convoy_data_clean.csv` in the same folder.
3. Run:
   project7_python.ipynb

Output will show:
- Dataset info
- Predicted fuel consumption for the sample convoy

---

## How to Run the Shiny App
1. Install R and RStudio.
2. Install Shiny:
   install.packages("shiny")
3. Place `app.R` and `convoy_data_clean.csv` in the same folder.
4. In RStudio, run:
   shiny::runApp(".")

The app will:
- Accept inputs for weight, speed, and distance
- Compute fuel consumption using the regression model
- Display the prediction interactively
