rm(list = ls())
gc()

library(dplyr)
library(data.table)
library(lubridate)
library(janitor)

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
tiempo <- tiempo[, .(fecha,
                     log_intensidad_viento_km_h = log10(intensidad_viento_km_h),
                     pp)]

#NO2:
no2 <- fread("Datos/Procesados/no2_diario_procesado.csv")
no2 <- no2[, .(fecha, y = log10(NO2_trop_mean))]

#Merge
datos <- no2 %>%
  merge(vehiculos, by = "fecha") %>%
  merge(temperatura, by = "fecha")%>%
  merge(tiempo, by = "fecha")

#formatear para prophet
setnames(datos, "fecha", "ds")
fwrite(datos, "Datos/Insumo_modelos/Modelo_2/prophet.csv")


#Input para XGB:
#Variables relacionadas con la fecha:
datos[, c("dia_de_semana",
          "dia_del_año",
          "dia_del_mes",
          "mes") := .(
            lubridate::wday(ds, week_start = 1),
            yday(ds),
            mday(ds),
            month(ds)
          )]
#Feriados
feriados <- fread("Datos/Insumos_prophet/feriados.csv")
feriados[, holiday := sub("_\\d+$", "", make_clean_names(holiday))]
datos <- datos %>%
  merge(feriados, by = "ds", all.x = TRUE)
datos[is.na(holiday), holiday := "dia_normal"]
fwrite(datos, "Datos/Insumo_modelos/Modelo_2/XGB.csv")
