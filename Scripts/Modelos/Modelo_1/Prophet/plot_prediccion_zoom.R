#### Resultados modelo 1:

library(tidyverse)
library(data.table)
library(lubridate)

observados <- fread(file.path("Datos","Insumo_modelos", "Modelo_1.csv"))[, .(ds, y = 10**y)]
datos <- fread(file.path("Datos","Resultados_modelos", "Modelo_1", "prediccion.csv")) %>%
  merge(observados, by = 'ds')

#datos[, ds := as_datetime(ds)]

plot.prediccion.vehiculos <- datos[between(ds, as.Date("2020-03-17"), as.Date("2020-03-24"))] %>%
  ggplot(aes(x = ds, fill = "Predicción")) +
  geom_point(aes(y = y, col = "Observados")) +
  geom_ribbon(aes(ymin = yhat_lower, ymax = yhat_upper), alpha = 0.3) +
  geom_line(aes(y = yhat, col = "Predicción")) +
  theme_bw() +
  scale_fill_manual(name = "", values = c("Predicción" = "#D95F02", "Observados" = "transparent")) +
  scale_color_manual(name = "", values = c("Predicción" = "#D95F02", "Observados" = "black")) +
  geom_vline(xintercept = as_datetime("2020-03-20"), linetype = "dashed") +
  labs(x = "Hora y fecha", y = "Conteo vehicular horario") +
  theme(legend.position = "top") +
  scale_x_datetime(date_breaks = "1 day", labels = function(x) format(x, "%d %b %Y"))

ggsave("Figuras/Modelo_1/Prediccion_m1.png", plot.prediccion.vehiculos, width = 10, height = 6)  


datos[between(ds, as.Date("2019-03-01"), as.Date("2019-04-30")), zoom := "Marzo y abril 2019"]
datos[between(ds, as.Date("2020-03-01"), as.Date("2020-04-30")), zoom := "Marzo y abril 2020"]



plot_predicciones_meses <- datos[!is.na(zoom)] %>%
  ggplot(aes(x = ds, fill = "Predicción")) +
  geom_line(aes(y = y, col = "Observados")) +
  geom_ribbon(aes(ymin = yhat_lower, ymax = yhat_upper), alpha = 0.3) +
  geom_line(aes(y = yhat, col = "Predicción")) +
  theme_bw() +
  scale_fill_manual(name = "", values = c("Predicción" = "#D95F02", "Observados" = "transparent")) +
  scale_color_manual(name = "", values = c("Predicción" = "#D95F02", "Observados" = "black")) +
  scale_linetype_manual(name = "", values = c("Incio restricciones" = "dashed")) +
  geom_vline(aes(xintercept = as_datetime("2020-03-20"), linetype = "Incio restricciones")) +
  labs(x = "Hora y fecha", y = "Conteo vehicular horario") +
  theme(legend.position = "top") +
  scale_x_datetime(date_breaks = "10 days", labels = function(x) format(x, "%d %b %Y"), expand = c(0, 0))+
  facet_wrap(zoom~., scales = "free_x", ncol = 1)

ggsave("Figuras/Modelo_1/Prediccion_m1_meses.png", plot_predicciones_meses, width = 10, height = 6)  
