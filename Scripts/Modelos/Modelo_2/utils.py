from typing import Any, Dict, Type, Union, List
import pandas as pd
from math import sqrt
import numpy as np
from sklearn.metrics import mean_squared_error
from sklearn.preprocessing import StandardScaler



def sklearn_cv_by_indexes(
    model: Any,
    dtrain: pd.DataFrame,
    indx_tuples: tuple,
    target_name: str = 'target',
    scale: bool = True
) -> float:
    """CV for list of tuple (train_idx, test_idx)

    Args:
        model (Any): Started model
        dtrain (pd.DataFrame): train dataset with target column
        indx_tuples (tuple): List of tuples (train_idx, test_idx)
        target_name (str, optional): Name of target variable. Defaults to 'target'.

    Returns:
        float: Mean score
    """    
    scores = []
    for train_idx, test_idx in indx_tuples:
        X_train, X_test = dtrain.iloc[train_idx].drop(target_name, axis = 1), dtrain.iloc[test_idx].drop(target_name, axis = 1)
        y_train, y_test = dtrain.iloc[train_idx][target_name], dtrain.iloc[test_idx][target_name]
        
        if scale:
            scaler = StandardScaler()
            X_train = scaler.fit_transform(X_train)
            X_test = scaler.transform(X_test)
        
        # Train
        model.fit(X_train, y_train)
        # Predict
        y_pred = model.predict(X_test)
        
        scores.append(sqrt(mean_squared_error(y_test, y_pred)))
    return np.mean(scores)