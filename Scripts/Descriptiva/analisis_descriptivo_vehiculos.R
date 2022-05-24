rm(list=ls())
gc()

##### Analisis descriptivo vehiculos ####
library(tidyverse)
library(data.table)
library(xlsx)
library(ggpubr)


#### Medidas resumen de circulacion vehicular comparando antes y despues de restricciones: ####
vehiculos <- fread("Datos/Procesados/conteo_vehicular.csv")
feriados <- fread("Datos/feriados.csv", encoding = "UTF-8")

# Total periodos:
vehiculos[, periodo := fifelse(fecha_hora < as.Date("2020-03-20"), "Previo a restricciones", "Durante las restricciones") %>%
            as.factor() %>%
            fct_rev()]

tabla.resumen <- vehiculos[, .(Promedio = mean(cantidad_pasos, na.rm = TRUE) %>% round(3),
                               Mediana = median(cantidad_pasos, na.rm = TRUE) %>% round(3), 
                               `Desvío estándar` = sd(cantidad_pasos, na.rm = TRUE) %>% round(3),
                               Máximo = max(cantidad_pasos, na.rm = TRUE) %>% round(3),
                               Mínimo = min(cantidad_pasos, na.rm = TRUE) %>% round(3)),
                           by = .(Período =  periodo)]

write.xlsx(tabla.resumen, file = "Figuras/Descriptiva/Tabla_resumen_periodo.xlsx")

vehiculos %>%
  ggplot(aes(x = periodo, y = cantidad_pasos)) +
  geom_boxplot()

vehiculos %>%
  ggplot(aes(x = cantidad_pasos, fill = periodo, col = periodo)) +
  geom_histogram(alpha = 0.4, position = "identity")


#Por mes:
vehiculos[, c("anio", "mes") := .(year(fecha_hora), months(fecha_hora) %>%
                                    str_to_title() %>%
                                    factor(levels = c("Enero","Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre")))]

vehiculos %>%
  ggplot(aes(x = as.factor(mes), y = cantidad_pasos, fill = as.factor(anio))) +
  geom_boxplot()

(plot.hist.mes <- vehiculos %>%
    ggplot(aes(x = cantidad_pasos, fill = periodo, col = periodo)) +
    geom_histogram(alpha = 0.4, position = "identity") +
    facet_grid(mes~anio) +
    labs(x = "Cantidad de vehículos contados por hora", y = "Frecuencia", fill = "Período", col = "Período") +
    scale_color_brewer(palette = "Dark2") +
    scale_fill_brewer(palette = "Dark2") +
    theme_bw()+
    theme(legend.position = "top"))

ggsave("Figuras/Descriptiva/Histograma_mes.png", plot.hist.mes, width = 5, height = 10)


# Por semana
vehiculos[, id_semana := paste0(week(fecha_hora), "_", year(fecha_hora), "_", periodo)]

(boxplot.semana <- vehiculos %>%
  ggplot(aes(x = fecha_hora, y = cantidad_pasos, group = id_semana, fill = periodo)) +
  geom_boxplot(alpha = 0.8) +
  scale_fill_brewer(palette = "Dark2") +
  theme_bw()+
  theme(legend.position = "top") +
  labs(x = "Fecha", y = "Cantidad de vehículos contados por hora", fill = "Período"))
  
ggsave("Figuras/Descriptiva/Boxplot_semana.png", boxplot.semana, width = 9, height = 5)



#Por dia de la semana:
vehiculos[, dia_semana := weekdays(fecha_hora) %>%
            str_to_title() %>%
            factor(levels = c("Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"))]

vehiculos %>%
  ggplot(aes(x = dia_semana, y = cantidad_pasos, fill = periodo)) +
  geom_boxplot()

vehiculos %>%
  ggplot(aes(x = cantidad_pasos, fill = periodo, col = periodo)) +
  geom_histogram(alpha = 0.4, position = "identity") +
  facet_wrap(dia_semana~., ncol = 3)


