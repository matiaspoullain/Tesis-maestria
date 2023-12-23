
library(tidyverse)
library(data.table)


# Seleccionar resultados del mejor modelo ---------------------------------
carpeta.archivos <- "Datos/Resultados_modelos/Modelo_2/"
carpeta.figuras <- "Figuras/Modelo_2/"
archivo.comparaciones <- file.path(carpeta.archivos, "General", "metricas.csv")
comparaciones <- fread(archivo.comparaciones) 
mejor.modelo <- 'KNN'#comparaciones[variable == 'R2'][value == max(value), as.character(modelo)]

archivo.predicciones.R <- file.path(carpeta.archivos, mejor.modelo, "prediccion.csv")
archivo.predicciones.SR <- file.path(carpeta.archivos, mejor.modelo, "prediccion_sin_restricciones.csv")

lista.predicciones <- lapply(c(archivo.predicciones.R, archivo.predicciones.SR), function(x){
  df <- fread(x)
  df <- df[ds < as.Date("2020-11-28")]
  return(df)
})
names(lista.predicciones) <- c('R', 'SR')


datos.obs <- lista.predicciones[['R']][, .(ds, y)]

datos.valores <- cbind(lista.predicciones[['R']][, .(ds, NO2R = yhat)],
                       lista.predicciones[['SR']][, .(NO2SR = yhat)])


datos.valores <- datos.valores %>%
  melt(id.vars = "ds")

(plot.pred <- datos.valores %>%
  ggplot(aes(x = ds, y = value)) +
  geom_line(aes(col = variable)) +
  geom_point(data = datos.obs, aes(y = y, fill = "Observados")) +
  theme_bw() +
  scale_color_manual(name = "",
                     labels = c(
                                expression(paste(NO[2], "R")),
                                expression(paste(NO[2], "SR"))),
                     values = c( 
                                "NO2R" = "#D95F02",
                                "NO2SR" = "#1B9E77")) +
  labs(
    x = "Fecha",
    y = expression(paste("Columna de ", NO[2], " troposférico (", mu, "mol.", m^-2, ")")),
    fill = '') +
  theme(legend.position = "top") +
  geom_vline(xintercept = as.Date("2020-03-20"), linetype = "dashed", alpha = 0.8) +
  scale_x_date(date_breaks = "3 months", labels = function(x) format(x, "%d %b %Y")))

#ggsave("Figuras/Modelo_2/Prediccion_m2.png", plot.pred, width = 10, height = 6)



# antiguo trabajo con areas -----------------------------------------------


# areas <- c("ds", names(datos)[grepl("min|max", names(datos))])
# 
# datos.area <- datos[, ..areas]
# 
# datos.valores <- datos.valores %>%
#   melt(id.vars = "ds")
# 
# datos.area <- datos.area %>%
#   melt(id.vars = "ds")
# 
# datos.area[, c("origen", "variable") := .(fifelse(grepl("train", variable), "prediccion_train", "prediccion_test"),
#                                           fifelse(grepl("max", variable), "max", "min"))]
# 
# datos.area <- datos.area %>%
#   dcast(ds + origen ~ variable)
# 
# datos <- merge(datos.valores, datos.area, by.x = c("ds", "variable"), by.y = c("ds", "origen"), all = TRUE)
# 
# 
# plot.pred <- datos %>%
#   ggplot(aes(x = ds, y = value)) +
#   geom_ribbon(aes(fill = variable, ymin = min, ymax = max), alpha = 0.3) +
#   geom_line(aes(col = variable)) +
#   geom_point(data = datos.obs, aes(y = y, col = "Observados", fill = "Observados")) +
#   theme_bw() +
#   scale_fill_manual(name = "",
#                     labels = c("Observados",
#                                expression(paste(NO[2], "R")),
#                                expression(paste(NO[2], "SR"))),
#                     values = c("Observados" = "transparent", 
#                                "prediccion_test" = "#D95F02",
#                                "prediccion_train" = "#1B9E77")) +
#   scale_color_manual(name = "",
#                      labels = c("Observados",
#                                 expression(paste(NO[2], "R")),
#                                 expression(paste(NO[2], "SR"))),
#                      values = c("Observados" = "black", 
#                                 "prediccion_test" = "#D95F02",
#                                 "prediccion_train" = "#1B9E77")) +
#   labs(x = "Fecha", y = expression(paste("Columna de ", NO[2], " troposférico (", mu, "mol.", m^-2, ")"))) +
#   theme(legend.position = "top") +
#   geom_vline(xintercept = as.Date("2020-03-20"), linetype = "dashed", alpha = 0.8) +
#   scale_x_date(date_breaks = "3 months", labels = function(x) format(x, "%d %b %Y"))
# 
# ggsave("Figuras/Modelo_2/Prediccion_m2.png", plot.pred, width = 10, height = 6)

  
