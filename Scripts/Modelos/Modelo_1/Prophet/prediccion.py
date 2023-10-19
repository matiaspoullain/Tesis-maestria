import os
import pandas as pd
from prophet import Prophet
from prophet.utilities import regressor_coefficients
import pickle
import json


# --------------------------------- Archivos --------------------------------- #
archivo_input = 'Datos/Insumo_modelos/Modelo_1.csv'
archivo_modelo = 'Modelos/Modelo_1/modelo.pkl'

carpeta_output = os.path.join('Datos', 'Resultados_modelos', 'Modelo_1')
archivo_predicciones = os.path.join(carpeta_output, 'prediccion.csv')
archivo_coeficientes = os.path.join(carpeta_output, 'coeficientes_regresoras.csv')
os.makedirs(carpeta_output, exist_ok=True)

capreta_figuras = os.path.join('Figuras', 'Modelo_1')
archivo_plot_componentes = os.path.join(capreta_figuras, 'plot_componentes.png')

# -------------------------------- Parametros -------------------------------- #
df_optimizacion_directory = os.path.join('Modelos', 'Modelo_1')
json_parametros_optimizados = os.path.join(df_optimizacion_directory, 'parametros_optimizados.json')
with open(json_parametros_optimizados, 'r') as json_file:
    parametros = json.load(json_file)

# ---------------------------------------------------------------------------- #
#                               Lectura de datos                               #
# ---------------------------------------------------------------------------- #
datos = pd.read_csv(archivo_input)
datos['ds'] = pd.to_datetime(datos['ds']).dt.tz_localize(None)
X = datos[datos['ds']<'2020-03-20']
feriados = pd.read_csv('Datos/Insumos_prophet/feriados.csv')


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

model.add_seasonality(
    name='diaria_semana',
    period=1,
    fourier_order=5,
    mode='additive',
    condition_name='es_semana'
)

model.add_seasonality(
    name='diaria_finde',
    period=1,
    fourier_order=5,
    mode='additive',
    condition_name='es_finde'
)

model.add_regressor('pp', mode='additive')
model.add_regressor('temperatura', mode='additive')

# Fittear modelo y predecir
model.fit(X, max_treedepth = 30)
predichos = model.predict(datos)

# Guardar modelo
with open(archivo_modelo, 'wb') as archivo:
    pickle.dump(model, archivo)

#Guardar analisis de componentes
model.plot_components(predichos).savefig(archivo_plot_componentes)
coeficientes_regresoras = regressor_coefficients(model)
coeficientes_regresoras.to_csv(archivo_coeficientes, index = False)

# Formatear predichos para guardar:
ys = ['yhat', 'yhat_lower', 'yhat_upper']
predichos = predichos[['ds'] + ys]
for y in ys:
    predichos.loc[:, y] = 10**predichos.loc[:, y]
predichos.to_csv(archivo_predicciones, index = False)
