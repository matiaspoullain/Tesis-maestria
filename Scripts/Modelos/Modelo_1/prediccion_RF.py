import os
os.chdir("D:\OneDrive\OneDrive - UCA\Escritorio\Proyectos\Tesis-maestria")

## Predicciones:
import pandas as pd
import numpy as np
import json
from sklearn.ensemble import RandomForestRegressor
from tqdm import tqdm


def estimador(parametros):
        parametros_it = parametros.copy()

        parametros_it['n_estimators'] = int(parametros_it['n_estimators'])

        dict_criterion = {
        0: 'squared_error',
        1: 'absolute_error',
        2: 'poisson'
        }
        parametros_it['criterion'] = dict_criterion[int(parametros_it['criterion'])]

        parametros_it['max_depth'] = int(parametros_it['max_depth'])
        return RandomForestRegressor(**parametros_it, n_jobs = -1)


def get_mejores_params(algoritmo, archivo_log = None):
    if archivo_log is None:
        archivo_log = os.path.join('Modelos', 'logs', algoritmo, "Optimizacion_bayesiana_logs.json")
    json_opt_out = []
    for line in open(archivo_log, 'r'):
        json_opt_out.append(json.loads(line))
    json_opt_out = pd.DataFrame.from_records(json_opt_out)

    parametros = json_opt_out[json_opt_out['target'] == max(json_opt_out['target'])]['params'].values[0]

    return parametros

parametros = get_mejores_params("RF")


datos = pd.read_csv('Datos/Insumos_python/insumo_modelo_1.csv')

#Entreno solo con antes de la cuarentena
x_train = datos[datos['ds'] < '2020-03-20'].drop(['ds', 'y'], axis = 1)
y_train = datos[datos['ds'] < '2020-03-20']['y']
x_test = datos.drop(['ds', 'y'], axis = 1)

clf = estimador(parametros)
clf.fit(x_train, y_train)
predicho = clf.predict(x_test)
datos['predicho'] = predicho

datos.to_csv('Datos/Resultados_prophet/Modelo_1/predicho_modelo_1_RF.csv', index = False)


#Importancia:
importances = clf.feature_importances_
std = np.std([tree.feature_importances_ for tree in clf.estimators_], axis=0)

forest_importances = pd.Series(importances, index=x_train.columns)

import matplotlib.pyplot as plt

fig, ax = plt.subplots()
forest_importances.plot.bar(yerr=std, ax=ax)
ax.set_title("Feature importances using MDI")
ax.set_ylabel("Mean decrease in impurity")
fig.tight_layout()



#Predicciones con lags:
def lagguear(df):
    df_lag = pd.DataFrame()
    for i in range(24*7, 0, -1):
        df_lag['y_lag_' + str(i)] = df.y.shift(i)
    df = pd.concat([df, df_lag], axis=1)
    df.dropna(inplace=True)
    return df

datos_lags = datos[datos.columns.drop(list(datos.filter(regex='_lag_')))]
predichos = clf.predict(x_train)
fechas_test = datos[datos['ds'] >= '2020-03-20']['ds']
for fecha_it in tqdm(fechas_test):
    datos_lags_it = lagguear(datos_lags)
    x_test_it = datos_lags[datos_lags_it['ds'] == fecha_it].drop(['ds', 'y'], axis = 1)
    predicho_it = clf.predict(x_test_it)
    datos_lags.loc[datos_lags['ds'] == fecha_it, 'y'] = predicho_it
    predichos = predichos.append(predicho_it)

