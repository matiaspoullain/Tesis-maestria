rm(list = ls())
gc()

library(tidyverse)
library(data.table)
library(xtable)


red.no2 <- fread("Datos/Resultados_modelos/Modelo_2/General/Q_mesual.csv")
red.no2 <- red.no2[!(mes_anio %like% "2019"| mes_anio %like% "ene\\." | mes_anio %like% "feb\\.")]

orden.meses <- c(red.no2$mes_anio, 'Total Período')

red.no2_periodo <- fread("Datos/Resultados_modelos/Modelo_2/General/Q_periodo.csv")
red.no2_periodo <- red.no2_periodo[periodo == 'Durante las restricciones', .(mes_anio = periodo, observados_NO2SR)]
red.no2_periodo[, mes_anio := 'Total Período']

red.no2 <- rbind(red.no2[, .(mes_anio, observados_NO2SR)], red.no2_periodo)

#Cuantifico reducon vehiculos
vehiculos.observados <- fread(file.path("Datos","Insumo_modelos", "Modelo_1.csv"))[, .(ds, y = 10**y)]
vehiculos.pred <- fread(file.path("Datos","Resultados_modelos", "Modelo_1", "prediccion.csv")) %>%
  merge(vehiculos.observados, by = 'ds')

vehiculos.pred.periodo <- vehiculos.pred[between(ds, as.Date("2020-03-20"), as.Date("2020-11-05"))]
vehiculos.pred.periodo <- vehiculos.pred.periodo[, .(observados = mean(y),
                                     predichos = mean(yhat))]
vehiculos.pred.periodo[, mes_anio := "Total Período"]
vehiculos.pred.periodo[, observados_predichos := observados / predichos]


vehiculos.pred[, mes_anio := format(vehiculos.pred$ds, format = "%b %Y")]
vehiculos.pred <- vehiculos.pred[, .(observados = mean(y),
                                     predichos = mean(yhat)), by = mes_anio]
vehiculos.pred[, observados_predichos := observados / predichos]

vehiculos.pred <- rbind(vehiculos.pred, vehiculos.pred.periodo)


#Los junto
dt <- merge(red.no2, vehiculos.pred[, .(mes_anio, observados_predichos)], by = "mes_anio")
dt[, mes_anio := factor(mes_anio, levels = orden.meses)]
dt <- dt %>%
  arrange(mes_anio)
dt[, c("Reducción estimada ${NO_2}$ (\\%)", "Reducción estimada conteo vehicular (\\%)") :=
     .(round((1-observados_NO2SR) * 100, 2),
      round((1-observados_predichos) * 100, 2))
     ]
dt <- dt[, -c("observados_NO2SR", "observados_predichos")] %>%
  rename("Período" = mes_anio)


print(xtable(dt, type = "latex"), file = "Tablas/Resultados/comparacion_reducciones_no2_vehiculos.tex", include.rownames=FALSE, , sanitize.colnames.function = identity, sanitize.text.function = identity)

