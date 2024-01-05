
library(tidyverse)
library(data.table)
library(pracma)



# Plot predicciones -------------------------------------------------------
## Seleccionar resultados del mejor modelo ---------------------------------


carpeta.archivos <- "Datos/Resultados_modelos/Modelo_2/"
figura_comparacion_predicciones <- "Figuras/Modelo_2/Prediccion_m2"
archivo.comparaciones <- file.path(carpeta.archivos, "General", "metricas.csv")
comparaciones <- fread(archivo.comparaciones) 
mejor.modelo <- comparaciones[variable == 'R2'][value == max(value), as.character(modelo)]



## Leer predicciones del mejor modelo --------------------------------------

archivo.predicciones.R <- file.path(carpeta.archivos, mejor.modelo, "prediccion.csv")
archivo.predicciones.SR <- file.path(carpeta.archivos, mejor.modelo, "prediccion_sin_restricciones.csv")

lista.predicciones <- lapply(c(archivo.predicciones.R, archivo.predicciones.SR), function(x){
  df <- fread(x)
  df <- df[ds < as.Date("2020-11-28")]
  return(df)
})
names(lista.predicciones) <- c('R', 'SR')


datos.obs <- lista.predicciones[['R']][, .(ds, y)]

datos.valores <- cbind(lista.predicciones[['R']][, .(ds, NO2R = yhat)],
                       lista.predicciones[['SR']][, .(NO2SR = yhat)])


datos.valores <- datos.valores %>%
  melt(id.vars = "ds")

(plot.pred <- datos.valores %>%
  ggplot(aes(x = ds, y = value)) +
  geom_line(aes(col = variable)) +
  geom_point(data = datos.obs, aes(y = y, fill = "Observados")) +
  theme_bw() +
  scale_color_manual(name = "",
                     labels = c(
                                expression(paste(NO[2], "R")),
                                expression(paste(NO[2], "SR"))),
                     values = c( 
                                "NO2R" = "#D95F02",
                                "NO2SR" = "#1B9E77")) +
  labs(
    x = "Fecha",
    y = expression(paste("Columna de ", NO[2], " troposférico (", mu, "mol.", m^-2, ")")),
    fill = '') +
  theme(legend.position = "top") +
  geom_vline(xintercept = as.Date("2020-03-20"), linetype = "dashed", alpha = 0.8) +
  scale_x_date(date_breaks = "3 months", labels = function(x) format(x, "%d %b %Y")))

ggsave("Figuras/Modelo_2/Prediccion_m2.png", plot.pred, width = 10, height = 6)




# Area bajo la curva ------------------------------------------------------

## Calcular area -----------------------------------------------------------


datos.valores[, "area_value" := frollapply(value, 28, trapz, align = "right"), by = variable]

(plot.areas <- datos.valores %>%
    ggplot(aes(x = ds, y = area_value, col = variable)) +
    geom_line() +
    geom_vline(xintercept = as.Date("2020-03-20"), linetype = "dashed") +
    scale_color_manual(name = "",
                       labels = c(
                         expression(paste(NO[2], "R")),
                         expression(paste(NO[2], "SR"))),
                       values = c( 
                         "NO2R" = "#D95F02",
                         "NO2SR" = "#1B9E77")) +
    scale_x_date(date_breaks = "3 months", date_labels = "%d %b %Y") +
    theme_bw()+
    theme(legend.position = "top") +
    labs(x = "Fecha", y = expression(paste("Área debajo de la curva de la columna promedio de ", NO[2], " (", mu, "mol.día.", m^-2, ")")), fill = "Predicción", col = "Predicción"))

ggsave("Figuras/Modelo_2/Mediamovil_area_bajo_curva_predicciones.png", plot.areas, width = 10, height = 6)



## Analisis ----------------------------------------------------------------
datos.valores[, c("periodo", "mes_anio") := .(
  fifelse(ds < as.Date("2020-03-20"), "Previo a restricciones", "Durante las restricciones"),
  format(datos.valores$ds, format = "%b %Y"))]
datos.valores <- datos.valores %>%
  rbind(datos.valores[between(ds, as.Date("2020-03-20"), as.Date("2020-05-04"))] %>%
          mutate(periodo = "Periodo Represa et al."))


#por periodo
datos.proporciones.periodo <- datos.valores[, .(area_value = trapz(value)), by = .(variable, periodo)]
datos.proporciones.periodo <- datos.proporciones.periodo[, .(prop = area_value[1]/area_value[2]), by = periodo]
datos.proporciones.periodo <- datos.proporciones.periodo[, .(periodo, prop, comparacion = "Según restricciones")]
print(paste("Proporción para el período utilizado por Represa et al: ", datos.proporciones.periodo[periodo == "Periodo Represa et al.", as.numeric(prop)]))
datos.proporciones.periodo <- datos.proporciones.periodo[periodo == 'Durante las restricciones']
datos.proporciones.periodo[, periodo := "Q promedio durante las restricciones"]
datos.proporciones.periodo[, periodo := factor(periodo, levels = unique(periodo))]


#por mes:
datos.proporciones.mes <- datos.valores [ds >= as.Date('2020-03-01'), .(area_value = trapz(value)), by = .(variable, mes_anio)]
datos.proporciones.mes <- datos.proporciones.mes[, .(prop = area_value[1]/area_value[2]), by = mes_anio]
datos.proporciones.mes <- datos.proporciones.mes[, .(periodo = mes_anio, prop, comparacion = "Mensual")]
datos.proporciones.mes[, periodo := factor(periodo, levels = unique(periodo))]

archivo.mensual <- file.path(carpeta.archivos, 'General', 'Q_mesual.csv')

fwrite(rbind(datos.proporciones.mes, datos.proporciones.periodo), archivo.mensual)

(plot.proporciones <- datos.proporciones.mes %>%
    ggplot(aes(x = periodo, y = prop)) +
    geom_col(fill = "gray70") +
    geom_hline(yintercept = 1, linetype = "dashed", alpha = 0.75) +
    geom_hline(data = datos.proporciones.periodo, aes(yintercept = prop, col = periodo)) +
    scale_color_manual(
      values = c( 
        "Q promedio durante las restricciones" = "#D95F02")) + ##1B9E77"
    theme_bw() +
    theme(legend.position = "top", axis.text.x = element_text(angle = 20, vjust = 1, hjust = 1), plot.margin = unit(c(0,0,0,1), "cm")) +
    labs(x = "Intervalo de tiempo", y = expression(Q == frac(Área(NO[2]~R), Área(NO[2]~SR))), col = ""))

ggsave("Figuras/Modelo_2/Proporciones_area_bajo_curva_predicciones.png", plot.proporciones, width = 10, height = 6)



# Observados vs predichos -------------------------------------------------
datos.obs.pred <- merge(datos.valores, datos.obs, by = 'ds')

plot.validacion <- datos.obs.pred[!is.na(y) & variable == 'NO2R'] %>%
  ggplot(aes(x = y, y = value)) +
  geom_point(alpha = 0.5, size = 0.75)+
  geom_abline(slope = 1, intercept = c(0, 0), linetype = "dashed") +
  theme_bw() +
  scale_x_continuous(labels = scientific) +
  labs(x = expression(paste("Observados (", mu, "mol.", m^-2, ")")), y = expression(paste("Predichos (", mu, "mol.", m^-2, ")")))

ggsave("Figuras/Modelo_2/Validacion_m2.png", plot.validacion, width = 10, height = 6)

