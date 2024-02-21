rm(list = ls())
gc() 

library(tidyverse)
library(sf)
library(raster)
library(data.table)
library(ggspatial)
library(ggthemes)
library(lemon)
library(scales)

provincias <- st_read("Datos/Georreferenciados/Departamentos/pxdptodatosok.shp")

bbox.shp <- st_read("Datos/Georreferenciados/bb_caba_buffer.geojson", crs = 'EPSG:4326')

bbox.shp$contorno <- 'Englobamiento inicial CABA'


mask <- st_read("Datos/Georreferenciados/mask/mask.geojson", crs = 4326)
mask$Máscara <- 'Máscara'


mapa_mascara <- ggplot() +
  geom_sf(data = provincias, fill = "transparent") +
  geom_sf(data = bbox.shp, aes(color = contorno), linewidth = 1.05, linetype = 'dashed', alpha = 0) +
  geom_sf(data = mask, aes(fill = Máscara), alpha = 0.2) +
  theme_bw() +
  annotation_scale(
    location = "br",
    bar_cols = c("grey60", "white")) +
  annotation_north_arrow(
    location = "tr", which_north = "true",
    pad_x = unit(0.1, "cm"), pad_y = unit(0.25, "cm"),
    style = north_arrow_fancy_orienteering(),
    height = unit(1, "cm"), width = unit(1, "cm")) +
  coord_sf(c(st_bbox(bbox.shp)$xmin, st_bbox(bbox.shp)$xmax),c(st_bbox(bbox.shp)$ymin, st_bbox(bbox.shp)$ymax)) +
  scale_x_continuous(labels = function(x) paste0(abs(x), "°O")) +
  theme(axis.title = element_blank(), legend.position="top") +
  theme(legend.title=element_blank()) +
  scale_color_manual(values=c("black")) +
  scale_fill_manual(values=c(palette.colors(2, "Dark2")[2]))

ggsave("Figuras/Descriptiva/mapa_mascara.png", mapa_mascara, width = 7, height = 6)

