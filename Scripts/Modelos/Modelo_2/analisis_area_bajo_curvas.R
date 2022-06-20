# Resultados modelo 2:
library(tidyverse)
library(data.table)
library(pracma)

datos <- fread("Datos/Resultados_prophet/Modelo_2/resultados_modelo_2_unidades_reales.csv")

datos <- datos[ds < as.Date("2020-11-29")]

#Media movil:
variables <- names(datos)[grepl("prediccion", names(datos))]

variables.nuevas <- paste0("area_", variables)

datos[, (variables.nuevas) := frollapply(.SD, 28, trapz, align = "right"), .SDcols = variables]

centrales <- c("ds", variables.nuevas[!grepl("min|max", variables.nuevas)])

datos.centrales <- datos[, ..centrales] %>%
  melt(id.vars = "ds", measure = patterns("^area_"), value.name = "valor_central")

datos.centrales[, variable := fifelse(variable == "area_prediccion_train", "NO2R", "NO2SR")]

incertidumbre <- c("ds", variables.nuevas[grepl("min|max", variables.nuevas)])

datos.incertidumbre <- datos[, ..incertidumbre] %>%
  melt(measure = patterns("^area_"), value.name = "valor_incertidumbre")

datos.incertidumbre[, c("variable", "rango") := .(fifelse(grepl("train", variable), "NO2R", "NO2SR"),
                                                  fifelse(grepl("max", variable), "incertidumbre_max", "incertidumbre_min"))]

datos.incertidumbre <- datos.incertidumbre %>%
  dcast(ds + variable ~ rango, value.var = "valor_incertidumbre")

datos.juntos <- merge(datos.centrales, datos.incertidumbre, by = c("ds", "variable"))


(plot.areas <- datos.juntos %>%
  ggplot(aes(x = ds, y = valor_central, ymax = incertidumbre_max, ymin = incertidumbre_min, col = variable, fill = variable)) +
  geom_ribbon(alpha = 0.3, col = NA) +
  geom_line() +
  geom_vline(xintercept = as.Date("2020-03-20"), linetype = "dashed") +
  scale_color_brewer(palette = "Dark2") +
  scale_fill_brewer(palette = "Dark2") +
  theme_bw()+
    theme(legend.position = "top") +
  labs(x = "Fecha", y = expression(paste("Área debajo de la curva de la concentración promedio de ", NO[2], " (", mu, "mol.día.", m^-2, ")")), fill = "Predicción", col = "Predicción"))

ggsave("Figuras/Modelo_2/Mediamovil_area_bajo_curva_predicciones.png", plot.areas, width = 10, height = 6)


#Proporciones:

datos[, c("periodo", "mes_anio") := .(fifelse(ds < as.Date("2020-03-20"), "Previo a restricciones", "Durante las restricciones"),
                                      format(datos$ds, format = "%b %Y"))]

#por periodo
datos.proporciones.periodo <- datos[, lapply(.SD, trapz), .SDcols = variables, by = periodo]
datos.proporciones.periodo[, c("prop", "prop_max", "prop_min") := .(prediccion_train/prediccion_test,
                                                            prediccion_train_max/prediccion_test_max,
                                                            prediccion_train_min/prediccion_test_min)]
datos.proporciones.periodo <- datos.proporciones.periodo[, .(periodo, prop, prop_max, prop_min, comparacion = "Según restricciones")]

#por mes:
datos.proporciones.mes <- datos[, lapply(.SD, trapz), .SDcols = variables, by = mes_anio]
datos.proporciones.mes[, c("prop", "prop_max", "prop_min") := .(prediccion_train/prediccion_test,
                                                            prediccion_train_max/prediccion_test_max,
                                                            prediccion_train_min/prediccion_test_min)]
datos.proporciones.mes <- datos.proporciones.mes[, .(periodo = mes_anio, prop, prop_max, prop_min, comparacion = "Mensual")]

datos.proporciones <- rbind(datos.proporciones.periodo, datos.proporciones.mes)

datos.proporciones[, periodo := factor(periodo, levels = unique(periodo))]

(plot.proporciones <- datos.proporciones %>%
  ggplot(aes(x = periodo, y = prop, ymin = prop_min, ymax = prop_max, fill = comparacion)) +
  geom_col() +
  #geom_errorbar() +
    geom_hline(yintercept = 1, linetype = "dashed", alpha = 0.75) +
  scale_color_brewer(palette = "Dark2") +
  scale_fill_brewer(palette = "Dark2") +
  theme_bw() +
  theme(legend.position = "top", axis.text.x = element_text(angle = 20, vjust = 1, hjust = 1), plot.margin = unit(c(0,0,0,1), "cm")) +
  labs(x = "Intervalo de tiempo", y = expression(Q == frac(Área(NO[2]~R), Área(NO[2]~SR))), fill = "Tipo de período"))

ggsave("Figuras/Modelo_2/Proporciones_area_bajo_curva_predicciones.png", plot.proporciones, width = 10, height = 6)

datos.proporciones[3:16, prop] %>%
  range

datos.proporciones[17:dim(datos.proporciones)[1], prop] %>%
  range

datos.proporciones %>%
  filter(grepl("2020", periodo)) %>%
  arrange(desc(prop))
