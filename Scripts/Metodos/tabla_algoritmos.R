#Tabla variables meteorologicas
library(xtable)

columnas <- c("Nombre", "Abreviación", "Hyperparámetros Optimizados e intervalos/opciones de búsqueda")

nombre <- c("K-Nearest Neighbors",
            "Prophet",
            "Ridge",
            "Support Vector Machine",
            "Extreme Gradient Boosting")

abreviacion <- c("KNN",
                 "Prophet",
                 "Ridge",
                 "SVM",
                 "XGB")

parametros <- c("n\\_neighbors [1; 50]\\newline
                weights [uniform; distance]\\newline
                p [1.0; 2.0]",
                
                "changepoint\\_prior\\_scale [0.001; 5.0]\\newline
                seasonality\\_prior\\_scale [0.01; 10.0]\\newline
                holidays\\_prior\\_scale [0.01; 10.0]",
                
                "alpha [1e-10; 500.0]",
                
                "C [1e-3; 100.0]\\newline
                epsilon [0.001; 0.1]\\newline
                kernel [linear; poly; rbf; sigmoid]\\newline
                gamma [scale; auto] si kernel \\neq 'linear'\\newline
                degree [2; 4] si kernel = 'poly'",
                
                "subsample [0.2; 1.0]\\newline
                colsample\\_bytree [0.2; 1.0]\\newline
                max\\_depth [3; 101]\\newline
                min\\_child\\_weight [0; 10]\\newline
                eta [1e-4; 1.0]")


df <- data.frame(nombre, abreviacion, parametros)

names(df) <- columnas

print(xtable(df, type = "latex"), file = "Tablas/Metodos/algoritmos.tex", include.rownames=FALSE, , sanitize.colnames.function = identity, sanitize.text.function = identity)
