# Preprocesamiento de no2
rm(list=ls())
gc()

library(tidyverse)
library(data.table)
library(lubridate)

datos <- fread("Datos/Crudos/Buenos Aires_NO2trop_crudo.csv")

#Me quedo solo con los dias. Tambien con las columnas interesantes
#Tomo promeidos para que haya un dato por dia

datos <- datos[, .(NO2_trop_mean = mean(NO2_trop_mean, na.rm = TRUE),
          NO2_trop_std = mean(NO2_trop_std, na.rm = TRUE)),
      by = .(fecha = as.Date(Timestamp))]

#Relleno con los dias que faltan

grilla.vacia <- data.table(
  fecha = seq(min(datos$fecha, na.rm = TRUE), max(datos$fecha, na.rm = TRUE), by = "day")
  )

datos <- grilla.vacia %>%
  merge(datos, by = "fecha", all = TRUE)

#Lo guardo:
fwrite(datos, "Datos/Procesados/no2_diario_procesado.csv")
