rm(list = ls())
gc()

library(tidyverse)
library(data.table)
library(xtable)


red.no2 <- fread("Datos/Resultados_modelos/Modelo_2/General/Q_mesual.csv")
red.no2 <- red.no2[!(mes_anio %like% "2019"| mes_anio %like% "ene\\." | mes_anio %like% "feb\\.")]

#Cuantifico reducon vehiculos
vehiculos.observados <- fread(file.path("Datos","Insumo_modelos", "Modelo_1.csv"))[, .(ds, y = 10**y)]
vehiculos.pred <- fread(file.path("Datos","Resultados_modelos", "Modelo_1", "prediccion.csv")) %>%
  merge(vehiculos.observados, by = 'ds')

vehiculos.pred[, mes_anio := format(vehiculos.pred$ds, format = "%b %Y")]
vehiculos.pred <- vehiculos.pred[, .(observados = mean(y),
                                     predichos = mean(yhat)), by = mes_anio]
vehiculos.pred[, observados_predichos := observados / predichos]


#Los junto
dt <- merge(red.no2[, .(mes_anio, observados_NO2SR)], vehiculos.pred[, .(mes_anio, observados_predichos)], by = "mes_anio")
dt[, c("Reducción estimada NO\\textsubscript{2} (%)", "Reducción estimada conteo vehicular (%)") :=
     .(round((1-observados_NO2SR) * 100, 2),
      round((1-observados_predichos) * 100, 2))
     ]
dt <- dt[, -c("observados_NO2SR", "observados_predichos")] %>%
  rename("Mes y año" = mes_anio)

print(xtable(dt, type = "latex"), file = "Tablas/Resultados/comparacion_reducciones_no2_vehiculos.tex", include.rownames=FALSE, , sanitize.colnames.function = identity, sanitize.text.function = identity)

