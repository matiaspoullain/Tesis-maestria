#### Resultados modelo 1 RF:

library(tidyverse)
library(data.table)
library(lubridate)


datos <- fread("Datos/Resultados_modelos/Modelo_1/predicho_modelo_1_RF.csv", encoding = "UTF-8")

#datos[, c("y", "predicho") := lapply(.SD, function(x) 10**x), .SDcols = c("y", "predicho")]

#datos[, ds := as_datetime(ds)]
windows()
(plot.prediccion.vehiculos <- datos %>%# [between(ds, as.Date("2019-12-20"), as.Date("2020-01-10"))] %>%
  ggplot(aes(x = ds, fill = "Predicción")) +
  geom_point(aes(y = y, col = "Observados")) +
  #geom_ribbon(aes(ymin = yhat_lower, ymax = yhat_upper), alpha = 0.3) +
  geom_line(aes(y = predicho, col = "Predicción")) +
  theme_bw() +
  scale_fill_manual(name = "", values = c("Predicción" = "#D95F02", "Observados" = "transparent")) +
  scale_color_manual(name = "", values = c("Predicción" = "#D95F02", "Observados" = "black")) +
  geom_vline(xintercept = as_datetime("2020-03-20"), linetype = "dashed") +
  labs(x = "Hora y fecha", y = "Conteo vehicular horario") +
  theme(legend.position = "top") +
  scale_x_datetime(date_breaks = "1 day", labels = function(x) format(x, "%d %b %Y")))

#ggsave("Figuras/Modelo_1/Prediccion_m1.png", plot.prediccion.vehiculos, width = 10, height = 6)  



#Importancia:

importancia <- fread("Datos/Resultados_modelos/Modelo_1/importancia_RF.csv", encoding = "UTF-8")
importancia[, variables := fct_reorder(variables, importancia)]
windows()
(importancia %>%
  arrange(desc(importancia)))[1:50] %>%
  ggplot(aes(x = variables, y = importancia)) +
  geom_col() +
  coord_flip()


library(tidyverse)
library(data.table)


windows()
(plot.validacion <- datos %>%
  ggplot(aes(x = y, y = predicho)) +
  geom_point(alpha = 0.2, size = 0.5)+
  #geom_errorbar(alpha = 0.01, width = 0.01) +
  geom_abline(slope = 1, intercept = c(0, 0), linetype = "dashed", col = "#D95F02") +
  theme_bw() +
  labs(x = "Observados (vehículos/hora)", y = "Predichos (vehículos/hora)"))

#ggsave("Figuras/Modelo_1/Validacion_m1.png", width = 10, height = 6)