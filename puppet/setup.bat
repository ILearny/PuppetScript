@echo off

set current-dir=%~dp0
set current-dir=%~n0


set environment=%1
set asset=%2


if %environment%.==. (
  goto help
)
if %asset%.==. (
  goto help
)

if not %asset% == FRONT (
	if not %asset% == BATCH (
		if not %asset% == ALL (
			goto help
		)
	)
)

setlocal enabledelayedexpansion


Rem ---------------------------------
Rem Download dependencies 
Rem ---------------------------------

if not exist "%current-dir%resources" (
	mkdir "%current-dir%resources"
)


Rem ---------------------------------
Rem Install Puppet extra modules
Rem ---------------------------------

cmd /Q /C puppet module install  puppetlabs/stdlib --ignore-dependencies
if not "!ERRORLEVEL!" == "0" (
	echo Module install failled
	exit /B 1
)

Rem ---------------------------------
Rem Execute puppet manifest
Rem ---------------------------------

set FACTER_asset=%asset%

cmd /Q /C puppet apply --modulepath C:/ProgramData/PuppetLabs/puppet/etc/modules;%current-dir%modules --confdir=%current-dir% --environment=%environment% %current-dir%manifests\site.pp
if not "!ERRORLEVEL!" == "0" (
	echo Tomcat set-up failled
	exit /B 1
)


echo Set-up succeeded

:help
  echo !!! Syntax error: environment must be specified !!!
  exit /B1
  
