import os
import pandas as pd
import numpy as np
from sklearn.linear_model import Ridge
import optuna
import json
from termcolor import colored
from datetime import timedelta
from Scripts.Modelos.Modelo_2.utils import sklearn_cv_by_indexes


# -------------------------------- Parametros -------------------------------- #
timeseries_cv_folds = 5
df_optimizacion_directory = os.path.join('Modelos', 'Modelo_2', 'Ridge')
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

X = datos.drop(['ds', 'heldout', 'inv_index', 'new_index'], axis = 1)

# ---------------------------------------------------------------------------- #
#                                 Optimizacion                                 #
# ---------------------------------------------------------------------------- #

def objective(trial):
    param = {
        'alpha': trial.suggest_float('alpha', 1e-10, 1.0, log = True)
    }
            
    model = Ridge(**param)
    mean_score = sklearn_cv_by_indexes(model, X, cv_indexes, target_name='y')
    return mean_score

# Crear study e iniciar la optimizacion
study = optuna.create_study(direction='minimize', study_name='Modelo_2', storage=f'sqlite:///{db_optimizacion}', load_if_exists = True)
study.optimize(objective, n_trials=1000, gc_after_trial=True, n_jobs = -1)

# Guardar mejores hiperparametros
best_params = study.best_params
with open(json_parametros_optimizados, 'w') as json_file:
    json.dump(best_params, json_file)

# Print como explorar el dashboard
comando_optuna_dashboard = colored(f'optuna-dashboard sqlite:///{db_optimizacion}', "green")
print(f'Correr {comando_optuna_dashboard} para ver dashboard de la optimizacion')