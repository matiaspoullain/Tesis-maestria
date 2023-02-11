from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import cross_val_score
import numpy as np
from random import randint
import os
import pandas as pd
import json

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
        return RandomForestRegressor(**parametros_it)

#Black box function para la optimizacion bayesiana del modelo RF
#Usa variables definidas por fuera, no le pude encontrar otra vuelta
def black_box_function(x_train, y_train, cv, archivo_log):
    def black_box_function_builder(criterion, n_estimators, min_samples_split, max_features):     
        parametros_opt = locals()
        exclude_keys = ['x_train', 'y_train', 'cv', 'archivo_log'] #Estos parametros estan en locals pero no los quiero como parametros del estimador
        parametros_opt = {k: parametros_opt[k] for k in set(list(parametros_opt.keys())) - set(exclude_keys)}
        
        #Parche por si se enceuntra con la misma combinacion que ya vio
        if os.path.isfile(archivo_log.replace('.json', '_guardado.json')):
            json_opt_out = []
            for line in open(archivo_log.replace('.json', '_guardado.json'), 'r'):
                json_opt_out.append(json.loads(line))
            json_opt_out = pd.DataFrame.from_records(json_opt_out)
            valor_visto = json_opt_out[json_opt_out.params == parametros_opt].target.values
            if len(valor_visto) > 0:
                 return valor_visto.mean()

        semillas = [randint(0, 1000000) for _ in range(5)]
        scores = np.array([])
        for semilla in semillas:
            parametros_opt['random_state'] = semilla
            try:
                 parametros_opt['n_jobs'] = -1
                 clf = estimador(parametros = parametros_opt)
                 score_it = cross_val_score(estimator = clf, X = x_train, y = y_train, cv=cv, scoring='neg_root_mean_squared_error')
            except:
                 parametros_opt['n_jobs'] = None
                 clf = estimador(parametros = parametros_opt)
                 score_it = cross_val_score(estimator = clf, X = x_train, y = y_train, cv=cv, scoring='neg_root_mean_squared_error', n_jobs = -1)

            scores = np.append(scores, score_it.mean())
        return scores.mean()
    return black_box_function_builder