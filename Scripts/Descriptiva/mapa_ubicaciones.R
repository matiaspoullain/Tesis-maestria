rm(list = ls())
gc()


library(tidyverse)
library(data.table)
library(sf)
library(ggspatial)
library(ggthemes)
library(lemon)
library(scales)
library(RColorBrewer)

provincias <- st_read("Datos/Georreferenciados/Departamentos/pxdptodatosok.shp")

caba_buffer <- st_read("Datos/Georreferenciados/bb_caba_buffer.geojson", crs = 'EPSG:4326')


ubicacion_peajes <- fread("Datos/Crudos/peajes-y-porticos-autopistas.csv")

ubicacion_peajes[, tipo := "Peaje"]
ubicacion_peajes = ubicacion_peajes[, .(tipo, lat, long)]

ubicacion.smn <- data.table(tipo = 'Estación meteorológica', lat = -34 - 35/60, long = -58 - 29/60)
ubicaciones <- rbind(ubicacion_peajes, ubicacion.smn)





ubicaciones <- st_as_sf(x = ubicaciones,                         
                             coords = c("long", "lat"),
                             crs = st_crs(provincias))

#MAPA

achica.mapa <- 0.2

mapa_ubicaciones <- ggplot() +
  geom_sf(data = provincias, fill = "transparent") +
  geom_sf(data = ubicaciones, aes(col = tipo), shape = 5, size = 5) +
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
  labs(col = "Construcción") +
  theme(axis.title = element_blank(), legend.position = "top") +
  coord_sf(c(st_bbox(caba_buffer)$xmin + achica.mapa, st_bbox(caba_buffer)$xmax - achica.mapa),c(st_bbox(caba_buffer)$ymin + achica.mapa, st_bbox(caba_buffer)$ymax - achica.mapa)) +
  scale_color_manual(values = RColorBrewer::brewer.pal(2, "Dark2"))

ggsave("Figuras/Descriptiva/mapa_ubicaciones.png", mapa_ubicaciones, width = 10, height = 8)
