#%% Read and Format Data
import Shared.DSModel.src.preprocessingFunctions as prep
from Shared.DSModel.Data import Data
import CCEScripts.common.cce_logger as cce_logger

#%% Model excution stuff
parameters = dict()
parameters['writeToExcel'] = False
parameters['highFrequencyPredictorTags'] = ["Matte feed PV", "Fuel coal feed rate PV", "Specific Oxygen Actual PV",
                                            "Reverts feed rate PV", "Lump coal PV",
                                            "Lance oxygen flow rate PV", "Lance air flow rate PV",
                                            "Matte transfer air flow", "Lance coal carrier air",
                                            "Silica PV",
                                            "Upper Waffle 3", "Upper Waffle 4", "Upper Waffle 5",
                                            "Upper Waffle 6", "Upper Waffle 7", "Upper Waffle 8",
                                            "Upper Waffle 9", "Upper Waffle 10", "Upper Waffle 11",
                                            "Upper Waffle 12", "Upper Waffle 13", "Upper Waffle 14",
                                            "Upper Waffle 15", "Upper Waffle 16", "Upper Waffle 17",
                                            "Upper Waffle 18",
                                            "Lower waffle 19", "Lower waffle 20", "Lower waffle 21",
                                            "Lower waffle 22", "Lower waffle 23", "Lower waffle 24",
                                            "Lower waffle 25", "Lower waffle 26", "Lower waffle 27",
                                            "Lower waffle 28", "Lower waffle 29", "Lower waffle 30",
                                            "Lower waffle 31", "Lower waffle 32", "Lower waffle 33",
                                            "Lower waffle 34", "Outer long 1", "Middle long 1",
                                            "Outer long 2", "Middle long 2", "Outer long 3",
                                            "Middle long 3", "Outer long 4", "Middle long 4",
                                            "Centre long", "Lance Oxy Enrich % PV", "Roof matte feed rate PV",
                                            "Lance height", "Lance motion", "Phase B Matte tap block 1 DT_water",
                                            "Phase B Matte tap block 2 DT_water", "Phase B Slag tap block DT_water",
                                            "Phase A Matte tap block 1 DT_water", "Phase A Matte tap block  DT_water",
                                            "Phase A Slag tap block DT_water"]

parameters['lowFrequencyPredictorTags'] = ["Cr2O3 Slag", "Basicity", "MgO Slag", "Cu Feedblend", "Ni Feedblend",
                                           "Co Feedblend", "Fe Feedblend", "S Feedblend",
                                           "SiO2 Feedblend", "Al2O3 Feedblend", "CaO Feedblend",
                                           "MgO Feedblend", "Cr2O3 Feedblend", "Slag temperatures"]

parameters['referenceTags'] = ["Converter mode", "Lance air and oxygen control"]

parameters['responseTags'] = ["Matte temperatures"]

parameters['filterFurnaceModes'] = {'add': False, 'modes':[6, 7, 8]}

parameters['removeTransientData'] = False

parameters['tapClassification'] = True

parameters['smoothFuelCoal'] = True

# Setup the Data
inputsDF = prep.readAndFormatData('Temperature')
inputsDF = prep.fillMissingHXPoints(inputsDF)

phase = 'A' # A - Jan 2021 - Dec 2021, B - Jan 2022 onwards

# Add latent features (Specific to Temperature Model)
inputsDF, _, parameters['highFrequencyPredictorTags'], parameters['lowFrequencyPredictorTags'] = \
    prep.addLatentTemperatureFeatures(inputsDF, parameters['highFrequencyPredictorTags']+parameters['lowFrequencyPredictorTags'],
                                      parameters['highFrequencyPredictorTags'], parameters['lowFrequencyPredictorTags'], phase)
#%%
log_file = 'MatteTemp'
calculation_id = 'TMT'
log_level = 255
calculation_name = 'Test Matte Temperature'
log = cce_logger.CCELogger(log_file, calculation_name, calculation_id, log_level)
dataModel = Data(inputsDF, log)

fullDF, origSmoothedResponses, predictorTagsNew = dataModel.preprocessingAndFeatureEngineering(**parameters)