(plot.variacion.semanal <- vehiculos[, .(cantidad_pasos_medio = mean(cantidad_pasos, na.rm = TRUE),
              cantidad_pasos_sd = sd(cantidad_pasos, na.rm = TRUE)), by = .(dia_semana, periodo)] %>%
  ggplot(aes(x = as.numeric(dia_semana), y = cantidad_pasos_medio))+
  geom_ribbon(aes(ymin = cantidad_pasos_medio - cantidad_pasos_sd, ymax = cantidad_pasos_medio + cantidad_pasos_sd, fill = periodo), alpha = 0.3) +
  geom_line(aes(col = periodo))+
  scale_x_continuous(breaks = 1:7, labels = levels(vehiculos$dia_semana), minor_breaks = NULL) +
  scale_fill_brewer(palette = "Dark2") +
  scale_color_brewer(palette = "Dark2") +
  theme_bw()+
  theme(legend.position = "top") +
  labs(x = "Día de la semana", y = "Cantidad de vehículos contados por hora", fill = "Período", col = "Período"))

ggsave("Figuras/Descriptiva/Linea_semanal.png", plot.variacion.semanal, width = 9, height = 5)



#Por hora del dia:

vehiculos[, c("hora", "condicion_dia") := .(hour(fecha_hora),
                                            fcase(as.Date(fecha_hora) %in% feriados$ds, "Feriado",
                                                  dia_semana %in% c("Sábado", "Domingo"), "Fin de semana",
                                                  default = "Día de semana") %>%
                                              factor(levels = c("Día de semana", "Fin de semana", "Feriado")))]

vehiculos %>%
  ggplot(aes(x = hora, y = cantidad_pasos, col = periodo, group = interaction(hora, periodo, condicion_dia))) +
  geom_boxplot()+
  facet_wrap(condicion_dia~.)

(plot.horario <- vehiculos[, .(cantidad_pasos_medio = mean(cantidad_pasos, na.rm = TRUE),
              cantidad_pasos_sd = sd(cantidad_pasos, na.rm = TRUE)), by = .(hora, periodo, condicion_dia)] %>%
  ggplot(aes(x = hora, y = cantidad_pasos_medio))+
  geom_ribbon(aes(ymin = cantidad_pasos_medio - cantidad_pasos_sd, ymax = cantidad_pasos_medio + cantidad_pasos_sd, fill = periodo), alpha = 0.3) +
  geom_line(aes(col = periodo))+
  facet_wrap(condicion_dia~.) +
  scale_fill_brewer(palette = "Dark2") +
  scale_color_brewer(palette = "Dark2") +
  theme_bw()+
  theme(legend.position = "none") +
  labs(x = "Hora del día", y = "Cantidad de vehículos contados por hora", fill = "Período", col = "Período"))

ggsave("Figuras/Descriptiva/Linea_horaria.png", plot.horario, width = 8, height = 4)


plot.variaciones <- ggarrange(plot.variacion.semanal, plot.horario, nrow = 2, labels = c("A", "B"))

ggsave("Figuras/Descriptiva/Lineas_semanal_horaria.png", plot.variaciones, width = 9, height = 10)

vehiculos %>%
  ggplot(aes(x = cantidad_pasos, col = periodo, fill = periodo)) +
  geom_histogram()+
  facet_grid(hora~condicion_dia)


#### Autocorrelogramas ####
#Horario
library(ggfortify)

autocorrelacion.horaria <- acf(vehiculos$cantidad_pasos, lag.max = 200, pl=FALSE)

intervalo.confianza <- ggfortify:::confint.acf(autocorrelacion.horaria, ci.type = 'ma')

(plot.acf.horaria <- data.table(Autocorrelación = autocorrelacion.horaria$acf,
                                Lag = autocorrelacion.horaria$lag,
                                intervalo = intervalo.confianza) %>%
                       ggplot(aes(x = Lag, y = Autocorrelación)) +
                       geom_ribbon(aes(ymin = -intervalo, ymax = intervalo), alpha = 0.3, fill = palette.colors(1, "Dark2")) +
                       geom_segment(aes(xend = Lag, y = 0, yend = Autocorrelación)) +
                       geom_point(col = palette.colors(1, "Dark2")) +
                       geom_hline(yintercept = 0, linetype = "dashed") +
                       theme_bw()+
                       labs(x = "Lag (Horas)"))

ggsave("Figuras/Descriptiva/Autocorrelograma_vehiculos_horaria.png", plot.acf.horaria, width = 8, height = 4)


#Diario
library(ggfortify)

vehiculos.diarios <- vehiculos[fecha_hora < as.Date("2020-03-20"), .(cantidad_pasos = sum(cantidad_pasos, na.rm = TRUE)), by = .(fecha = (as.Date(fecha_hora)))]

autocorrelacion.diaria <- acf(vehiculos.diarios$cantidad_pasos, lag.max = 500, pl=FALSE)

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
