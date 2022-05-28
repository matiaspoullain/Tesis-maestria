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

tiempo <- fread("Datos/Procesados/datos_tiempo_procesados.csv")

#Uno las bases

vehiculos.tiempo <- vehiculos %>%
  merge(tiempo[, .(fecha_hora, temperatura, pp)], by = "fecha_hora")

# Las analizo
#Construyo nueva variable que es diferencia de temperatura a la promedio para esa hora del dia con todos los datos que pueda
tiempo[, hora := hour(fecha_hora)]
tiempo[, temp.media.hora := mean(temperatura), by = hora]

vehiculos.tiempo <- vehiculos.tiempo %>%
  merge(tiempo[, .(fecha_hora, hora, temp.media.hora)], by = "fecha_hora")

vehiculos.tiempo[, dif.temp.hora := temperatura - temp.media.hora]

vehiculos.tiempo %>%
  ggplot(aes(x = dif.temp.hora, y = cantidad_pasos, col = periodo)) +
  geom_point(alpha = 0.1) +
  facet_grid(hora~condicion_dia)

cor.test(vehiculos.tiempo$cantidad_pasos, vehiculos.tiempo$temperatura, method = "pearson")

#Heatmap

cantidad.pixeles <- 100

rango.temperatura <- diff(range(vehiculos.tiempo$temperatura)) / (cantidad.pixeles - 1)

rango.vehiculos <- diff(range(vehiculos.tiempo$cantidad_pasos)) / (cantidad.pixeles - 1)


