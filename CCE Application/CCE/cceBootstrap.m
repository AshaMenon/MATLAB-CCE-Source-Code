function cceBootstrap(varargin)
    %cceBootstrap  Initialise CCE system
    %   cceBootstrap() provides first-time installation of the CCE system, checking the
    %   CCE configuration file and creating the Configurator Scheduled task, running as the user
    %   cceServer; you must enter the password for the user in a secure dialog. The Configurator is
    %   executed from that scheduled task once.
    %
    %   cceBootstrap(Name, Value) allows you to override some behaviour of the Bootstrapping process.
    %   Defaults are shown in brackets for each option.
    %   "-username" [cceServer]: Specify the name of the running CCE user.
    %   "-password" [<prompted>]: Specify the password for the CCE user. If you do not specify a value,
    %       you will be prompted for one in a secure dialog.
    %   "-runConfigurator" [true]: Specify "true" to run the configurator immediately after
    %       bootstrapping the Scheduled Task, or "false" to not run the configurator.
    %   "-help": Display instructions for how to use cceBootstrap.
    %
    %   See also: cceStatus, cceStop, cceRestart.
    
    % Copyright 2021 Opti-Num Solutions (Pty) Ltd
    % Version: $Format:%ci$ ($Format:%h$)
    % developed as background IP for Anglo American Platinum
    
    %% Argument-checking
    % We cannot use inputParser here because our names must be preceded with dashes, to conform to
    % Windows command-line conventions.
    username = "cceServer";
    password = "";
    runConfigurator = true;
    while numel(varargin)>0
        arg = string(varargin{1});
        if numel(varargin)>1
            val = varargin{2};
        else
            val = [];
        end
        switch lower(arg)
            case "-help"
                % Display help.
                fprintf("%s\n", helpString());
                return;
            case "-username"
                username = errorIfNotUsername(val);
            case "-password"
                password = string(val);
            case "-runconfigurator"
                runConfigurator = safeTrueFalse(val);
            otherwise
                error("optinum:cceBootstrap:InvalidName", "Invalid name %s", arg);
        end
        varargin(1:2)=[]; % Fortunately they come in pairs.
    end
    if numel(varargin) > 1
        error("optinum:cceBootstrap:NameValueMismatch", "Name passed without a Value.");
    end
    
    % If we don't have a password, ask for one
    if strlength(password)==0
        % TODO: We know Java will go away. Figure out if we can do this with something else
        warnState = warning('off', 'MATLAB:ui:javacomponent:FunctionToBeRemoved');
        password = string(passwordEntryDialog('ValidatePassword',true, 'CheckPasswordLength', false, ...
            'WindowName', 'Enter Password for CCE User'));
        warning(warnState);
    end
    % If the user cancels, we get an empty string
    if strlength(password)==0
        return
    end
    % And encrypt the password
    aesObj = AESEncrypter;
    encryptedPassword = aesObj.encrypt(password);
    
    %% Check the configuration file to ensure that the syntax is correct.
    % We write out an encrypted version of the password to the config file
    configFile = fullfile(getenv("CCE_Root"),"config","cce.conf");
    conf = toml.read(configFile);
    % TODO: Add checks for the right fields
    conf.System.CCEUsername = char(username);
    conf.System.CCEPassword = char(encryptedPassword);
    toml.write(configFile, conf);
    
    %% Check access to PI as the required user.
    % a.	Logging into PI AF as the required user to ensure that the login works.
    % b.	Checking for the existence of the cceCoordinator template and cceCalculation root template, as the logged in user.
    
    %% Create the “CCE” Scheduled Task folder, to house all CCE scheduled tasks.
    wScheduler = WindowsScheduler;
    cceFolderName = cce.System.SchedulerFolderName;
    
    %% Create the CCE Configurator task in the CCE task folder.
    % Check if the CCE Configurator task exists. If it does, enable it.
    configuratorTaskName = "CCE Configurator"; % TODO: Read from config file
    taskDescription = "CCE Configurator - Creates Coordinators to run CCE calculations.";
    startTime = datetime('tomorrow') + hours(3); % TODO: Read from config file
    repeatInterval = days(1); % TODO: Read from config file
    stopOverrun = hours(1);
    cmdToRun = fullfile(cce.System.RootFolder, "bin", "cceConfigurator.exe");
    % Create the scheduled task - This will also update an existing one
    fprintf("Creating Configurator Scheduled Task.\n");
    configuratorTask = wScheduler.createTask(configuratorTaskName, cmdToRun, "", ...
        startTime, repeatInterval, stopAfter=stopOverrun, autoRestart=false, ...
        folderName=cceFolderName, description=taskDescription, author="CCE Configurator", ...
        userCredentials=[username, password]);
    if isempty(configuratorTask)
        error("Could not create Configurator Scheduled Task. Bootstrap failed.");
    else
        enable(configuratorTask); % Just to be sure.
    end
    
    %% If required, run the configurator for the first time.
    if runConfigurator
        fprintf("Running Configurator Service Task once.\n");
        runTask(SchedulerTaskService, configuratorTaskName, cceFolderName);
    end
end

%% Helper functions
function uName = errorIfNotUsername(uName)
    %errorIfNotUsername  Throw an error if the input is not a valid username
    % errorIfNotUsername(userName)
    % TODO: Implement a "valid username" algorithm.
    if strlength(uName) < 1
        error("cce:Bootsrap:EmptyUsername", "Username cannot be empty.");
    end
end

function tf = safeTrueFalse(x)
    %safeTrueFalse  Accept true, false, yes, no, 1, 0, true, false as valid logical inputs
    if ischar(x) || isstring(x)
        if ismember(string(lower(x)), ["yes", "true"])
            tf = true;
        elseif ismember(string(lower(x)), ["no", "false"])
            tf = false;
        else
            error("optinum:cceBootstrap:InvalidArgument", "Cannot parse input to true/false.")
        end
    else
        tf = logical(x);
    end
end

function str = helpString()
    %helpStr  Return the help for this function
    str=[...
" cceBootstrap  Initialise CCE system"
"    cceBootstrap() provides first-time installation of the CCE system, checking the"
"    CCE configuration file and creating the Configurator Scheduled task, running as the user"
"    cceServer; you must enter the password for the user in a secure dialog. The Configurator is"
"    executed from that scheduled task once."
" "
"    cceBootstrap(Name, Value) allows you to override some behaviour of the Bootstrapping process."
"    Defaults are shown in brackets for each option."
"    ""-username"" [cceServer]: Specify the name of the running CCE user."
"    ""-password"" [<prompted>]: Specify the password for the CCE user. If you do not specify a value,"
"        you will be prompted for one in a secure dialog."
"    ""-runConfigurator"" [true]: Specify ""true"" to run the configurator immediately after"
"        bootstrapping the Scheduled Task, or ""false"" to not run the configurator."
"    ""-help"": Display instructions for how to use cceBootstrap."
" "
"    See also: cceStatus, cceStop, cceRestart."
];        
end