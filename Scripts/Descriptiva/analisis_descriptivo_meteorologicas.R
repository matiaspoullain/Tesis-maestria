rm(list=ls())
gc()

##### Analisis descriptivo NO2 y variables meteorológicas ####
library(tidyverse)
library(data.table)
library(scales)

#### Variables meteorologicas ####
tiempo.diario <- fread("Datos/Procesados/datos_diarios_tiempo_procesados.csv")

tiempo.diario <- tiempo.diario[between(fecha, as.Date("2019-01-01"), as.Date("2021-01-01"))]

(plot.tiempo <- tiempo.diario %>%
    mutate(etiqueta = "Ocurrencia de precipitaciones") %>%
    ggplot(aes(x = fecha, y = temperatura, ymin = temperatura.min, ymax = temperatura.max)) +
    geom_ribbon(alpha = 0.5, fill = palette.colors(2, "Dark2")[2]) +
    geom_line(col = palette.colors(2, "Dark2")[2]) +
    geom_vline(aes(xintercept = ifelse(pp == 1, fecha, NA), col = etiqueta), alpha = 0.5, na.rm = TRUE) +
    scale_fill_brewer(palette = "Dark2") +
    scale_color_manual(values = palette.colors(3, "Dark2")[3]) +
    labs(x = "Fecha", y = "Temperatura (°C)", col = "") +
    theme_bw()+
    theme(legend.position = "top"))


ggsave("Figuras/Descriptiva/Tiempo_diario.png", plot.tiempo, width = 10, height = 6)

# días seguidos con y sin lluvias:

tiempo.diario[, contador := rleid(pp)]

contador <- tiempo.diario[, .N, by = .(pp, contador)]

contador[pp == 0, N] %>%
  mean

contador[pp == 1, N] %>%
  mean


#Viento:
(plot.viento <- tiempo.diario %>%
  ggplot(aes(x = fecha, y = intensidad_viento_km_h)) +
  geom_line(col = palette.colors(2, "Dark2")[1]) +
  labs(x = "Fecha", y = "Intensidad del viento (Km/H)", col = "") +
  theme_bw())

ggsave("Figuras/Descriptiva/Intensidad_viento_diario.png", plot.viento, width = 10, height = 6)
