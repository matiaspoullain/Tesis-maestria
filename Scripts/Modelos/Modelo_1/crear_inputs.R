rm(list = ls())
gc()

library(dplyr)
library(data.table)
library(lubridate)

datos <- fread("Datos/Procesados/conteo_vehicular.csv")
tiempo <- fread("Datos/Procesados/datos_horarios_tiempo_procesados.csv")

datos <- datos %>%
  merge(tiempo, by = 'fecha_hora')

#Categorizacion de los dias
datos[, es_semana := fifelse(wday(fecha_hora) %in% 2:6, TRUE, FALSE)]
datos[, es_finde := !es_semana]

#Cantidad pasos a log10
datos[, y := log10(cantidad_pasos)]
datos[, cantidad_pasos := NULL]

datos <- datos[, .(ds = fecha_hora, y, pp, temperatura, es_finde, es_semana)]
fwrite(datos, "Datos/Insumo_modelos/Modelo_1.csv")