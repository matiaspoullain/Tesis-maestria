rm(list = ls())
gc()

library(tidyverse)
library(data.table)
library(raster)
library(sf)
library(ggspatial)
library(ggthemes)
library(lemon)
library(scales)

r.2019 <- raster("Datos/Georreferenciados/NO2_tropomi_mensual/2019-04-01 00_00_00.tif")
r.2020 <- raster("Datos/Georreferenciados/NO2_tropomi_mensual/2020-04-01 00_00_00.tif")
r.cociente <- r.2020/r.2019
names(r.cociente) <- "columna"
r.cociente <- as.data.frame(r.cociente, xy = TRUE)
setDT(r.cociente)

provincias <- st_read("Datos/Georreferenciados/Departamentos/pxdptodatosok.shp")

caba_buffer <- st_read("Datos/Georreferenciados/bb_caba_buffer.geojson", crs = 'EPSG:4326')

mask <- st_read("Datos/Georreferenciados/mask/mask.geojson", crs = 4326)

leyenda <- expression(
  atop(
    "Cociente abril 2020 / abril 2019
    de la columna promedio de", paste(NO[2], " troposférico")
  )
)

r.cociente[columna > 1.7, columna := 1.7]
r.cociente[columna < 0.3, columna := 0.3]

mapa_cociente <- ggplot() +
  geom_raster(data = r.cociente, aes(x = x, y = y, fill = columna)) +
  geom_sf(data = provincias, fill = "transparent") +
  theme_bw() +
  annotation_scale(
    location = "br",
    bar_cols = c("grey60", "white")) +
  annotation_north_arrow(
    location = "tr", which_north = "true",
    pad_x = unit(0.25, "cm"), pad_y = unit(0.25, "cm"),
    style = north_arrow_fancy_orienteering(),
    height = unit(1, "cm"), width = unit(1, "cm")) +
  scale_x_continuous(labels = function(x) paste0(abs(x), "°O")) +
  labs(fill = leyenda)+
  theme(axis.title = element_blank()) +
  coord_sf(c(st_bbox(caba_buffer)$xmin, st_bbox(caba_buffer)$xmax),c(st_bbox(caba_buffer)$ymin, st_bbox(caba_buffer)$ymax)) +
  scale_fill_fermenter(n.breaks = 9, palette = "PuOr")

ggsave("Figuras/Descriptiva/mapa_cociente_abriles.png", mapa_cociente, width = 10, height = 8)
