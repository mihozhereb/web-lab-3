@echo off
setlocal

set "ANT_HOME=%~dp0apache-ant"
set "PATH=%ANT_HOME%\bin;%PATH%"

call "%ANT_HOME%\bin\ant.bat" %*