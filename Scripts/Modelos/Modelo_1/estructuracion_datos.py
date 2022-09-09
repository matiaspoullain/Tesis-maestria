### Estructuracion de los datos para entrenamientos en Python:
import os
os.chdir("D:\OneDrive\OneDrive - UCA\Escritorio\Proyectos\Tesis-maestria")


import pandas as pd
import numpy as np 


datos = pd.read_csv("Datos/Insumos_prophet/df_prophet_entero.csv")
feriados = pd.read_csv("Datos/Insumos_prophet/feriados.csv")
datos['dia'] = [dia[0:10] for  dia in datos['ds']]
datos = datos.merge(feriados, how = "left", left_on = 'dia', right_on = 'ds')

datos['ds_x'] = pd.to_datetime(datos['ds_x'])
datos['hora'] = datos['ds_x'].dt.hour
datos['dia_semana'] = datos['ds_x'].dt.dayofweek
datos['mes'] = datos['ds_x'].dt.month
datos['anio'] = datos['ds_x'].dt.year


datos = datos.drop(['ds_y', 'dia', 'es_semana'], axis = 1)
datos['valor'] = ~pd.isna(datos['holiday'])
datos = pd.pivot(datos, index = ['ds_x', 'y', 'precipitaciones', 'temperatura', 'es_finde', 'hora', 'dia_semana', 'mes', 'anio'], columns = 'holiday', values = 'valor').reset_index()
datos[np.unique(feriados['holiday'])] = datos[np.unique(feriados['holiday'])].fillna(False)
datos = datos.loc[:, datos.columns.notna()]

datos['y'] = 10**datos['y']
datos = datos.rename(columns = {"ds_x":"ds"})

#Lags:
datos_lag = pd.DataFrame()
for i in range(24*7, 0, -1):
   datos_lag['y_lag_' + str(i)] = datos.y.shift(i)
datos = pd.concat([datos, datos_lag], axis=1)
datos.dropna(inplace=True)

datos.to_csv('Datos/Insumos_python/insumo_modelo_1.csv', index = False)