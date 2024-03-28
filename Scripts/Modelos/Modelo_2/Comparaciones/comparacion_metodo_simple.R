library(tidyverse)
library(data.table)
library(raster)
library(sf)

prop_area <- fread('Datos/Resultados_modelos/Modelo_2/General/Q_mesual.csv')

#Calculo por comparacion de promedio de pixeles mensual:
mascara <- st_read("Datos/Georreferenciados/mask/mask.geojson")
raster.2019 <- raster("Datos/Georreferenciados/NO2_tropomi_mensual/2019-04-01 00_00_00.tif")
raster.2020 <- raster("Datos/Georreferenciados/NO2_tropomi_mensual/2020-04-01 00_00_00.tif")

promedio.2019.sin.mascara <- mean(values(raster.2019))
promedio.2019.con.mascara <- mean(extract(raster.2019, mascara)[[1]])
promedio.2020.sin.mascara <- mean(values(raster.2020))
promedio.2020.con.mascara <- mean(extract(raster.2020, mascara)[[1]])

prop.sin.mascara <- promedio.2020.sin.mascara / promedio.2019.sin.mascara

prop.con.mascara <- promedio.2020.con.mascara / promedio.2019.con.mascara

cat("Sin mascara: ", prop.sin.mascara)
cat("Con mascara: ", prop.con.mascara)


dt.valores <- data.table(
  mascara = c(rep(TRUE, length(extract(raster.2019, mascara)[[1]])),
              rep(FALSE, length(values(raster.2019))),
              rep(TRUE, length(extract(raster.2020, mascara)[[1]])),
              rep(FALSE, length(values(raster.2020)))),
  anio = c(rep(2019, length(extract(raster.2019, mascara)[[1]])),
           rep(2019, length(values(raster.2019))),
           rep(2020, length(extract(raster.2020, mascara)[[1]])),
           rep(2020, length(values(raster.2020)))),
  valor = c(extract(raster.2019, mascara)[[1]],
            values(raster.2019),
            extract(raster.2020, mascara)[[1]],
               values(raster.2020))
)

dt.valores.medios <- dt.valores[, .(valor = mean(valor)), by = .(anio, mascara)]

dt.valores  %>%
  ggplot(aes(x = valor, fill = as.factor(anio))) +
  geom_histogram(alpha = 0.5) +
  facet_wrap(mascara~., scales = 'free') +
  geom_vline(data = dt.valores.medios, aes(xintercept = valor, col = as.factor(anio)), linetype ='dashed')


#Histograma cociente pixeles:
dt.valores.cociente <- data.table(
  mascara = c(rep(TRUE, length(extract(raster.2019, mascara)[[1]] / extract(raster.2020, mascara)[[1]])),
              rep(FALSE, length(values(raster.2019) / values(raster.2020)))),
  anio = c(rep(2019, length(extract(raster.2019, mascara)[[1]] / extract(raster.2020, mascara)[[1]])),
           rep(2019, length(values(raster.2019) / values(raster.2020)))),
  valor = c(extract(raster.2019, mascara)[[1]] / extract(raster.2020, mascara)[[1]],
            values(raster.2019) / values(raster.2020))
)

dt.valores.cocientes.medios <- dt.valores.cociente[, .(valor = mean(valor)), by = .(anio, mascara)]

dt.valores.cociente  %>%
  ggplot(aes(x = valor, fill = as.factor(anio))) +
  geom_histogram(alpha = 0.5) +
  facet_wrap(mascara~., scales = 'free') +
  geom_vline(data = dt.valores.cocientes.medios, aes(xintercept = valor, col = as.factor(anio)), linetype ='dashed')
