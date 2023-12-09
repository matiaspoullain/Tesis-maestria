library(tidyverse)
library(data.table)
library(Metrics)

carpeta.archivos <- "Datos/Resultados_modelos/Modelo_2/"
nombre.archivos <- "prediccion_heldout.csv"

archivos <- list.files(carpeta.archivos, recursive = TRUE, full.names = TRUE)
archivos <- archivos[archivos %like% nombre.archivos]

lista.df <- list()
for(i in 1:length(archivos)){
  nombre.modelo <- basename(dirname(archivos[i]))
  df.it <- fread(archivos[i])
  df.it[, modelo := nombre.modelo]
  df.it <- df.it[, -c("yhat_lower", "yhat_upper")]
  lista.df[[i]] <- df.it
}

df <- rbindlist(lista.df)
df <- df[!is.na(y)]
df.agg <- df[, .(RMSE = rmse(y, yhat),
                 MAPE = mape(y, yhat)), by = modelo]

columnas.metricas <- names(df.agg)[names(df.agg) != 'modelo']

df.agg <- melt(df.agg, id.vars = "modelo")

df.agg %>%
  ggplot(aes(x = modelo, y = value)) +
  geom_col() +
  facet_wrap(variable~., scales = "free") +
  theme_bw()
