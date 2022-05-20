rm(list = ls())
gc()

library(dplyr)
library(data.table)
library(prophet)

df.prophet <- fread("Datos/df_prophet_train.csv")
feriados <- fread("Datos/feriados.csv", encoding = "UTF-8")

m <- prophet(growth = "flat",
            changepoint.range = 0.8, 
            changepoint.prior.scale = 0.05, 
            n_changepoint = 25, 
            yearly.seasonality = TRUE,
            daily.seasonality = FALSE, 
            weekly.seasonality = TRUE,
            mcmc.samples = 1000, 
            seasonality.mode = "additive", 
            seasonality.prior.scale = 0.827,
            uncertainty.samples = 2000,
            holidays = feriados,
            holidays.prior.scale = 0.0198,
            control = list(max_treedepth = 30)) %>%
  add_seasonality("diaria_semana", 1, mode = "additive", condition.name = "es_semana", fourier.order = 5) %>%
  add_seasonality("diaria_finde", 1, mode = "additive", condition.name = "es_finde", fourier.order = 5) %>%
  add_regressor("precipitaciones", mode = "additive") %>%
  add_regressor("temperatura", mode = "additive") %>%
  fit.prophet(df.prophet)

saveRDS(m, file="Modelos/modelo_1.RDS")