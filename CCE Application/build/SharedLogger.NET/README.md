# SharedLogger.NET

Implementation of SharedLogger class in .NET

## Use as a client
If you'd like to just use the SharedLogger class, add this project as a sub-module and exclude everything but the DLL from your archive process.

## Building SharedLogger - Visual Studio Installer Extension
To build SharedLogger.NET and create an installer MSI for this, you must add the Microsoft Visual Studio Installer Projects extension relevant to your version of Visual Studio. TO do this, open the project, then got to Extensions, Manage Extensions and search for "Microsoft Visual Studio Installer". Once you install the extension, reload the SetupCCELogger project.

## TODO's
+ Remove the SetupCCELogger and put it into the CCE repo
+ Add the path environment variable option, as is done for MATLAB's SharedLogger.
