import krippendorff.krippendorff
import numpy as np
import pandas as pd
import krippendorff
import pprint

from classes import Coder, Annotation

#load example data
df = pd.read_csv('Coding rounds - 446.csv')

# access coder columns
coder_info = {
  "a.m.j.van.hoof@vu.nl":"AvH",
  "m.e.reuver@vu.nl": "MR",
  "vanatteveldt@gmail.com": "Wouter",
  "info@jessicafiks.nl": "Jessica",
  "nelruigrok@nieuwsmonitor.org": "Nel",
  "s.sramota@vu.nl": "Sarah",
  "i.nait.el.ghazi@student.vu.nl": "Ihsane",
  "n.karadavut@student.vu.nl": "Nisanur",
  "s.b.van.haasteren@student.vu.nl": "Sascha",
  "o.ben.youssef@student.vu.nl": "Oumaima",
  "k.narain@student.vu.nl": "Karishma",
  "jellevanelburg@gmail.com": "Jelle"
}


def create_coders_dict(coder_info:dict):

    coders = {} 

    for key, value in coder_info.items():
        coders[value] = Coder(
            email=key,
            name=value, 
            annotations=[]
            )
        
    return coders
    

def category_mapping(df:pd.DataFrame, coders:dict):

    #  Define the mapping for categorical values
    category_mapping = {'L': -1, 'N': 0, 'R': 1}
    
    for col in df.columns:
        if col in coders.keys():
            df.loc[:, col] = df[col].map(category_mapping).astype(float)
    
    return df


def retrieve_coder_annotations(df:pd.DataFrame, coder_name:str):

    annotations = []
    
    for index in range(len(df)):
        if coder_name not in df.columns:
            continue
        
        annotations.append(Annotation(
            value = df[coder_name].iloc[index],
            jobid = df['jobid'].iloc[index],
            unit_id = df['unit_id'].iloc[index],
            topic = df['topic'].iloc[index],
            text = df['text'].iloc[index],
            coder_name=coder_name
            ))
        
    return annotations


coders = create_coders_dict(coder_info)

category_mapping(df, coders)

annotations = retrieve_coder_annotations(df=df, coder_name='Nel')

# pprint.pprint(annotations)

for key, value in coders.items():
    value['annotations'] = retrieve_coder_annotations(df, key)

print(coders['Nel']['annotations'][2].value)
pprint.pprint(coders['Jelle'])

krippendorff.alpha()


# def coder_columns_from_df(df:pd.DataFrame, coders:dict):
#     "Seperates columns that coded values from dataframe"

#     coder_columns = []

#     for col in df.columns:
#         if col in coders.values():
#             coder_columns.append(col)

#     coder_df = df[coder_columns]

#     return coder_df



#calculate reliability

# def calculate_reliability(df: pd.DataFrame, coders: dict):
#     # Define the mapping for categorical values
#     category_mapping = {'L': -1, 'N': 0, 'R': 1}
    
#     for col in df.columns:
#         if col in coders.values():
#             print(f"Unique values in {col} before mapping: {df[col].unique()}")
#             df.loc[:, col] = df[col].map(category_mapping).astype(float)
#             print(f"Unique values in {col} after mapping: {df[col].unique()}")

#     # # Convert categorical columns in the original DataFrame to numerical codes
#     # for col in df.columns:
#     #     if col in coders.values():
#     #         # Map values to custom codes, replacing NA with np.nan
#     #         df.loc[:, col] = df[col].map(category_mapping)
#     #         df.loc[:, col] = df.loc[:, col].replace({np.nan: np.nan})  # Ensure NaNs are kept

#     #         # Convert to float to allow NaN values
#     #         df.loc[:, col] = df.loc[:, col].astype(float)

#     # Get coder-only columns
#     coder_df = coder_columns_from_df(df, coders)

#     # Convert the DataFrame to a list of lists for Krippendorff's alpha
#     coder_data = coder_df.to_numpy().T  # Transpose for Krippendorff's function

#     # Calculate Krippendorff's alpha
#     alpha = krippendorff.alpha(reliability_data=coder_data, level_of_measurement='interval')
#     print("Krippendorff's Alpha:", alpha)


# # Run reliability calculation
# calculate_reliability(df, coders)
