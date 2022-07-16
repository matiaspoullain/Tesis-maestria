#### Resultados modelo 2:

library(tidyverse)
library(data.table)
library(scales)


datos <- fread("Datos/Resultados_prophet/Modelo_2/resultados_modelo_2_unidades_reales.csv")

plot.validacion <- datos[!is.na(y)] %>%
  ggplot(aes(x = y, y = prediccion_train, ymin = prediccion_train_min, ymax = prediccion_train_max)) +
  geom_point(alpha = 0.5, size = 0.75)+
  geom_errorbar(alpha = 0.3) +
  geom_abline(slope = 1, intercept = c(0, 0), linetype = "dashed") +
  theme_bw() +
  scale_x_continuous(labels = scientific) +
  labs(x = expression(paste("Observados (", mu, "mol.", m^-2, ")")), y = expression(paste("Predichos (", mu, "mol.", m^-2, ")")))

ggsave("Figuras/Modelo_2/Validacion_m2.png", plot.validacion, width = 10, height = 6)
