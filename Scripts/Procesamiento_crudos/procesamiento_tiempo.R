rm(list=ls())
gc()

#Preprocesamiento de datos meteorologicos:
library(tidyverse)
library(data.table)
library(lubridate)

datos <- fread("Datos/Crudos/CABA_datosestacion.csv", encoding = 'Latin-1')

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



#Me quedo solo con temperatura, pp para datos horarios
datos.horarios <- datos[, .(fecha_hora, temperatura, pp)]

#Lo guardo
fwrite(datos.horarios, "Datos/Procesados/datos_horarios_tiempo_procesados.csv")

#Para los valores diarios:

datos[, fecha := as.Date(fecha_hora)]

#Direccion viento:
#Convertir numero de direccioen angulo radianes (0 == Norte):
datos[, direccion_viento_rad := fifelse(is.na(as.numeric(`DIRECCION DEL VIENTO (§/10)`)), 0, as.numeric(`DIRECCION DEL VIENTO (§/10)`))]
datos[, direccion_viento_rad := pi * direccion_viento_rad / 18]
setnames(datos, 'INTENSIDAD DEL VIENTO (km/h)', 'intensidad_viento_km_h')

#Componentes x e y del viento:
datos[, x := intensidad_viento_km_h * cos(direccion_viento_rad)]
datos[, y := intensidad_viento_km_h * sin(direccion_viento_rad)]

# Resultante por dia:
datos <- datos[, .(
  temperatura = mean(temperatura, na.rm = TRUE),
  temperatura.max = max(temperatura, na.rm = TRUE),
  temperatura.min = min(temperatura, na.rm = TRUE),
  pp = as.numeric(sum(pp)>0),
  x = sum(x),
  y = sum(y)), by = fecha]

# Obtener la direccion e intensidad del viento
datos[, direccion_viento_rad := atan2(y, x)]
datos[, intensidad_viento_km_h := sqrt(x^2 + y^2)/24]

datos <- datos[, -c('x', 'y')]

# Guardar
fwrite(datos, "Datos/Procesados/datos_diarios_tiempo_procesados.csv")
