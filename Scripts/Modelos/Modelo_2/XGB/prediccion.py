import os
import pandas as pd
import xgboost as xgb
import pickle
import json
import numpy as np
from datetime import timedelta
from sklearn.model_selection import train_test_split



# --------------------------------- Archivos --------------------------------- #
archivo_input = 'Datos/Insumo_modelos/Modelo_2/XGB.csv'
archivo_input_sin_restricciones = 'Datos/Resultados_modelos/Modelo_1/prediccion.csv'
carpeta_modelo = os.path.join('Modelos', 'Modelo_2', 'XGB')
archivo_modelo =  os.path.join(carpeta_modelo, 'modelo.pkl')
os.makedirs(carpeta_modelo, exist_ok=True)

carpeta_output = os.path.join('Datos', 'Resultados_modelos', 'Modelo_2', 'XGB')
archivo_predicciones = os.path.join(carpeta_output, 'prediccion.csv')
archivo_predicciones_sin_restricciones = os.path.join(carpeta_output, 'prediccion_sin_restricciones.csv')
archivo_predicciones_heldout = os.path.join(carpeta_output, 'prediccion_heldout.csv')
archivo_coeficientes = os.path.join(carpeta_output, 'feature_importance.csv')
os.makedirs(carpeta_output, exist_ok=True)

# -------------------------------- Parametros -------------------------------- #
json_parametros_optimizados = os.path.join(carpeta_modelo, 'parametros_optimizados.json')
with open(json_parametros_optimizados, 'r') as json_file:
    parametros = json.load(json_file)
if 'early_stopping_rounds' not in parametros:
    parametros['early_stopping_rounds']=100
semanas_heldout = 3

# ---------------------------------------------------------------------------- #
#                               Lectura de datos                               #
# ---------------------------------------------------------------------------- #
datos = pd.read_csv('Datos/Insumo_modelos/Modelo_2/XGB.csv')
datos['ds'] = pd.to_datetime(datos['ds']).dt.tz_localize(None)
corte_heldout = datos['ds'].max() - timedelta(weeks=semanas_heldout)
datos['heldout'] = datos['ds'] > corte_heldout

# ---------------------------------- Dummies --------------------------------- #
datos = pd.get_dummies(datos, prefix=['holiday_dummy'], columns=['holiday'], dtype=float)
heldout = datos[datos['heldout']].drop('heldout', axis = 1).reset_index(drop = True)
X = datos[(~datos['heldout']) & (~datos['y'].isnull())].drop(['heldout', 'y', 'ds'], axis = 1).reset_index(drop = True)
y = datos[(~datos['heldout']) & (~datos['y'].isnull())]['y'].reset_index(drop = True)
datos = datos.drop('heldout', axis = 1)

X_train, X_test, y_train, y_test = train_test_split(X, y, random_state=94)


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
model = xgb.XGBRegressor(**parametros)

# Fittear modelo y predecir
model.fit(X_train, y_train, eval_set=[(X_test, y_test)])
predichos = model.predict(datos.drop(['y', 'ds'], axis = 1))

# Guardar modelo
with open(archivo_modelo, 'wb') as archivo:
    pickle.dump(model, archivo)

#Guardar feature importance
feature_importance_df = pd.DataFrame.from_dict(model.get_booster().get_score(importance_type='gain'), orient='index').reset_index().rename({'index': 'Feature', 0: 'Importance'}, axis = 1)
feature_importance_df.to_csv(archivo_coeficientes, index = False)

# Formatear predichos para guardar:
df_predichos = datos[['ds', 'y']]
df_predichos.loc[:, 'yhat'] = predichos
for y in ['y', 'yhat']:
    df_predichos.loc[:, y] = 10**df_predichos.loc[:, y]
df_predichos.to_csv(archivo_predicciones, index = False)

#Prediccion sobre heldout
df_predichos_heldout = heldout[['ds', 'y']]
df_predichos_heldout.loc[:, 'yhat'] = model.predict(heldout.drop(['y', 'ds'], axis = 1))
for y in ['y', 'yhat']:
    df_predichos_heldout.loc[:, y] = 10**df_predichos_heldout.loc[:, y]
df_predichos_heldout.to_csv(archivo_predicciones_heldout, index = False)

#Predicciones para sin restricciones:
df_predichos_sin_restricciones = datos_sin_restricciones[['ds', 'y']]
df_predichos_sin_restricciones.loc[:, 'yhat'] = model.predict(datos_sin_restricciones.drop(['y', 'ds'], axis = 1))
for y in ['y', 'yhat']:
    df_predichos_sin_restricciones.loc[:, y] = 10**df_predichos_sin_restricciones.loc[:, y]
df_predichos_sin_restricciones.to_csv(archivo_predicciones_sin_restricciones, index = False)