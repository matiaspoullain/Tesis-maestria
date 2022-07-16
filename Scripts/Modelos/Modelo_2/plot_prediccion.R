
library(tidyverse)
library(data.table)

datos <- fread("Datos/Resultados_prophet/Modelo_2/resultados_modelo_2_unidades_reales.csv")

datos <- datos[ds < as.Date("2020-11-28")]

datos.obs <- datos[, .(ds, y)]

datos.valores <- datos[, .(ds, prediccion_train, prediccion_test)]

areas <- c("ds", names(datos)[grepl("min|max", names(datos))])

datos.area <- datos[, ..areas]

datos.valores <- datos.valores %>%
  melt(id.vars = "ds")

datos.area <- datos.area %>%
  melt(id.vars = "ds")

datos.area[, c("origen", "variable") := .(fifelse(grepl("train", variable), "prediccion_train", "prediccion_test"),
                                          fifelse(grepl("max", variable), "max", "min"))]

datos.area <- datos.area %>%
  dcast(ds + origen ~ variable)

datos <- merge(datos.valores, datos.area, by.x = c("ds", "variable"), by.y = c("ds", "origen"), all = TRUE)


plot.pred <- datos %>%
  ggplot(aes(x = ds, y = value)) +
  geom_ribbon(aes(fill = variable, ymin = min, ymax = max), alpha = 0.3) +
  geom_line(aes(col = variable)) +
  geom_point(data = datos.obs, aes(y = y, col = "Observados", fill = "Observados")) +
  theme_bw() +
  scale_fill_manual(name = "",
                    labels = c("Observados",
                               expression(paste(NO[2], "R")),
                               expression(paste(NO[2], "SR"))),
                    values = c("Observados" = "transparent", 
                               "prediccion_test" = "#D95F02",
                               "prediccion_train" = "#1B9E77")) +
  scale_color_manual(name = "",
                     labels = c("Observados",
                                expression(paste(NO[2], "R")),
                                expression(paste(NO[2], "SR"))),
                     values = c("Observados" = "black", 
                                "prediccion_test" = "#D95F02",
                                "prediccion_train" = "#1B9E77")) +
  labs(x = "Fecha", y = expression(paste("Columna de ", NO[2], " troposférico (", mu, "mol.", m^-2, ")"))) +
  theme(legend.position = "top") +
  geom_vline(xintercept = as.Date("2020-03-20"), linetype = "dashed", alpha = 0.8) +
  scale_x_date(date_breaks = "3 months", labels = function(x) format(x, "%d %b %Y"))

ggsave("Figuras/Modelo_2/Prediccion_m2.png", plot.pred, width = 10, height = 6)

  
