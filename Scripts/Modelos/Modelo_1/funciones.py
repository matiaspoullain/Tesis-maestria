#Regresor RF

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

def black_box_function(n_estimators, criterion, max_depth, min_samples_split, max_features):
    parametros_opt = locals()
    semillas = [randint(0, 1000000) for _ in range(n_semillas)]
    scores = np.array([])
    for semilla in semillas:
        parametros_opt['random_state'] = semilla
        clf = estimador(parametros = parametros_opt)
        score_it = cross_val_score(estimator = clf, X = x_train, y = y_train, cv=cv, scoring='neg_root_mean_squared_error')
        scores = np.append(scores, score_it.mean())
    return scores.mean()