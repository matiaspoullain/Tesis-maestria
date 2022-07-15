# Crear Region de interés:

library(sf)
library(dplyr)

rectangulo.caba <- data.frame(lon = c(-58.56, -58.33), lat = c(-34.52, -34.73))



poly <- rectangulo.caba %>% 
  st_as_sf(coords = c("lon", "lat"), 
           crs = 4326) %>% 
  st_bbox() %>% 
  st_as_sfc()

st_write(poly, "Datos/Georreferenciados/bb_caba.geojson")
