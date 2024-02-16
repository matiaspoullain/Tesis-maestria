library(tidyverse)
library(data.table)
library(Metrics)
library(RColorBrewer)
library(scales)


carpeta.archivos <- "Datos/Resultados_modelos/Modelo_2/"
nombre.archivos <- "prediccion_heldout.csv"
carpeta.figuras <- "Figuras/Modelo_2/"
imagen.comparaciones <- file.path(carpeta.figuras, "comparacion_metricas.png")
imagen.predicciones <- file.path(carpeta.figuras, "comparacion_predicciones_heldout.png")
archivo.comparaciones <- file.path(carpeta.archivos, "General", "metricas.csv")


archivos <- list.files(carpeta.archivos, recursive = TRUE, full.names = TRUE)
archivos <- archivos[archivos %like% nombre.archivos]

r2 = function(y_actual,y_predict){
  cor(y_actual,y_predict)^2
}

lista.df <- list()
for(i in 1:length(archivos)){
  nombre.modelo <- basename(dirname(archivos[i]))
  df.it <- fread(archivos[i])
  df.it[, modelo := nombre.modelo]
  df.it <- df.it[, -c("yhat_lower", "yhat_upper")]
  lista.df[[i]] <- df.it
}

df <- rbindlist(lista.df)
df.missing <- copy(df)



# Metricas: plot y csv ----------------------------------------------------

df <- df[!is.na(y)]
df.agg <- df[, .(RMSE = rmse(y, yhat),
                 MAPE = mape(y, yhat),
                 R2 = r2(y, yhat)), by = modelo]

columnas.metricas <- names(df.agg)[names(df.agg) != 'modelo']

df.agg <- melt(df.agg, id.vars = "modelo")

fwrite(df.agg, archivo.comparaciones)

(plot.metricas <- df.agg %>%
  ggplot(aes(x = modelo, y = value)) +
  geom_col(fill = "gray70") +
  facet_wrap(variable~., scales = "free") +
  theme_bw() +
  labs(x = 'Modelo', y = 'Valor'))

ggsave(imagen.comparaciones, plot.metricas, width = 10, height = 6)



# Plot predicciones -------------------------------------------------------
modelos <- c('Observados', sort(unique(df.missing$modelo)))
colores <- c('black', brewer.pal(8, "Dark2")[1:length(modelos)-1])
names(colores) <- modelos 


plot.predicciones <- df.missing %>%
  ggplot(aes(x = ds)) +
  geom_point(aes(y = y, col = 'Observados')) +
  geom_line(aes(y = yhat, col = modelo)) +
  theme_bw() +
  scale_x_date(date_breaks = '4 days', labels = function(x) format(x, "%d %b %Y")) +
  labs(
    y = expression(paste("Concentración promedio de ", NO[2], " troposférico (", mu, "mol.", m^-2, ")")),
    x = "Fecha",
    col = 'Modelos') +
  scale_color_manual(values = colores)

ggsave(imagen.predicciones, plot.predicciones, width = 10, height = 6)