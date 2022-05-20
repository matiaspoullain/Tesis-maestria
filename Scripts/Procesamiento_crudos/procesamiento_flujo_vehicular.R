rm(list = ls())
gc()

library(data.table)
library(stringr)

setDTthreads(threads = 0, restore_after_fork = NULL)

#Genera archivo de conteo vehicular por hora

datos <- data.table()

archivos <- paste0('Datos/Crudos/flujo-vehicular-', 2019:2020, '.csv')

for(i in archivos){
  datos.it <- fread(i, encoding = "UTF-8")
  datos.it[, fecha_hora := paste(as.character(fecha), 
                                 paste0(
                                   str_pad(hora_inicio, 2, pad = "0"),
                                   ":00:00"))]
  datos.it <- datos.it[, .(cantidad_pasos = round(sum(cantidad_pasos, na.rm = TRUE))), by = fecha_hora]
  datos <- rbind(datos, datos.it)
}

datos[, fecha_hora := as.POSIXct(fecha_hora,format="%Y-%m-%d %H:%M:%S", tz = "GMT")]
      

fwrite(datos, "Datos/Procesados/conteo_vehicular.csv")
