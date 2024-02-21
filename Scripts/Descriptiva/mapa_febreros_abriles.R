#Mapas de concentraciones mensuales:

library(tidyverse)
library(sf)
library(raster)
library(data.table)
library(ggspatial)
library(ggthemes)
library(lemon)
library(scales)

fechas <- c("2019-02-01", "2019-04-01", "2020-02-01", "2020-04-01")


dt <- data.table()

for(i in fechas){
  cat("\r", which(i == fechas), "de", length(fechas))
  r <- raster::raster(paste0("Datos/Georreferenciados/NO2_tropomi_mensual/", i, " 00_00_00.tif"))
  names(r) <- "columna"
  r <- as.data.frame(r, xy = TRUE)
  setDT(r)
  r[, fecha := i %>%
      as.Date() %>%
      format("%B %Y") %>%
      str_to_title()]
  dt <- rbind(dt, r)
}

dt[, fecha := factor(fecha, levels = ..fechas %>%
                       as.Date() %>%
                       format("%B %Y") %>%
                       str_to_title())]

provincias <- st_read("Datos/Georreferenciados/Departamentos/pxdptodatosok.shp")

caba_buffer <- st_read("Datos/Georreferenciados/bb_caba_buffer.geojson", crs = 'EPSG:4326')

mask <- st_read("Datos/Georreferenciados/mask/mask.geojson", crs = 4326)

leyenda <- expression(
  atop(
    "Columna promedio de", paste(NO[2], " troposférico (", mu, "mol.", m^-2, ")")
  )
)


mapa_desciptivo <- ggplot() +
    geom_raster(data = dt, aes(x = x, y = y, fill = columna)) +
    geom_sf(data = provincias, fill = "transparent") +
    geom_sf(data = mask, linetype = 'dashed', fill = 'transparent', linewidth = 1) +
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
    facet_rep_wrap(fecha~., repeat.tick.labels = TRUE) +
    scale_fill_gradient2_tableau(palette = "Red-Green-Gold Diverging", trans = "reverse", labels = scientific) +
    guides(fill = guide_colorbar(reverse=T))

ggsave("Figuras/Descriptiva/mapa_febreros_abriles.png", mapa_desciptivo, width = 10, height = 8)
