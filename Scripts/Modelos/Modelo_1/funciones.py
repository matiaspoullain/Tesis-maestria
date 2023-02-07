import pandas as pd
import json
import os

#Funcion para leer los mejores parametros de los logs de las optimizaciones
def get_mejores_params(algoritmo, archivo_log = None):
    if archivo_log is None:
        archivo_log = os.path.join('Modelos', 'logs', algoritmo, "Optimizacion_bayesiana_logs.json")
    json_opt_out = []
    for line in open(archivo_log, 'r'):
        json_opt_out.append(json.loads(line))
    json_opt_out = pd.DataFrame.from_records(json_opt_out)

    parametros = json_opt_out[json_opt_out['target'] == max(json_opt_out['target'])]['params'].values[0]

    return parametros