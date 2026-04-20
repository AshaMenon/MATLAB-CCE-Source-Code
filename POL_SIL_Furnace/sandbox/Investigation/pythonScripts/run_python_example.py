import pandas as pd
import os
from mode import create_mode_proxy

cwd = os.path.dirname(os.path.dirname(os.getcwd()))
path = os.path.join(cwd, 'data', 'Polokwane_SIL_furnace_data_Jan_Aug23_v3.csv')

columns = pd.read_csv(path, nrows=0).columns.tolist()
df = pd.read_csv(path)
df = df.apply(lambda col: pd.to_numeric(col, errors='coerce') if col.name != 'Timestamp' else col)

print(df.head())

df2 = create_mode_proxy(df)