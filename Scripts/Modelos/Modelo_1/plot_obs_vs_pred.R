#### Resultados modelo 1:

library(tidyverse)
library(data.table)


datos <- fread("Datos/df_prophet_prediccion.csv")

plot.validacion <- datos %>%
  ggplot(aes(x = y, y = yhat, ymin = yhat_lower, ymax = yhat_upper)) +
  geom_point(alpha = 0.2, size = 0.5)+
  geom_errorbar(alpha = 0.01, width = 0.01) +
  geom_abline(slope = 1, intercept = c(0, 0), linetype = "dashed", col = "#D95F02") +
  theme_bw() +
  labs(x = "Observados (vehículos/hora)", y = "Predichos (vehículos/hora)")

ggsave("Figuras/Modelo_1/Validacion_m1.png", width = 10, height = 6)
