### Estructuracion de los datos para entrenamientos en modelos que no son intrinsecamente de series temporales (distintos al Prophet):
import os
import pandas as pd
import numpy as np 

#Leo los datos de vehiculos y feriados y los junto
datos = pd.read_csv(os.path.join('Datos', 'Insumos_prophet', 'df_prophet_entero.csv'))
feriados = pd.read_csv(os.path.join('Datos', 'Insumos_prophet', 'feriados.csv'))
datos['dia'] = [dia[0:10] for  dia in datos['ds']]
datos = datos.merge(feriados, how = "left", left_on = 'dia', right_on = 'ds')

#Reformateo columnas relacionadas al tiempo
datos['ds_x'] = pd.to_datetime(datos['ds_x'])
datos['hora'] = datos['ds_x'].dt.hour
datos['dia_semana'] = datos['ds_x'].dt.dayofweek
datos['mes'] = datos['ds_x'].dt.month
datos['anio'] = datos['ds_x'].dt.year

#One hot encoding de las columnas de feriados:
datos = datos.drop(['ds_y', 'dia', 'es_semana'], axis = 1)
datos['valor'] = ~pd.isna(datos['holiday'])
datos = pd.pivot(datos, index = ['ds_x', 'y', 'precipitaciones', 'temperatura', 'es_finde', 'hora', 'dia_semana', 'mes', 'anio'], columns = 'holiday', values = 'valor').reset_index()
datos[np.unique(feriados['holiday'])] = datos[np.unique(feriados['holiday'])].fillna(False)
datos = datos.loc[:, datos.columns.notna()]

# Cambio el valor de vehiculos a 10**vehiculos
datos['y'] = 10**datos['y']
datos = datos.rename(columns = {"ds_x":"ds"})
datos = datos.sort_values(['ds'])

""""
#Busco los valores medianos (evitando outliers) de cada hora-dia de la semana
medianas = datos.groupby(['dia_semana', 'hora'])[['y']].median().reset_index().rename({'y': 'y_mediana'}, axis = 1)

#Los uno a los datos:
datos = datos.merge(medianas, on = ['dia_semana', 'hora'])
datos = datos.sort_values(['ds'])

#Calculo la diferencia entre el valor mediano y el valor observado y borro la columna mediana:
datos['y_diff_mediana'] = datos.y_mediana - datos.y
datos = datos.drop(['y_mediana'], axis = 1)

#Creo variables laggeadas de la diferencia con la mediana de la ultima semana (cada hora):
datos_lag = pd.DataFrame()
for i in [1, 8, 12, 24, 24*7]:#range(24*7, 0, -1):
   datos_lag['y_diff_mediana_lag_' + str(i)] = datos.y_diff_mediana.shift(i)
datos = pd.concat([datos, datos_lag], axis=1)
datos.dropna(inplace=True)
"""

#Corrijo columnas que tienen "[", "]":
datos.columns = [nombre.replace('[', '(').replace(']', ')') for nombre in datos.columns]

#Corrijo los booleanos a 0/1:
datos[datos.select_dtypes(include=['bool']).columns] = datos.select_dtypes(include=['bool']).astype(int)

#Guardo el archivo
datos.to_csv(os.path.join('Datos', 'Insumos_python', 'insumo_modelo_1.csv'), index = False)