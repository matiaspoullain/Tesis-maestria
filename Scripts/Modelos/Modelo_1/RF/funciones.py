from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import cross_val_score
import numpy as np
from random import randint

#Regresor RF
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
