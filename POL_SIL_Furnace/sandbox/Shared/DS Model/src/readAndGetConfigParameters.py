import yaml

def readYamlFile(yamlFilename):
    '''readYamlFile Reads in a yaml extension  file
    
    '''
    with open(yamlFilename, "r") as f:
        return yaml.safe_load(f)

def getConfigParameter(parameter, configFile):

    '''Extracts the specified parameter from the yaml file'''

    config = readYamlFile(configFile)

    return config[parameter]    
