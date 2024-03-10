rm(list=ls())
gc()

##### Analisis descriptivo NO2 y variables meteorológicas ####
library(tidyverse)
library(data.table)
library(scales)

#### NO2 ####

no2 <- fread("Datos/Procesados/no2_diario_procesado.csv")

# Grafico crudo:

(plot.no2 <- no2 %>%
  ggplot(aes(x = fecha, y = NO2_trop_mean, ymin = NO2_trop_mean -NO2_trop_std, ymax = NO2_trop_mean + NO2_trop_std)) +
  geom_ribbon(alpha = .5, fill = palette.colors(2, "Dark2")[2]) +
  geom_line(col = palette.colors(2, "Dark2")[2]) +
    scale_x_date(breaks = date_breaks("4 month")) +
  theme_bw()+
    geom_vline(xintercept = as.Date("2020-03-20"), alpha = 0.3, linetype = "dashed")+
    labs(x = "Fecha", y = expression(paste("Concentración promedio de ", NO[2], " troposférico (", mu, "mol.", m^-2, ")")), fill = "Período", col = "Período"))

ggsave("Figuras/Descriptiva/Linea_NO2.png", plot.no2, width = 12, height = 6)


# Variacion semanal segun periodo:
no2[, c("periodo", "dia_semana") := .(fifelse(fecha < as.Date("2020-03-20"), "Previo a restricciones", "Durante las restricciones") %>%
                                        as.factor() %>%
                                        fct_rev(),
                                      weekdays(fecha) %>%
                                        str_to_title() %>%
                                        factor(levels = c("Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo")))]


(plot.variacion.semanal <- no2[, .(NO2_trop_medio = mean(NO2_trop_mean, na.rm = TRUE),
                                   NO2_trop_sd = sd(NO2_trop_mean, na.rm = TRUE)), by = .(dia_semana, periodo)] %>%
    ggplot(aes(x = as.numeric(dia_semana), y = NO2_trop_medio))+
    geom_ribbon(aes(ymin = NO2_trop_medio - NO2_trop_sd, ymax = NO2_trop_medio + NO2_trop_sd, fill = periodo), alpha = 0.3) +
    geom_line(aes(col = periodo))+
    scale_x_continuous(breaks = 1:7, labels = levels(no2$dia_semana), minor_breaks = NULL) +
    scale_fill_brewer(palette = "Dark2") +
    scale_color_brewer(palette = "Dark2") +
    theme_bw()+
    theme(legend.position = "top") +
    labs(x = "Día de la semana", y = "Cantidad de vehículos contados por hora", fill = "Período", col = "Período"))


(plot.variacion.semanal.cuantil <- no2[, .(NO2_trop_medio = median(NO2_trop_mean, na.rm = TRUE),
                                   NO2_trop_2.5 = quantile(NO2_trop_mean, 0.025, na.rm = TRUE),
                                   NO2_trop_97.5 = quantile(NO2_trop_mean, 0.975, na.rm = TRUE)), by = .(dia_semana, periodo)] %>%
    ggplot(aes(x = as.numeric(dia_semana), y = NO2_trop_medio))+
    geom_ribbon(aes(ymin = NO2_trop_2.5, ymax = NO2_trop_97.5, fill = periodo), alpha = 0.3) +
    geom_line(aes(col = periodo))+
    scale_x_continuous(breaks = 1:7, labels = levels(no2$dia_semana), minor_breaks = NULL) +
    scale_fill_brewer(palette = "Dark2") +
    scale_color_brewer(palette = "Dark2") +
    theme_bw()+
    theme(legend.position = "top") +
    labs(x = "Día de la semana", y = "Cantidad de vehículos contados por hora", fill = "Período", col = "Período"))



(boxplot.semanal <- no2 %>%
  ggplot(aes(x = dia_semana, y = NO2_trop_mean, fill = periodo)) +
  geom_boxplot() +
  scale_fill_brewer(palette = "Dark2") +
  theme_bw()+
  theme(legend.position = "top") +
  labs(x = "Día de la semana", y = expression(paste("Concentración promedio de ", NO[2], " troposférico (", mu, "mol.", m^-2, ")")), fill = "Período"))


ggsave("Figuras/Descriptiva/Boxplot_semanal_NO2.png", boxplot.semanal, width = 10, height = 6)


## Autocorrelogramas:
library(ggfortify)
#Diaria

autocorrelacion.diaria <- acf(no2$NO2_trop_mean, lag.max = 28, pl=FALSE, na.action = na.pass)

intervalo.confianza <- ggfortify:::confint.acf(autocorrelacion.diaria, ci.type = 'ma')

(plot.acf.diaria <- data.table(Autocorrelación = autocorrelacion.diaria$acf,
                               Lag = autocorrelacion.diaria$lag,
                               intervalo = intervalo.confianza) %>%
    ggplot(aes(x = Lag, y = Autocorrelación)) +
    geom_ribbon(aes(ymin = -intervalo, ymax = intervalo), alpha = 0.3, fill = palette.colors(1, "Dark2")) +
    geom_segment(aes(xend = Lag, y = 0, yend = Autocorrelación)) +
    geom_point(col = palette.colors(1, "Dark2")) +
    geom_hline(yintercept = 0, linetype = "dashed") +
    theme_bw()+
    labs(x = "Lag (Días)"))

ggsave("Figuras/Descriptiva/Autocorrelograma_no2_diaria.png", plot.acf.diaria, width = 8, height = 4)


#Semanal

no2[, semana := floor((0:(.N-1))/7)]

no2.semana <- no2[, .(NO2_trop_mean = mean(NO2_trop_mean, na.rm = TRUE)), by = semana]

autocorrelacion.semanal <- acf(no2.semana$NO2_trop_mean, lag.max = 150, pl=FALSE, na.action = na.pass)

intervalo.confianza <- ggfortify:::confint.acf(autocorrelacion.semanal, ci.type = 'ma')

(plot.acf.semanal <- data.table(Autocorrelación = autocorrelacion.semanal$acf,
                               Lag = autocorrelacion.semanal$lag,
                               intervalo = intervalo.confianza) %>%
    ggplot(aes(x = Lag, y = Autocorrelación)) +
    geom_ribbon(aes(ymin = -intervalo, ymax = intervalo), alpha = 0.3, fill = palette.colors(1, "Dark2")) +
    geom_segment(aes(xend = Lag, y = 0, yend = Autocorrelación)) +
    geom_point(col = palette.colors(1, "Dark2")) +
    geom_hline(yintercept = 0, linetype = "dashed") +
    theme_bw() +
    labs(x = "Lag (Semanas)") +
    scale_x_continuous(breaks = seq(0, 150, 10)))

ggsave("Figuras/Descriptiva/Autocorrelograma_no2_semanal.png", plot.acf.semanal, width = 8, height = 4)
