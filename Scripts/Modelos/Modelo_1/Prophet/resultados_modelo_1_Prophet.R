rm(list = ls())
gc()

##### Resultados modelo 1 #####

library(tidyverse)
library(data.table)
library(prophet)

datos <- fread("Datos/df_prophet_entero.csv")
modelo <- readRDS("Modelos/modelo_1.RDS")

#Prediccion a futuro:
forcast <- predict(modelo, datos)

#Graficos de componentes:

plot.componentes <- prophet_plot_components(modelo, forcast)
