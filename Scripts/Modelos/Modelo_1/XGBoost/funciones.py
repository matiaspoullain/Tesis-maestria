from xgboost import XGBRegressor
from sklearn.model_selection import cross_val_score
import numpy as np
from random import randint

#Regresor XGB
def estimador(parametros):
        parametros_it = parametros.copy()
        dict_tree_method = {
            0: 'exact',
            1: 'approx',
            2: 'hist'    
        }
        parametros_it['tree_method'] = dict_tree_method[int(parametros_it['tree_method'])]
        parametros_it['max_depth'] = 0
        return XGBRegressor(**parametros_it)

#Black box function para la optimizacion bayesiana del modelo RF
#Usa variables definidas por fuera, no le pude encontrar otra vuelta
def black_box_function(x_train, y_train, cv):
    def black_box_function_builder(eta, gamma, reg_lambda, tree_method):
        parametros_opt = locals()
        exclude_keys = ['x_train', 'y_train', 'cv'] #Estos parametros estan en locals pero no los quiero como parametros del estimador
        parametros_opt = {k: parametros_opt[k] for k in set(list(parametros_opt.keys())) - set(exclude_keys)}
        semillas = [randint(0, 1000000) for _ in range(5)]
        scores = np.array([])
        for semilla in semillas:
            parametros_opt['seed'] = semilla
            clf = estimador(parametros = parametros_opt)
            score_it = cross_val_score(estimator = clf, X = x_train, y = y_train, cv=cv, scoring='neg_root_mean_squared_error', n_jobs = -1)
            scores = np.append(scores, score_it.mean())
        return scores.mean()
    return black_box_function_builder