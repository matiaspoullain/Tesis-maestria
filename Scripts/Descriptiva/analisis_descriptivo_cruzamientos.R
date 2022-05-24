rm(list=ls())
gc()

##### Analisis descriptivo entre variables ####
library(tidyverse)
library(data.table)
library(lubridate)


#Vehiculos vs meteorologicas
#Procesamiento vehiculos
vehiculos <- fread("Datos/Procesados/conteo_vehicular.csv")
feriados <- fread("Datos/feriados.csv", encoding = "UTF-8")

vehiculos[, periodo := fifelse(fecha_hora < as.Date("2020-03-20"), "Previo a restricciones", "Durante las restricciones") %>%
            as.factor() %>%
            fct_rev()]

vehiculos[, dia_semana := weekdays(fecha_hora) %>%
            str_to_title() %>%
            factor(levels = c("Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"))]

vehiculos[, condicion_dia := fcase(as.Date(fecha_hora) %in% feriados$ds, "Feriado",
                                   dia_semana %in% c("Sábado", "Domingo"), "Fin de semana",
                                   default = "Día de semana") %>%
            factor(levels = c("Día de semana", "Fin de semana", "Feriado"))]

#Procesamiento tiempo

tiempo <- fread("Datos/Crudos/datos_meteorologicos.csv")[ESTACION == 87585]

tiempo[, fecha_hora := paste0(as.character(FECHA)," ", str_pad(`HORA LOCAL`, 2, pad = "0"), ":00:00") %>%
         as_datetime]

#Uno las bases

vehiculos.tiempo <- vehiculos %>%
  merge(tiempo[, .(fecha_hora, TEMPERATURA, `PP 1h`)], by = "fecha_hora")

# Las analizo
#Heatmap

cantidad.pixeles <- 100

rango.temperatura <- diff(range(vehiculos.tiempo$TEMPERATURA)) / (cantidad.pixeles - 1)

rango.vehiculos <- diff(range(vehiculos.tiempo$cantidad_pasos)) / (cantidad.pixeles - 1)


vehiculos.tiempo.heatmap <- vehiculos.tiempo[, .(temperatura = cut_width(TEMPERATURA, rango.temperatura, labels = FALSE),
                                                 cantidad_pasos = cut_width(cantidad_pasos, rango.vehiculos, labels = FALSE),
                                                 periodo,
                                                 condicion_dia)]

vehiculos.tiempo.heatmap <- vehiculos.tiempo.heatmap[, .(frecuencia = .N), by = .(temperatura, cantidad_pasos, periodo, condicion_dia)]


grilla.vacia <- expand.grid(temperatura = 1:cantidad.pixeles,
            cantidad_pasos = 1:cantidad.pixeles,
            periodo = unique(vehiculos.tiempo.heatmap$periodo),
            condicion_dia = unique(vehiculos.tiempo.heatmap$condicion_dia)) %>%
  as.data.table()

vehiculos.tiempo.heatmap <- grilla.vacia %>%
  merge(vehiculos.tiempo.heatmap, by = c("temperatura", "cantidad_pasos", "periodo", "condicion_dia"), all = TRUE)

vehiculos.tiempo.heatmap[is.na(frecuencia), frecuencia := 0]

vehiculos.tiempo %>%
  ggplot(aes(x = cut_width(TEMPERATURA, rango.temperatura), y = cut_width(cantidad_pasos, rango.vehiculos))) +
  geom_tile() +
  facet_grid(periodo~condicion_dia)

num.ticks <- 9

vehiculos.tiempo.heatmap %>%
  ggplot(aes(x = temperatura, y = cantidad_pasos, fill = frecuencia)) +
  geom_tile() +
  facet_grid(periodo~condicion_dia) +
  scale_fill_viridis_c(n.breaks = 10) +
  scale_x_continuous(breaks = seq(1, cantidad.pixeles, length.out = num.ticks), labels = round(seq(range(vehiculos.tiempo$TEMPERATURA)[1], range(vehiculos.tiempo$TEMPERATURA)[2], length.out = num.ticks))) +
  scale_y_continuous(breaks = seq(1, cantidad.pixeles, length.out = num.ticks), labels = round(seq(range(vehiculos.tiempo$cantidad_pasos)[1], range(vehiculos.tiempo$cantidad_pasos)[2], length.out = num.ticks))) +
  labs(x = "Temperatura (°C)", y = "Cantidad de vehículos contados por hora", fill = "Frecuencia") +
  theme_bw()


#Nitrogeno vs otras:


