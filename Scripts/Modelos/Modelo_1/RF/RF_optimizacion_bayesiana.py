for name in dir():
    if not name.startswith('_'):
        del globals()[name]

from cmath import isnan, nan
import math
from gettext import npgettext
import os

import pandas as pd
from sklearn.model_selection import TimeSeriesSplit
import numpy as np 
from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import cross_val_score
from random import randint, seed
from datetime import datetime
import datetime as dt
from bayes_opt import BayesianOptimization
from bayes_opt.logger import JSONLogger
from bayes_opt.event import Events
#import scipy #version 1.7.3 despues de la 1.8 rompe la bayesian optimization
#from Scripts.Modelos.Modelo_1.RF.funciones import estimador, black_box_function

seed(10)
datos = pd.read_csv('Datos/Insumos_python/insumo_modelo_1.csv')


#Solo previo cuarentena:
datos = datos[datos['ds'] < '2020-03-20']

## CV:
n_datos = datos.shape[0]
un_mes = 24*30
n_splits = n_datos // un_mes - 1
cv = TimeSeriesSplit(n_splits = n_splits, test_size = un_mes)
##

## Optimizacion bayesiana:
x_train = datos.drop(['ds', 'y'], axis = 1)
y_train = datos['y']

# Parametros:
init_points = 900
n_iter = 100

pbounds = {
    'criterion': (0, 2.9999),
    "n_estimators": (100, 5000),
    "min_samples_split": (0.0001, 0.9999),
    'max_features': (math.sqrt(x_train.shape[1])/x_train.shape[1], 1.0)
    }


carpeta_logs = os.path.join('Modelos', 'logs', 'RF')
os.makedirs(carpeta_logs, exist_ok=True)

archivo_log = os.path.join(carpeta_logs, 'Optimizacion_bayesiana_logs.json')
logger = JSONLogger(path=archivo_log)

##### Copiado de funciones:

def estimador(parametros):
        parametros_it = parametros.copy()
        parametros_it['n_estimators'] = int(parametros_it['n_estimators'])
        dict_criterion = {
            0: 'squared_error',
            1: 'friedman_mse',
            2: 'poisson'    
        }
        parametros_it['criterion'] = dict_criterion[int(parametros_it['criterion'])]
        return RandomForestRegressor(**parametros_it, n_jobs = -1)

#Black box function para la optimizacion bayesiana del modelo RF
#Usa variables definidas por fuera, no le pude encontrar otra vuelta
def black_box_function(criterion, n_estimators, min_samples_split, max_features):
    parametros_opt = locals()
    semillas = [randint(0, 1000000) for _ in range(5)]
    scores = np.array([])
    for semilla in semillas:
        parametros_opt['random_state'] = semilla
        clf = estimador(parametros = parametros_opt)
        score_it = cross_val_score(estimator = clf, X = x_train, y = y_train, cv=cv, scoring='neg_root_mean_squared_error')
        scores = np.append(scores, score_it.mean())
    return scores.mean()

####




optimizer = BayesianOptimization(f = black_box_function,
                                pbounds = pbounds, 
                                verbose = 2,
                                random_state = 10)

optimizer.subscribe(Events.OPTIMIZATION_STEP, logger)

optimizer.maximize(init_points = init_points, n_iter = n_iter)

print("Best result: {}; f(x) = {}.".format(optimizer.max["params"], optimizer.max["target"]))