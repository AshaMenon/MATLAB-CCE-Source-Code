import yaml


class Config:
    def __init__(self, configDetails, outputLogger=None):
        self.outputLogger = outputLogger
        if isinstance(configDetails, str):
            self._Config = Config._getConfigParameter(configDetails)
        elif isinstance(configDetails, dict):
            self._Config = configDetails
        else:
            raise Exception("Unexpected input data type during Config construction.")

    def getParameters(self, parameters):
        if isinstance(parameters, str):
            config = self._Config[parameters]
        elif isinstance(parameters, list):
            config = {par: self._Config[par] for par in parameters}
        else:
            raise Exception("Unexpected input type to getParameters.")
        return config
    
    def getMinimumTimeseriesLength(self, configDict):
        '''
        Derive the minimum required length of Steady State data for this
        particular CONFIGDICT
        '''
        minRequiredLength = 1
        for key in configDict.keys():
            if key == 'smoothBasicityResponse':
                if configDict[key] == True:
                    minRequiredLength = max(minRequiredLength, 4*19) #Need at least 3 readings, assuming a median of 19 minutes apart, 4*19 would guarantee at least 3 readings
            elif key == 'addRollingSumPredictors':
                if configDict[key]['add'] == True:
                    minRequiredLength = max(minRequiredLength, configDict[key]['window'])
            elif key == 'addRollingMeanPredictors':
                if configDict[key]['add'] == True:
                    minRequiredLength = max(minRequiredLength, configDict[key]['window'])
            elif key == 'addMeasureIndicatorsAsPredictors':
                if configDict[key]['add'] == True:
                    # if any('Feedblend' in item for item in configDict[key]['on']): # Don't actually need this one, because these readings need not have been taken for a continuous steady state period. Same for Matte Temperature.
                    #     minRequiredLength = max(minRequiredLength, 10*60)
                    if any('Basicity' in item for item in configDict[key]['on']):
                        minRequiredLength = max(minRequiredLength, 2*19) #Need at least 1 reading to count the number of minutes have elapsed since that reading
            elif key == 'addShiftsToPredictors':
                if configDict[key]['add'] == True:
                    minRequiredLength = max(minRequiredLength, configDict[key]['nLags'])
            elif key == 'addResponsesAsPredictors':
                if configDict[key]['add'] == True:
                    minRequiredLength = max(minRequiredLength, configDict[key]['nLags']+1*19)
        return minRequiredLength

    def _readYamlFile(yamlFilename):
        '''
        readYamlFile Reads in a yaml extension  file
        '''
        with open(yamlFilename, "r") as f:
            return yaml.safe_load(f)

    @staticmethod
    def _getConfigParameter(configFile):
        '''Extracts the specified parameter from the yaml file'''

        config = Config._readYamlFile(configFile)

        return config

