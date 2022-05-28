rm(list=ls())
gc()

#Preprocesamiento de datos meteorologicos:
library(tidyverse)
library(data.table)
library(lubridate)

datos <- fread("Datos/Crudos/CABA_datosestacion.csv")

#Me quedo solo con la estacion observatorio que es la 10156

datos <- datos[ESTACION == 10156,]

#Arreglo la fecha a datetime

datos[, fecha_hora := paste0(FECHA, " ", str_pad(`HORA LOCAL`, 2, pad = "0"), ":00:00") %>%
        as_datetime(format = "%d/%m/%Y %H:%M:%S")]

#Arreglo la temperatura (como viene de excel tiene comas)

datos[, temperatura := gsub(",", ".", `TEMPERATURA (§C)`, fixed = TRUE) %>%
        as.numeric]

#Creo la variable de ocurrencia de precipitaciones con el tiempo presente
#El codigo de tiempo presente esta en http://labosinop.at.fcen.uba.ar/CODIGO_SYNOP_basico.pdf

codigos_pp <- c(20:27, 29, 31, 50:69, 80:98)

datos[, pp := fifelse(`TIEMPO PRESENTE` %in% codigos_pp, 1, 0)]

#Me quedo solo con temperatura y pp
datos <- datos[, .(fecha_hora, temperatura, pp)]

#Lo guardo
fwrite(datos, "Datos/Procesados/datos_tiempo_procesados.csv")
