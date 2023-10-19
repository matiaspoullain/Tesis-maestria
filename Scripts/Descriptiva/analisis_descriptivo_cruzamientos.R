rm(list=ls())
gc()

##### Analisis descriptivo entre variables ####
library(tidyverse)
library(data.table)
library(lubridate)


#Vehiculos vs meteorologicas
#Procesamiento vehiculos
vehiculos <- fread("Datos/Procesados/conteo_vehicular.csv")
feriados <- fread("Datos/Insumos_prophet/feriados.csv", encoding = "UTF-8")

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

vehiculos.diario <- vehiculos[, .(cantidad_pasos = sum(cantidad_pasos, na.rm = TRUE),
                                         periodo = unique(periodo),
                                         dia_semana = unique(dia_semana),
                                         condicion_dia = unique(condicion_dia)),
                                     by = .(fecha = as.Date(fecha_hora))]

#Procesamiento tiempo

tiempo <- fread("Datos/Procesados/datos_horarios_tiempo_procesados.csv")

#Uno las bases

vehiculos.tiempo <- vehiculos %>%
  merge(tiempo[, .(fecha_hora, temperatura, pp)], by = "fecha_hora")

# Las analizo
#Construyo nueva variable que es diferencia de temperatura a la promedio para esa hora del dia con todos los datos que pueda
tiempo[, hora := hour(fecha_hora)]
tiempo[, temp.media.hora := mean(temperatura), by = hora]

vehiculos.tiempo <- vehiculos.tiempo %>%
  merge(tiempo[, .(fecha_hora, hora, temp.media.hora)], by = "fecha_hora")

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
tiempo.diario <- fread("Datos/Procesados/datos_diarios_tiempo_procesados.csv")
vehiculos.tiempo.diario <- vehiculos.diario %>%
  merge(tiempo.diario, by = 'fecha')

#### Nitrogeno vs otras:

no2 <- fread("Datos/Procesados/no2_diario_procesado.csv")


vehiculos.tiempo.no2 <- vehiculos.tiempo.diario %>%
  merge(no2, by = "fecha")

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

leyenda <- expression(
  atop(
    "Columna promedio de", paste(NO[2], " troposférico (", mu, "mol.", m^-2, ")")
  )
)

(heatmap.vehiculos.temperatura.no2 <- vehiculos.tiempo.no2.heatmap %>%
  ggplot(aes(x = temperatura, y = cantidad_pasos, fill = frecuencia)) +
  geom_tile() +
  ggthemes::scale_fill_gradient2_tableau(palette = "Red-Green-Gold Diverging", trans = "reverse",n.breaks = 10, labels = scales::scientific) +
  # scale_x_continuous(breaks = seq(1, cantidad.pixeles, length.out = num.ticks), labels = round(seq(range(vehiculos.tiempo.no2$temperatura)[1], range(vehiculos.tiempo.no2$temperatura)[2], length.out = num.ticks))) +
  # scale_y_continuous(breaks = seq(1, cantidad.pixeles, length.out = num.ticks), labels = round(seq(range(vehiculos.tiempo.no2$cantidad_pasos)[1], range(vehiculos.tiempo.no2$cantidad_pasos)[2], length.out = num.ticks))) +
  labs(x = "Intervalos de temperatura media diaria (°C)", y = "Intervalos de cantidad de vehículos contados por día", fill = leyenda) +
  theme_bw() +
    guides(fill = guide_colorbar(reverse=T)) +
    theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1)))

ggsave("Figuras/Descriptiva/Heatmap_vehiculos_temperatura_no2.png", heatmap.vehiculos.temperatura.no2, width = 10, height = 6)

# tests contra no2:
cor.test(vehiculos.tiempo.no2$cantidad_pasos, vehiculos.tiempo.no2$NO2_trop_mean, method = "spearman")
cor.test(vehiculos.tiempo.no2$temperatura, vehiculos.tiempo.no2$NO2_trop_mean, method = "spearman")
cor.test(vehiculos.tiempo.no2$intensidad_viento_km_h, vehiculos.tiempo.no2$NO2_trop_mean, method = "spearman")


#Creo lags y otras funciones y busco las correlaciones de spearman:

funciones <- c("sqrt", "log10")

variables.originales <- c("NO2_trop_mean", "cantidad_pasos", "temperatura", "intensidad_viento_km_h", "temperatura.max", "temperatura.min")

