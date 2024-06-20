#Mapas de concentraciones mensuales:

library(tidyverse)
library(sf)
library(raster)
library(data.table)
library(ggspatial)
library(ggthemes)
library(lemon)
library(scales)

dir_salida <- "Figuras/Descriptiva/Mapas_mensuales"

archivos_tif <- list.files('Datos/Georreferenciados/NO2_tropomi_mensual/', full.names = TRUE)
archivos_tif <- archivos_tif[grepl('*.tif', archivos_tif) & !grepl('.aux', archivos_tif)]

dir.create(dir_salida, showWarnings = FALSE)

provincias <- st_read("Datos/Georreferenciados/Departamentos/pxdptodatosok.shp")

caba_buffer <- st_read("Datos/Georreferenciados/bb_caba_buffer.geojson", crs = 'EPSG:4326')

mask <- st_read("Datos/Georreferenciados/mask/mask.geojson", crs = 4326)

buffer_recorte <- 0.03

for(i in archivos_tif){
  cat("\r", which(i == archivos_tif), "de", length(archivos_tif))
  r <- raster::raster(i)
  names(r) <- "columna"
  r <- as.data.frame(r, xy = TRUE)
  setDT(r)
  fecha <- substr(basename(i), start = 1, stop = 10)
  r[, fecha := fecha %>%
      as.Date() %>%
      format("%B %Y") %>%
      str_to_title()]
  
  mapa_mesual <- ggplot() +
    geom_raster(data = r, aes(x = x, y = y, fill = columna)) +
    geom_sf(data = provincias, fill = "transparent") +
    #geom_sf(data = mask, linetype = 'dashed', fill = 'transparent', linewidth = 1) +
    theme_void() +
    coord_sf(c(st_bbox(caba_buffer)$xmin + buffer_recorte, st_bbox(caba_buffer)$xmax - buffer_recorte),c(st_bbox(caba_buffer)$ymin + buffer_recorte, st_bbox(caba_buffer)$ymax - buffer_recorte)) +
    scale_fill_gradient2_tableau(palette = "Red-Green-Gold Diverging", trans = "reverse", labels = scientific) +
    theme(legend.position = "none")
  
  r[, seleccion := quantile(columna, 0.7) < columna]
  r[!r$seleccion, seleccion := NA]
  
  mapa_percentil <- ggplot() +
    geom_raster(data = r, aes(x = x, y = y, fill = seleccion), alpha = 0.7) +
    geom_sf(data = provincias, fill = "transparent") +
    #geom_sf(data = mask, linetype = 'dashed', fill = 'transparent', linewidth = 1) +
    theme_void() +
    coord_sf(c(st_bbox(caba_buffer)$xmin + buffer_recorte, st_bbox(caba_buffer)$xmax - buffer_recorte),c(st_bbox(caba_buffer)$ymin + buffer_recorte, st_bbox(caba_buffer)$ymax - buffer_recorte)) +
    scale_fill_gradient2_tableau(palette = "Red-Green-Gold Diverging", trans = "reverse", labels = scientific) +
    theme(legend.position = "none")
  
  archivo_mapa_mensual <- file.path(dir_salida, paste0(fecha, '.png'))
  archivo_mapa_percentil <- file.path(dir_salida, paste0(fecha, '_percentil.png'))
  
  ggsave(archivo_mapa, mapa_mesual, width = 5, height = 5)
  ggsave(archivo_mapa_percentil, mapa_percentil, width = 5, height = 5)

}

r[, seleccion := NA]
r[1, seleccion := 0]
mapa_mascara_simple = ggplot() +
  geom_raster(data = r, aes(x = x, y = y, fill = seleccion), alpha = 0.7)+
  geom_sf(data = provincias, fill = "transparent") +
  geom_sf(data = mask, fill = 'red', linewidth = 1, alpha = 0.5) +
  theme_void() +
  coord_sf(c(st_bbox(caba_buffer)$xmin + buffer_recorte, st_bbox(caba_buffer)$xmax - buffer_recorte),c(st_bbox(caba_buffer)$ymin + buffer_recorte, st_bbox(caba_buffer)$ymax - buffer_recorte)) +
  scale_fill_gradient2_tableau(palette = "Red-Green-Gold Diverging", trans = "reverse", labels = scientific) +
  theme(legend.position = "none")

archivo_mapa_mascara_simple <- file.path(dir_salida, 'mascara_simple.png')

ggsave(archivo_mapa_mascara_simple, mapa_mascara_simple, width = 5, height = 5)
