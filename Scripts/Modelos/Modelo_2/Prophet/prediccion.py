import os
import pandas as pd
from prophet import Prophet
from prophet.utilities import regressor_coefficients
import pickle
import json
import numpy as np
from datetime import timedelta



# --------------------------------- Archivos --------------------------------- #
archivo_input = 'Datos/Insumo_modelos/Modelo_2/prophet.csv'
archivo_input_sin_restricciones = 'Datos/Resultados_modelos/Modelo_1/prediccion.csv'
archivo_modelo = 'Modelos/Modelo_2/modelo.pkl'

carpeta_output = os.path.join('Datos', 'Resultados_modelos', 'Modelo_2', 'Prophet')
archivo_predicciones = os.path.join(carpeta_output, 'prediccion.csv')
archivo_predicciones_sin_restricciones = os.path.join(carpeta_output, 'prediccion_sin_restricciones.csv')
archivo_predicciones_heldout = os.path.join(carpeta_output, 'prediccion_heldout.csv')
archivo_coeficientes = os.path.join(carpeta_output, 'coeficientes_regresoras.csv')
os.makedirs(carpeta_output, exist_ok=True)

carpeta_figuras = os.path.join('Figuras', 'Modelo_2', 'Prophet')
archivo_plot_componentes = os.path.join(carpeta_figuras, 'plot_componentes.png')
os.makedirs(carpeta_figuras, exist_ok=True)

# -------------------------------- Parametros -------------------------------- #
df_optimizacion_directory = os.path.join('Modelos', 'Modelo_2')
json_parametros_optimizados = os.path.join(df_optimizacion_directory, 'parametros_optimizados.json')
with open(json_parametros_optimizados, 'r') as json_file:
    parametros = json.load(json_file)
semanas_heldout = 3

# ---------------------------------------------------------------------------- #
#                               Lectura de datos                               #
# ---------------------------------------------------------------------------- #
datos = pd.read_csv(archivo_input)
datos['ds'] = pd.to_datetime(datos['ds']).dt.tz_localize(None)

corte_heldout = datos['ds'].max() - timedelta(weeks=3)
heldout = datos[datos['ds'] > corte_heldout].reset_index(drop = True)
datos = datos[datos['ds'] <= corte_heldout].reset_index(drop = True) 

X = datos[~datos['y'].isnull()]
feriados = pd.read_csv('Datos/Insumos_prophet/feriados.csv')

#Datos predichos por Modelo 1:
datos_sin_restricciones = datos.copy()
prediccion_m1 = pd.read_csv(archivo_input_sin_restricciones)
prediccion_m1['ds'] = pd.to_datetime(prediccion_m1['ds']).dt.tz_localize(None)
prediccion_m1 = prediccion_m1[['ds', 'yhat']]
prediccion_m1['yhat'] = np.log10(prediccion_m1['yhat'])
datos_sin_restricciones = datos_sin_restricciones.merge(prediccion_m1, on = 'ds')
datos_sin_restricciones.loc[datos_sin_restricciones['ds'] >= '2020-03-20', 'cantidad_pasos'] = datos_sin_restricciones.loc[datos_sin_restricciones['ds'] >= '2020-03-20', 'yhat']
datos_sin_restricciones = datos_sin_restricciones.drop('yhat', axis = 1)

# ---------------------------------------------------------------------------- #
#                                 Entrenamiento                                #
# ---------------------------------------------------------------------------- #
model = Prophet(
    growth = "flat",
    seasonality_mode = "additive",
    changepoint_range=0.8,
    yearly_seasonality = True,
    weekly_seasonality = True,
    daily_seasonality = False,
    mcmc_samples = 1000,
    holidays=feriados,
    **parametros
)

model.add_regressor('cantidad_pasos', mode='additive')
model.add_regressor('log_temperatura', mode='additive')
model.add_regressor('log_intensidad_viento_km_h', mode='additive')

# Fittear modelo y predecir
model.fit(X, max_treedepth = 30, show_console=True)
predichos = model.predict(datos)

# Guardar modelo
with open(archivo_modelo, 'wb') as archivo:
    pickle.dump(model, archivo)

#Guardar analisis de componentes
model.plot_components(predichos).savefig(archivo_plot_componentes)
coeficientes_regresoras = regressor_coefficients(model)
coeficientes_regresoras.to_csv(archivo_coeficientes, index = False)

# Formatear predichos para guardar:
ys = ['y', 'yhat', 'yhat_lower', 'yhat_upper']
predichos['y'] = datos['y']
predichos = predichos[['ds'] + ys]
for y in ys:
    predichos.loc[:, y] = 10**predichos.loc[:, y]
predichos.to_csv(archivo_predicciones, index = False)

#Prediccion sobre heldout
predichos_heldout = model.predict(heldout)
predichos_heldout['y'] = heldout['y']
predichos_heldout = predichos_heldout[['ds'] + ys]
for y in ys:
    predichos_heldout.loc[:, y] = 10**predichos_heldout.loc[:, y]
predichos_heldout.to_csv(archivo_predicciones_heldout, index = False)

#Predicciones para sin restricciones:
predichos_sin_restricciones = model.predict(datos_sin_restricciones)
predichos_sin_restricciones['y'] = datos_sin_restricciones['y']
predichos_sin_restricciones = predichos_sin_restricciones[['ds'] + ys]
for y in ys:
    predichos_sin_restricciones.loc[:, y] = 10**predichos_sin_restricciones.loc[:, y]
predichos_sin_restricciones.to_csv(archivo_predicciones_sin_restricciones, index = False)

