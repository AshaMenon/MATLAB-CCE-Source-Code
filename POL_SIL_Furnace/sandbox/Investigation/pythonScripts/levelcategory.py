import pandas as pd

def assign_level_categories(level_df, custom_order, tags, level_type):
    """
    Assigns level categories based on level type

    :param level_df: Pandas dataframe with level data
    :param custom_order: Order of categories
    :param tags: Tags of columns to be converted
    :param level_type: Level type - slag, matte, bonedry, bath
    :return: Updated level_df
    """

    if level_type == 'slag':
        func_handle = categorise_slag_level
    elif level_type == 'matte':
        func_handle = categorise_matte_level
    elif level_type == 'bath':
        func_handle = categorise_bath_level
    elif level_type == 'bonedry':
        func_handle = categorise_bonedry_level
    else:
        raise ValueError('Invalid Function choice')

    for tag in tags:
        categories = []

        for _, row in level_df.iterrows():
            level = row[tag]
            categories.append(func_handle(level))

        column_name_cat = f"{tag}Cat"
        level_df[column_name_cat] = pd.Categorical(categories, categories=custom_order, ordered=True)

    return level_df

def categorise_slag_level(level):
    """
    Categorise level for 'slag' type.

    :param level: Level to be categorized
    :return: Categorisation result as a string
    """
    if level >= 145:
        category = 'Extremely High'
    elif 130 <= level < 145:
        category = 'Very High'
    elif 120 <= level < 130:
        category = 'High'
    elif 100 <= level < 120:
        category = 'Normal'
    elif 90 <= level < 100:
        category = 'Low'
    elif 80 <= level < 90:
        category = 'Very Low'
    elif level < 80:
        category = 'Extremely Low'
    else:
        category = 'Undefined'

    return category

def categorise_matte_level(level):
    """
    Categorise level for 'matte' type.

    :param level: Level to be categorized
    :return: Categorisation result as a string
    """

    if level >= 72:
        category = 'Run Out'
    elif 70 <= level < 72:
        category = 'Very High'
    elif 68 <= level < 70:
        category = 'High'
    elif 62 <= level < 68 :
        category = 'Normal'
    elif 58 <= level < 62:
        category = 'Very Low'
    elif level < 58 :
        category = 'Extremely Low'
    else:
        category = 'Undefined'

    return category

def categorise_bath_level(level):
    """
    Categorise level for 'bath' type.

    :param level: Level to be categorized
    :return: Categorisation result as a string
    """
    if level >= 220:
        category = 'Extremely High'
    elif 200 <= level < 220:
        category = 'Above Waffle Coolers'
    elif 195 <= level < 200:
        category = 'Very High'
    elif 185 <= level < 195:
        category = 'High'
    elif 160 <= level < 185: 
        category = 'Normal'
    elif level < 160: 
        category = 'Low'
    else:
        category = 'Undefined'

    return category
    

def categorise_bonedry_level(level):
    """
    Categorise level for 'bath' type.

    :param level: Level to be categorized
    :return: Categorisation result as a string
    """
    if level >= 120:
        category = 'Extremely High'
    elif 100 <= level < 120:
        category = 'High'
    elif 80 <= level < 100:
        category = 'Normal'
    elif level < 80:
        category = 'Low'
    else:
        category = 'Undefined'

    return category

     
   
    
