import os
import pandas as pd
import numpy as np
import xgboost as xgb
import optuna
import json
from termcolor import colored
from datetime import timedelta


# -------------------------------- Parametros -------------------------------- #
timeseries_cv_folds = 5
df_optimizacion_directory = os.path.join('Modelos', 'Modelo_2', 'XGB')
db_optimizacion = os.path.join(df_optimizacion_directory, 'opt_bayesiana.db')
json_parametros_optimizados = os.path.join(df_optimizacion_directory, 'parametros_optimizados.json')
os.makedirs(df_optimizacion_directory, exist_ok=True)
semanas_heldout = 3
num_boost_round = 10000

# ---------------------------------------------------------------------------- #
#                               Lectura de datos                               #
# ---------------------------------------------------------------------------- #
datos = pd.read_csv('Datos/Insumo_modelos/Modelo_2/XGB.csv')
datos['ds'] = pd.to_datetime(datos['ds']).dt.tz_localize(None)
corte_heldout = datos['ds'].max() - timedelta(weeks=semanas_heldout)
datos['heldout'] = datos['ds'] > corte_heldout

# ---------------------------------- Dummies --------------------------------- #
datos = pd.get_dummies(datos, prefix=['holiday_dummy'], columns=['holiday'], dtype=float)
datos = datos[~datos['heldout']]

# --------------------- Obtener lista de indices para CV --------------------- #
#Se maximiza la seleccion para entrenar con al menos un año y el maximo valor de prediccion a futuro. 3 semanas de heldout
datos['inv_index'] = range(len(datos)-1, -1, -1)
lineas_disponibles_validacion = datos[datos['ds']>='2020-03-20'].shape[0]
horizon = lineas_disponibles_validacion/timeseries_cv_folds
datos['inv_index'] = (datos['inv_index']/horizon).astype(int)
test_indx = [datos.index.values[datos['inv_index']==i] for i in range(timeseries_cv_folds)]
datos = datos[~datos['y'].isnull()]
#Nuevo index despues de borrar y faltantes:
datos['new_index'] = range(0, len(datos))
new_test_indx = []
for old_indx_array in test_indx:
    new_test_indx.append(datos.filter(old_indx_array, axis = 0)['new_index'].values)
train_indx = [np.array(range(0, min(t_indx))) for t_indx in new_test_indx]
#Folds del cv
cv_indexes = list(zip(train_indx, new_test_indx))

X = xgb.DMatrix(datos.drop(['ds', 'heldout', 'inv_index', 'new_index', 'y'], axis = 1), label=datos['y'])

# ---------------------------------------------------------------------------- #
#                                 Optimizacion                                 #
# ---------------------------------------------------------------------------- #

def objective(trial):
    param = {
            "verbosity": 0,
            "tree_method": "auto",
            "booster": "gbtree",
            "subsample": trial.suggest_float("subsample", 0.2, 1.0),
            "colsample_bytree": trial.suggest_float("colsample_bytree", 0.2, 1.0),
            'eval_metric': 'rmse',
            "max_depth": trial.suggest_int("max_depth", 3, 101, step=2),
            "min_child_weight": trial.suggest_int("min_child_weight", 0, 10),
            "eta": trial.suggest_float("eta", 1e-4, 1.0, log=True)
        }

    param['early_stopping_rounds'] = int(50 + 5/param["eta"])

    xgb_pruning_callback = optuna.integration.XGBoostPruningCallback(trial, 'test-rmse')

    xgb_model = xgb.cv(param, X, folds = cv_indexes, num_boost_round = num_boost_round, early_stopping_rounds = param['early_stopping_rounds'], callbacks=[xgb_pruning_callback])
    mean_score = xgb_model['test-rmse-mean'].min()
    return mean_score

# Crear study e iniciar la optimizacion
pruner = optuna.pruners.MedianPruner(n_startup_trials=30, n_warmup_steps=int(num_boost_round/10))
study = optuna.create_study(direction='minimize', study_name='Modelo_2', storage=f'sqlite:///{db_optimizacion}', load_if_exists = True, pruner = pruner)
study.optimize(objective, n_trials=1000, gc_after_trial=True)

# Guardar mejores hiperparametros
best_params = study.best_params
best_params['early_stopping_rounds'] = int(50 + 5/best_params["eta"])
best_params['n_estimators'] = num_boost_round
with open(json_parametros_optimizados, 'w') as json_file:
    json.dump(best_params, json_file)

# Print como explorar el dashboard
comando_optuna_dashboard = colored(f'optuna-dashboard sqlite:///{db_optimizacion}', "green")
print(f'Correr {comando_optuna_dashboard} para ver dashboard de la optimizacion')