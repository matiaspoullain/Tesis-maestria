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
from random import randint, seed
from datetime import datetime
import datetime as dt
from bayes_opt import BayesianOptimization
from bayes_opt.logger import JSONLogger
from bayes_opt.event import Events
from bayes_opt.util import load_logs
import shutil
#import scipy #version 1.7.3 despues de la 1.8 rompe la bayesian optimization
from Scripts.Modelos.Modelo_1.XGBoost.funciones import estimador, black_box_function

seed(10)
datos = pd.read_csv('Datos/Insumos_python/insumo_modelo_1.csv')


#Solo previo cuarentena:
datos = datos[datos['ds'] < '2020-03-20']

## CV:
n_datos = datos.shape[0]
un_mes = 24*30
n_splits = n_datos // un_mes - 1
cv = TimeSeriesSplit(n_splits = n_splits, test_size = un_mes)

## Optimizacion bayesiana:
x_train = datos.drop(['ds', 'y'], axis = 1)
y_train = datos['y']

# Parametros:
init_points = 900
n_iter = 100

pbounds = {
    'eta': (0.0001, 1),
    'gamma': (0.0001, 100),
    'reg_lambda': (0.0001, 10),
    'tree_method': (0.0001, 2.9999)
    }


carpeta_logs = os.path.join('Modelos', 'logs', 'XGB')
os.makedirs(carpeta_logs, exist_ok=True)

archivo_log = os.path.join(carpeta_logs, 'Optimizacion_bayesiana_logs.json')

optimizer = BayesianOptimization(f = black_box_function(x_train, y_train, cv, archivo_log),
                                pbounds = pbounds, 
                                verbose = 2,
                                random_state = 10,
                                allow_duplicate_points=True)

if os.path.isfile(archivo_log):
    print('Archivo log pre-existente, se usa su informacion')
    load_logs(optimizer, logs=[archivo_log])
    shutil.copyfile(archivo_log, archivo_log.replace('.json', '_guardado.json'))
else:
    print('Archivo log no encontrado, se empieza de 0')
    
logger = JSONLogger(path=archivo_log)
optimizer.subscribe(Events.OPTIMIZATION_STEP, logger)

print(f'Comienza optimizacion bayesiana de {init_points} iteraciones de exploracion y {n_iter} de mejoramiento')
print(f'Los logs son guardados en {archivo_log}')

optimizer.maximize(init_points = init_points, n_iter = n_iter)

print("Best result: {}; f(x) = {}.".format(optimizer.max["params"], optimizer.max["target"]))