# PROJECT AEGIS: Phase 5 – Statistical Risk Probability Model
# ANALYST: Jen Jones
# OBJECTIVE: Prioritize high-risk accounts for manual investigative review.

# 1. DATA INGESTION
# Loading the priority list containing my manual investigative statuses.
data <- read.csv("Aegis_Priority_Results_Final.csv")

# 2. NORMALIZING HIGH-VOLUME OUTLIERS (Scaling)
# Using log10 to smooth the transaction volumes so the multi-million dollar 
# 'Whale' transactions don't skew the overall probability model.
data$log_volume <- log10(data$total_volume + 1)

# 3. WEIGHTED RISK CALCULATION
# Applying a 60/40 weight to Volume vs. Velocity to determine the risk gradient.
data$fraud_probability <- (data$log_volume * 0.6) + (data$total_velocity * 0.4)

# 4. PROBABILITY STANDARDIZATION
# Normalizing scores to a 0.0 - 1.0 range for executive reporting.
data$fraud_probability <- (data$fraud_probability - min(data$fraud_probability)) / 
                          (max(data$fraud_probability) - min(data$fraud_probability))

# 5. RISK RANKING
# Sorting the dataset to highlight the top probability targets.
final_report <- data[order(-data$fraud_probability), ]
head(final_report, 10)

# 6. OUTPUT FOR DASHBOARDING
# Exporting the final model for Tableau visualization.
write.csv(final_report, "Aegis_Final_Risk_Model.csv", row.names = FALSE)




