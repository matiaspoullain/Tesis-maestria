library(tidyverse)
library(data.table)
library(raster)
library(sf)
df <- fread("Datos/Georreferenciados/mask.csv")
dfr <- rasterFromXYZ(df, res=c(0.01, 0.01), crs = crs(raster("Datos/Georreferenciados/NO2_tropomi_mensual/2018-06-01 00_00_00.tif")))

df_sf <- st_as_sf(rasterToPolygons(dfr, dissolve = TRUE))
df_sf <- df_sf[df_sf$value == 1,]
st_write(df_sf$geometry[1], "Datos/Georreferenciados/mask.geojson", delete_dsn = TRUE)

