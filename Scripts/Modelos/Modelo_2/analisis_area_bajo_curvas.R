# Resultados modelo 2:
library(tidyverse)
library(data.table)
library(pracma)

datos <- fread("Datos/Resultados_prophet/Modelo_2/resultados_modelo_2_unidades_reales.csv")

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


#Proporciones:

datos.juntos[, ]

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