for(funcion in funciones){
  nuevas.variables <- paste(funcion, variables.originales, sep = "_")
  if(funcion == "sqrt"){
    vehiculos.tiempo.no2[, (nuevas.variables) :=  sqrt(.SD), .SDcols=variables.originales]
  }
  else if(funcion == "log10"){
+    vehiculos.tiempo.no2[, (nuevas.variables) :=  log10(.SD), .SDcols=variables.originales]
  }
}


lags <- str_pad(0:30, width = 2, pad = "0")
variables <- names(vehiculos.tiempo.no2)[grepl(paste(variables.originales[-1], collapse = "|"), names(vehiculos.tiempo.no2))]

for(lag in lags){
  nuevas.variables <- paste(variables, lag, sep = "_")
  vehiculos.tiempo.no2[, (nuevas.variables) :=  shift(.SD, as.numeric(lag)), .SDcols=variables]
}

variables.correlaciones <- names(vehiculos.tiempo.no2)[
  grepl(
    paste(paste0(c("NO2_trop_mean", variables), "_")
          , collapse = "|"),
    names(vehiculos.tiempo.no2)
  )
]


conversiones.no2 <- names(vehiculos.tiempo.no2)[grepl("NO2_trop_mean", names(vehiculos.tiempo.no2))]

dt.correlaciones <- data.table()

for(i in conversiones.no2){
  
  variables.correlaciones2 <- c(i, variables.correlaciones)
  
  vehiculos.tiempo.no2.correlaciones <- vehiculos.tiempo.no2[, ..variables.correlaciones2]
  
  correlaciones.no2 <- cor(vehiculos.tiempo.no2.correlaciones, method="p", use = "pairwise.complete.obs")[1,]
  
  correlaciones.no2 <- data.table(variable = names(correlaciones.no2),
                                  spearman = correlaciones.no2)
  
  correlaciones.no2 <- correlaciones.no2[!grepl("NO2_trop_mean", variable)]
  
  correlaciones.no2[, target := ..i]
  
  dt.correlaciones <- dt.correlaciones %>%
    rbind(correlaciones.no2)
}



dt.correlaciones[, lag := substr(variable, nchar(variable)-1, nchar(variable))
                  %>% as.numeric]

dt.correlaciones[, variable := substr(variable, 1, nchar(variable)-3)]

dt.correlaciones[, conversion := fcase(grepl("sqrt", variable), "Raíz cuadrada",
                                        grepl("log10", variable), "Logaritmo base 10",
                                        default = "Identidad")]

dt.correlaciones[, variable := gsub(paste(paste0(funciones, "_"), collapse = "|"), "", variable)]

dt.correlaciones[, variable := fcase(variable == "cantidad_pasos", "Conteo vehicular diario",
                                      variable == "temperatura", "Temperatura media diaria",
                                     variable == "temperatura.max", "Temperatura máxima diaria",
                                     variable == "temperatura.min", "Temperatura mínima diaria",
                                     variable == "intensidad_viento_km_h", "Intensidad del viento (Km/H)")]


etiquetas.grid <- list(
  "NO2_trop_mean" = expression(NO[2]),
  "log10_NO2_trop_mean" = expression(paste(Log[10], (NO[2]))),
  "sqrt_NO2_trop_mean" = expression(sqrt(NO[2]))
)

for(i in unique(dt.correlaciones$variable)){
  etiquetas.grid[i] <- i
}

etiquetadora <- function(variable, value){
  return(etiquetas.grid[value])
}

(plot.correlaciones <- dt.correlaciones %>%
                         ggplot(aes(x = lag, y = spearman, col = conversion)) +
                         geom_line() +
                         geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.75) +
                         facet_grid(variable~target, scales = "free", labeller = etiquetadora)+
                         scale_color_brewer(palette = "Dark2") +
                         theme_bw()+
                         theme(legend.position = "top") +
                         labs(x = "Lag (días)", y = "Correlación de Pearson", col = "Conversión"))

ggsave("Figuras/Descriptiva/correlaciones_no2.png", plot.correlaciones, width = 9, height = 12)


print("Mejores combinaciones:")
dt.correlaciones[, mejor := abs(spearman) == max(abs(spearman)), by = variable]
dt.correlaciones[mejor == TRUE]
