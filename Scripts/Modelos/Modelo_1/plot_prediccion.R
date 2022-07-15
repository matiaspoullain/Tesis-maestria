#### Resultados modelo 1:

library(tidyverse)
library(data.table)


datos <- fread("Datos/df_prophet_prediccion.csv")

#datos[, ds := as_datetime(ds)]

plot.prediccion.vehiculos <- datos[between(ds, as.Date("2020-03-17"), as.Date("2020-03-24"))] %>%
  ggplot(aes(x = ds)) +
  geom_point(aes(y = y, col = "Observados")) +
  geom_ribbon(aes(ymin = yhat_lower, ymax = yhat_upper, fill = "Intervalo de incerteza"), alpha = 0.3) +
  geom_line(aes(y = yhat, col = "Predicción")) +
  theme_bw() +
  scale_fill_manual(name = "", values = c("Intervalo de incerteza" = "#D95F02")) +
  scale_color_manual(name = "", values = c("Predicción" = "#D95F02", "Observados" = "black")) +
  geom_vline(xintercept = as_datetime("2020-03-20"), linetype = "dashed") +
  labs(x = "Hora y fecha", y = "Conteo vehicular horario") +
  theme(legend.position = "top") +
  scale_x_datetime(date_breaks = "1 day", labels = function(x) format(x, "%d %b %Y"))

ggsave("Figuras/Modelo_1/Prediccion.png", plot.prediccion.vehiculos, width = 10, height = 6)  
