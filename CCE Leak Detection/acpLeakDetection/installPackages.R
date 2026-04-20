# This script installs (once-off) all the necessary packages for the R integration
# project. 

# Data Preparation
install.packages("RODBC") #Don't need anymore, delegated to Logger 
install.packages("data.table")
install.packages("tidyverse")
install.packages("reshape2")
install.packages("anytime")
install.packages("univOutl")
install.packages("imputeTS")
install.packages("janitor")
install.packages("roll")
install.packages("janitor")

# Prediction 
install.packages("zoo")
install.packages("mlr3")
install.packages("mlr3measures")
install.packages("mlr3learners")
install.packages("mlr3tuning")
install.packages("paradox")


