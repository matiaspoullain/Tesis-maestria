rm(list = ls())
gc()

library(dplyr)
library(data.table)
library(lubridate)

#Mejores combinaciones de transformaciones:
#Target: log10
#Vehiculos: log10, lag 0
#Temperatura: Media, log10, lag 2 dias
#Viento: log10, lag 0 dias

#Vehiculos
vehiculos <- fread("Datos/Procesados/conteo_vehicular.csv")
vehiculos[, fecha := as.Date(fecha_hora)]
vehiculos <- vehiculos[, .(cantidad_pasos = log10(sum(cantidad_pasos, na.rm = TRUE))), by = fecha]

#Tiempo
tiempo <- fread("Datos/Procesados/datos_diarios_tiempo_procesados.csv")
temperatura <- tiempo[, .(fecha = fecha + 2, log_temperatura = log10(temperatura))]
viento <- tiempo[, .(fecha, log_intensidad_viento_km_h = log10(intensidad_viento_km_h))]

#NO2:
no2 <- fread("Datos/Procesados/no2_diario_procesado.csv")
no2 <- no2[, .(fecha, y = log10(NO2_trop_mean))]

#Merge
datos <- no2 %>%
  merge(vehiculos, by = "fecha") %>%
  merge(temperatura, by = "fecha")%>%
  merge(viento, by = "fecha")

#formatear para prophet
setnames(datos, "fecha", "ds")
fwrite(datos, "Datos/Insumo_modelos/Modelo_2/prophet.csv")