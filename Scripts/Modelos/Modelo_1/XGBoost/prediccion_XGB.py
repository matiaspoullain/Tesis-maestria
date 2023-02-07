
## Predicciones:
import os
import pandas as pd
import numpy as np
from tqdm import tqdm
from Scripts.Modelos.Modelo_1.funciones import get_mejores_params
from Scripts.Modelos.Modelo_1.RF.funciones import estimador

fecha_inicio = '2020-03-10'

parametros = get_mejores_params("RF")
parametros['max_depth'] = None
parametros['min_samples_split'] = 2
parametros['criterion'] = 'squared_error'
datos = pd.read_csv(os.path.join('Datos', 'Insumos_python', 'insumo_modelo_1.csv'))

#Entreno solo con antes de la cuarentena
x_train = datos[datos['ds'] < fecha_inicio].drop(['ds', 'y', 'y_diff_mediana'], axis = 1)
y_train = datos[datos['ds'] < fecha_inicio]['y']


clf = estimador(parametros)
clf.fit(x_train, y_train)



"""
predicho = clf.predict(x_test)
datos['predicho'] = predicho

datos.to_csv('Datos/Resultados_prophet/Modelo_1/predicho_modelo_1_RF.csv', index = False)
"""

#Importancia de las variables:
importances = clf.feature_importances_
std = np.std([tree.feature_importances_ for tree in clf.estimators_], axis=0)

forest_importances = pd.Series(importances, index=x_train.columns)
forest_importances = pd.DataFrame(forest_importances).reset_index().rename({'index': 'variables', 0: 'importancia'}, axis = 1)
forest_importances.to_csv(os.path.join('Datos', 'Resultados_modelos', 'Modelo_1', 'importancia_RF.csv'), index = False)


#Nuevas predicciones
#Como los valores predichos dependen de los valores anteriores observados, es necesario hacer predicciones y usarlas para predecir la hora siguiente

#Funcion para crear los nuevos lags en cada iteracion
def lagguear(df):
    df_lag = pd.DataFrame()
    for i in [1, 8, 12, 24, 24*7]:#range(24*7, 0, -1):
        df_lag['y_diff_mediana_lag_' + str(i)] = df.y.shift(i)
    df = pd.concat([df, df_lag], axis=1)
    df.dropna(inplace=True)
    return df

datos_lags = datos[datos.columns.drop(list(datos.filter(regex='_lag_')))]
predichos = clf.predict(x_train)
fechas_test = datos.ds[datos.ds >= fecha_inicio].values
for fecha_it in tqdm(fechas_test):
    datos_lags_it = lagguear(datos_lags)
    x_test_it = datos_lags_it[datos_lags_it['ds'] == fecha_it].drop(['ds', 'y', 'y_diff_mediana'], axis = 1)
    predicho_it = clf.predict(x_test_it)
    datos_lags.at[np.where(datos_lags.ds == fecha_it)[0][0], 'y'] = predicho_it[0]
    predichos = np.append(predichos, predicho_it[0])

datos['predicho'] = predichos
datos.to_csv('Datos/Resultados_modelos/Modelo_1/predicho_modelo_1_RF.csv', index = False)