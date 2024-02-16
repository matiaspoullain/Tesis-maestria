#### dominio frecuencia de los datos:
rm(list = ls())
gc()

library(tidyverse)
library(data.table)
library(ggrepel)
library(zoo)

vehiculos <- fread("Datos/Procesados/conteo_vehicular.csv")
no2 <- fread("Datos/Procesados/no2_diario_procesado.csv")

#vehiculos:


DeltaT <- 1 # horas
FrecuenciaMuestreo <- 1/DeltaT
DeltaFrecMuestreo <- FrecuenciaMuestreo/nrow(vehiculos)

vehiculos[, c("frecuencia", "fft_valor") := .(DeltaFrecMuestreo * 0:(.N-1), fft(cantidad_pasos))]

vehiculos[1, fft_valor := 0]

medio <- max(vehiculos$frecuencia) / 2

freq.inv.seleccionados <- Mod(vehiculos$fft_valor) %>%
  sort(decreasing = TRUE)
freq.inv.seleccionados <- c(freq.inv.seleccionados[1:5])
horas.seleccionadas <- c(24*7 + 0.6923, 8, 6)

(plot.df <- vehiculos[frecuencia <= medio]%>%
  ggplot(aes(x = frecuencia, y = Mod(fft_valor), label = fifelse(round(Mod(fft_valor)) %in% round(freq.inv.seleccionados) | round(1/frecuencia, 4) %in% horas.seleccionadas, paste(round(1/frecuencia, 1), 'Hs'), NA_character_))) +
  geom_line() +
  geom_text(vjust = -1) + 
  scale_x_continuous(label = function(x) round(1/x, 2), n.breaks = 20) +
  theme_bw() +
  labs(x = "1/Frecuencia (Hs)", y = "Espectro de la Amplitud"))

ggsave("Figuras/Descriptiva/dominio_frecuencia_vehiculos.png", plot.df, width = 10, height = 6)


#no2:
DeltaT <- 1 # dias
FrecuenciaMuestreo <- 1/DeltaT
DeltaFrecMuestreo <- FrecuenciaMuestreo/nrow(no2)

no2[, no2_approx := na.approx(NO2_trop_mean)]

no2[, c("frecuencia", "fft_valor") := .(DeltaFrecMuestreo * 0:(.N-1), fft(no2_approx))]

no2[1, fft_valor := 0]

medio <- max(no2$frecuencia) / 2

no2[, fft_valor := Mod(fft_valor)]

etiquetas.grandes <- no2$fft_valor[order(-no2$fft_valor)][12]

(plot.df <- no2[frecuencia <= medio]%>%
  ggplot(aes(x = frecuencia, y = Mod(fft_valor), label = ifelse(fft_valor >= etiquetas.grandes, paste(round(1/frecuencia, 2), 'días'), NA_character_))) +
  geom_line() +
  geom_text_repel(box.padding = 0.5, min.segment.length = 0.2) + 
  scale_x_continuous(label = function(x) round(1/x, 2), n.breaks = 20) +
  theme_bw() +
  labs(x = "1/Frecuencia (Días)", y = "Espectro de la amplitud"))

ggsave("Figuras/Descriptiva/dominio_frecuencia_no2.png", plot.df, width = 10, height = 6)
