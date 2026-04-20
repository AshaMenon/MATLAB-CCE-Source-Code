function simOut = massSpringDamperModel(data, params)

    simInputs = Simulink.SimulationInput('MassSpringDamperModel');
    stopTimeStr = num2str(params.StopTimeSpinnerValue);
    simInputs = simInputs.setModelParameter('StopTime', stopTimeStr);
    simInputs.ExternalInput = externalInput(params);
    simInputs = simInputs.setVariable('k',params.StiffnessSpinnerValue);
    simInputs = simInputs.setVariable('k',params.StiffnessSpinnerValue);
    simInputs = simInputs.setVariable('m',data.MassSpinnerValue);
    simInputs = simInputs.setVariable('b',params.DampingSpinnerValue);
    %simInputs = simInputs.setVariable('x0',params.InitialPositionEditFieldValue);
    simInputs = simulink.compiler.configureForDeployment(simInputs);

    %set_param('MassSpringDamperModel','LoadExternalInput','on');
    simOut = sim(simInputs); 