#### Resultados modelo 1:

library(tidyverse)
library(data.table)


datos <- fread("Datos/df_prophet_prediccion.csv")


datos

plot.validacion <- datos %>%
  ggplot(aes(x = y, y = yhat, ymin = yhat_lower, ymax = yhat_upper)) +
  geom_point(alpha = 0.5, size = 0.5)+
  geom_errorbar(alpha = 0.3, width = 1) +
  geom_abline(slope = 1, intercept = c(0, 0), linetype = "dashed") +
  theme_bw()

ggsave("Figuras/Modelo_1/Validacion_2.png", width = 10, height = 6)