vehiculos.tiempo.heatmap <- vehiculos.tiempo[, .(temperatura = cut_width(temperatura, rango.temperatura, labels = FALSE),
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

num.ticks <- 9

vehiculos.tiempo.heatmap %>%
  ggplot(aes(x = temperatura, y = cantidad_pasos, fill = frecuencia)) +
  geom_tile() +
  facet_grid(periodo~condicion_dia) +
  scale_fill_viridis_c(n.breaks = 10) +
  scale_x_continuous(breaks = seq(1, cantidad.pixeles, length.out = num.ticks), labels = round(seq(range(vehiculos.tiempo$temperatura)[1], range(vehiculos.tiempo$temperatura)[2], length.out = num.ticks))) +
  scale_y_continuous(breaks = seq(1, cantidad.pixeles, length.out = num.ticks), labels = round(seq(range(vehiculos.tiempo$cantidad_pasos)[1], range(vehiculos.tiempo$cantidad_pasos)[2], length.out = num.ticks))) +
  labs(x = "Temperatura (°C)", y = "Cantidad de vehículos contados por hora", fill = "Frecuencia") +
  theme_bw()


#Lo mismo pero diario:
vehiculos.tiempo.diario <- vehiculos.tiempo[, .(cantidad_pasos = sum(cantidad_pasos, na.rm = TRUE),
                                                periodo = unique(periodo),
                                                dia_semana = unique(dia_semana),
                                                condicion_dia = unique(condicion_dia),
                                                temperatura = mean(temperatura, na.rm = TRUE),
                                                pp = as.numeric(sum(pp, na.rm = TRUE)> 1),
                                                dif.temp.dia = mean(dif.temp.hora, na.rm = TRUE)),
                                            by = .(fecha = as.Date(fecha_hora))]

tiempo.diario <- tiempo[, .(temperatura = mean(temperatura, na.rm = TRUE)), by = .(fecha = as.Date(fecha_hora))]
tiempo.diario[, doy := yday(fecha)]
tiempo.diario[, dif.temp.media := temperatura - mean(temperatura), by = doy]

vehiculos.tiempo.diario[periodo == "Previo a restricciones"] %>%
  merge(tiempo.diario[, .(fecha, dif.temp.media)], by = "fecha") %>%
  ggplot(aes(x = dif.temp.dia, y = cantidad_pasos)) +
  geom_point(alpha = 0.5) +
  facet_wrap(condicion_dia~.) +
  geom_smooth(method = "lm")

#### Nitrogeno vs otras:

no2 <- fread("Datos/Procesados/no2_diario_procesado.csv")


vehiculos.tiempo.no2 <- vehiculos.tiempo.diario %>%
  merge(no2, by = "fecha")

vehiculos.tiempo.no2 %>%
  ggplot(aes(x = cantidad_pasos, y = NO2_trop_mean, col = condicion_dia)) +
  geom_point() +
  facet_grid(periodo~pp)

#Heatmap
cantidad.pixeles <- 100

rango.temperatura <- diff(range(vehiculos.tiempo.no2$temperatura)) / (cantidad.pixeles - 1)

rango.vehiculos <- diff(range(vehiculos.tiempo.no2$cantidad_pasos)) / (cantidad.pixeles - 1)


vehiculos.tiempo.no2.heatmap <- vehiculos.tiempo.no2[, .(temperatura = cut_width(temperatura, rango.temperatura, labels = FALSE),
                                                 cantidad_pasos = cut_width(cantidad_pasos, rango.vehiculos, labels = FALSE),
                                                 NO2_trop_mean,
                                                 periodo,
                                                 condicion_dia)]

vehiculos.tiempo.no2.heatmap <- vehiculos.tiempo.no2.heatmap[, .(frecuencia = mean(NO2_trop_mean, na.rm = TRUE)), by = .(temperatura, cantidad_pasos, periodo, condicion_dia)]


grilla.vacia <- expand.grid(temperatura = 1:cantidad.pixeles,
                            cantidad_pasos = 1:cantidad.pixeles,
                            periodo = unique(vehiculos.tiempo.no2.heatmap$periodo),
                            condicion_dia = unique(vehiculos.tiempo.no2.heatmap$condicion_dia)) %>%
  as.data.table()

vehiculos.tiempo.no2.heatmap <- grilla.vacia %>%
  merge(vehiculos.tiempo.no2.heatmap, by = c("temperatura", "cantidad_pasos", "periodo", "condicion_dia"), all = TRUE)

vehiculos.tiempo.no2.heatmap[is.na(frecuencia), frecuencia := 0]

vehiculos.tiempo.no2 %>%
  ggplot(aes(x = cut_width(temperatura, rango.temperatura), y = cut_width(cantidad_pasos, rango.vehiculos))) +
  geom_tile() +
  facet_grid(periodo~condicion_dia)

num.ticks <- 9

vehiculos.tiempo.no2.heatmap %>%
  ggplot(aes(x = temperatura, y = cantidad_pasos, fill = frecuencia)) +
  geom_tile() +
  facet_grid(periodo~condicion_dia) +
  scale_fill_viridis_c(n.breaks = 10) +
  scale_x_continuous(breaks = seq(1, cantidad.pixeles, length.out = num.ticks), labels = round(seq(range(vehiculos.tiempo.no2$temperatura)[1], range(vehiculos.tiempo.no2$temperatura)[2], length.out = num.ticks))) +
  scale_y_continuous(breaks = seq(1, cantidad.pixeles, length.out = num.ticks), labels = round(seq(range(vehiculos.tiempo.no2$cantidad_pasos)[1], range(vehiculos.tiempo.no2$cantidad_pasos)[2], length.out = num.ticks))) +
  labs(x = "Temperatura media diaria (°C)", y = "Cantidad de vehículos contados por día", fill = expression(paste("Concentración promedio de ", NO[2], " troposférico (", mu, "mol.", m^-2, ")"))) +
  theme_bw()

#Sin agrupar:
cantidad.pixeles <- 10

rango.temperatura <- diff(range(vehiculos.tiempo.no2$temperatura)) / (cantidad.pixeles - 1)

rango.vehiculos <- diff(range(vehiculos.tiempo.no2$cantidad_pasos)) / (cantidad.pixeles - 1)


vehiculos.tiempo.no2.heatmap <- vehiculos.tiempo.no2[, .(temperatura = cut_width(temperatura, rango.temperatura),#, labels = FALSE),
                                                         cantidad_pasos = cut_width(cantidad_pasos, rango.vehiculos),#, labels = FALSE),
                                                         temperatura_orden = cut_width(temperatura, rango.temperatura, labels = FALSE),
                                                         cantidad_pasos_orden = cut_width(cantidad_pasos, rango.vehiculos, labels = FALSE),
                                                         NO2_trop_mean)]

vehiculos.tiempo.no2.heatmap <- vehiculos.tiempo.no2.heatmap[, .(frecuencia = mean(NO2_trop_mean, na.rm = TRUE),
                                                                 temperatura_orden,
                                                                 cantidad_pasos_orden), by = .(temperatura, cantidad_pasos)]


grilla.vacia <- expand.grid(temperatura = unique(vehiculos.tiempo.no2.heatmap$temperatura),# 1:cantidad.pixeles,
                            cantidad_pasos = unique(vehiculos.tiempo.no2.heatmap$cantidad_pasos)) %>%#1:cantidad.pixeles) %>%
  as.data.table()

vehiculos.tiempo.no2.heatmap <- grilla.vacia %>%
  merge(vehiculos.tiempo.no2.heatmap, by = c("temperatura", "cantidad_pasos"), all = TRUE)

#vehiculos.tiempo.no2.heatmap[is.na(frecuencia), frecuencia := 0]

num.ticks <- 9

(heatmap.vehiculos.temperatura.no2 <- vehiculos.tiempo.no2.heatmap %>%
  ggplot(aes(x = temperatura, y = cantidad_pasos, fill = frecuencia)) +
  geom_tile() +
  scale_fill_viridis_c(n.breaks = 10) +
  # scale_x_continuous(breaks = seq(1, cantidad.pixeles, length.out = num.ticks), labels = round(seq(range(vehiculos.tiempo.no2$temperatura)[1], range(vehiculos.tiempo.no2$temperatura)[2], length.out = num.ticks))) +
  # scale_y_continuous(breaks = seq(1, cantidad.pixeles, length.out = num.ticks), labels = round(seq(range(vehiculos.tiempo.no2$cantidad_pasos)[1], range(vehiculos.tiempo.no2$cantidad_pasos)[2], length.out = num.ticks))) +
  labs(x = "Intervalos de temperatura media diaria (°C)", y = "Intervalos de cantidad de vehículos contados por día", fill = expression(paste("[", NO[2], " troposférico] (", mu, "mol.", m^-2, ")"))) +
  theme_bw() +
    theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1)))

ggsave("Figuras/Descriptiva/Heatmap_vehiculos_temperatura_no2.png", heatmap.vehiculos.temperatura.no2, width = 10, height = 6)

# tests contra no2:
cor.test(vehiculos.tiempo.no2$cantidad_pasos, vehiculos.tiempo.no2$NO2_trop_mean, method = "spearman")
cor.test(vehiculos.tiempo.no2$temperatura, vehiculos.tiempo.no2$NO2_trop_mean, method = "spearman")
