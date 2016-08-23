@ECHO OFF

REM Network share double-clickable runner of InstallModules.ps1

SETLOCAL

SET ScriptDir=%~dp0
SET PSDir=%windir%\System32\WindowsPowerShell\v1.0

IF NOT EXIST "%PSDir%" (
  ECHO PowerShell directory doesn't exist. Cannot continue.
  PAUSE
  GOTO :End
)

COPY %ScriptDir%InstallModules.ps1 %TMP%

SET PSCmd=^" -ModuleSource '%ScriptDir%'
"%PSDir%\powershell.exe" -ExecutionPolicy RemoteSigned -Command ^"%TMP%\InstallModules.ps1 -ModuleSource '%ScriptDir%'^"

IF /I "%1" NEQ "/Q" PAUSE

:End
ENDLOCAL
