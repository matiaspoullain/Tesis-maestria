import os
import pandas as pd
from prophet import Prophet
from prophet.diagnostics import cross_validation, performance_metrics
import optuna
import json
from termcolor import colored
from datetime import timedelta


# -------------------------------- Parametros -------------------------------- #
timeseries_cv_folds = 5
df_optimizacion_directory = os.path.join('Modelos', 'Modelo_2', 'Prophet')
db_optimizacion = os.path.join(df_optimizacion_directory, 'opt_bayesiana.db')
json_parametros_optimizados = os.path.join(df_optimizacion_directory, 'parametros_optimizados.json')
os.makedirs(df_optimizacion_directory, exist_ok=True)
semanas_heldout = 3

# ---------------------------------------------------------------------------- #
#                               Lectura de datos                               #
# ---------------------------------------------------------------------------- #
datos = pd.read_csv('Datos/Insumo_modelos/Modelo_2/prophet.csv')
datos['ds'] = pd.to_datetime(datos['ds']).dt.tz_localize(None)
corte_heldout = datos['ds'].max() - timedelta(weeks=semanas_heldout)
datos = datos[datos['ds'] <= corte_heldout].reset_index(drop = True) 
feriados = pd.read_csv('Datos/Insumos_prophet/feriados.csv')

# --------------------- Obtener lista de indices para CV --------------------- #
#Se maximiza la seleccion para entrenar con al menos un año y el maximo valor de prediccion a futuro. 3 folds da unos 26.333 dias de prediccion
datos['inv_index'] = range(len(datos)-1, -1, -1)
lineas_disponibles_validacion = datos[datos['ds']>='2020-03-20'].shape[0]
horizon = lineas_disponibles_validacion/timeseries_cv_folds
datos['inv_index'] = (datos['inv_index']/horizon).astype(int)
#test_indx = [datos.index.values[datos['inv_index']==i] for i in range(timeseries_cv_folds)]
cutoffs = [datos.loc[datos['inv_index']==i, 'ds'].min() for i in range(timeseries_cv_folds)]
datos = datos.drop('inv_index', axis = 1)

X = datos[~datos['y'].isnull()]

# ---------------------------------------------------------------------------- #
#                                 Optimizacion                                 #
# ---------------------------------------------------------------------------- #

def objective(trial):
    # Define the search space for hyperparameters
    changepoint_prior_scale = trial.suggest_float('changepoint_prior_scale', 0.001, 0.5, log=True)
    seasonality_prior_scale = trial.suggest_float('seasonality_prior_scale', 0.01, 10, log=True)
    holidays_prior_scale = trial.suggest_float('holidays_prior_scale', 0.01, 10, log=True)

    # Initialize the Prophet model with the suggested hyperparameters
    model = Prophet(
        growth = "flat",
        seasonality_mode = "additive",
        changepoint_range=0.8,
        yearly_seasonality = True,
        weekly_seasonality = True,
        daily_seasonality = False,
        mcmc_samples = 1000,
        holidays=feriados,
        changepoint_prior_scale=changepoint_prior_scale,
        seasonality_prior_scale=seasonality_prior_scale,
        holidays_prior_scale=holidays_prior_scale
    )

    model.add_regressor('cantidad_pasos', mode='additive')
    model.add_regressor('log_temperatura', mode='additive')
    model.add_regressor('log_intensidad_viento_km_h', mode='additive')

    # Fittear modelo
    model.fit(X, max_treedepth = 30)

    # CV
    df_cv = cross_validation(model, cutoffs=cutoffs, horizon=f'{horizon-2} days', parallel='processes')

    # Calculate the Mean Absolute Percentage Error (MAPE)
    rmse = performance_metrics(df_cv)['rmse'].values[0]

    return rmse

# Crear study e iniciar la optimizacion
study = optuna.create_study(direction='minimize', study_name='Modelo_2', storage=f'sqlite:///{db_optimizacion}', load_if_exists = True)
study.optimize(objective, n_trials=100, gc_after_trial=True)

# Guardar mejores hiperparametros
with open(json_parametros_optimizados, 'w') as json_file:
    json.dump(study.best_params, json_file)

# Print como explorar el dashboard
comando_optuna_dashboard = colored(f'optuna-dashboard sqlite:///{db_optimizacion}', "green")
print(f'Correr {comando_optuna_dashboard} para ver dashboard de la optimizacion')