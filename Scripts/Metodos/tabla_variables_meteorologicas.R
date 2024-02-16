#Tabla variables meteorologicas
library(xtable)

columnas <- c("Nombre", "Abreviación", "Resolución temporal", "Origen")

nombre <- c("Temperatura Horaria (°C)",
            "Tiempo presente",
            "Temperatura Media Diaria (°C)",
            "Ocurrencia de Precipitaciones horaria",
            "Ocurrencia de Precipitaciones diaria",
            "Dirección Cardinal del Viento",
            "Intensidad del Viento horario (Km/h)",
            "Intensidad del Viento diaria (Km/h)")

abreviacion <- c("T\\textsubscript{h}",
                 "TP",
                 "T\\textsubscript{d}",
                 "OP\\textsubscript{h}",
                 "OP\\textsubscript{d}",
                 "", 
                 "IV\\textsubscript{h}",
                 "IV\\textsubscript{d}")

resolucion <- c("Horaria",
                "Horaria",
                "Diaria",
                "Horaria",
                "Diaria",
                "Horaria",
                "Horaria",
                "Diaria")

origen <- c("SMN",
            "SMN",
            "Calculada",
            "Calculada",
            "Calculada",
            "SMN",
            "SMN",
            "Calculada")


df <- data.frame(nombre, abreviacion, resolucion, origen)

names(df) <- columnas

print(xtable(df, type = "latex"), file = "Tablas/Metodos/variables_meteorologicas.tex", include.rownames=FALSE, , sanitize.colnames.function = identity, sanitize.text.function = identity)
