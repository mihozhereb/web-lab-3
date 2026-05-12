@echo off
chcp 65001 > nul
setlocal

set "ANT_HOME=%~dp0apache-ant"
set "PATH=%ANT_HOME%\bin;%PATH%"

set "ANT_OPTS=-Dfile.encoding=UTF-8 -Dsun.stdout.encoding=UTF-8 -Dsun.stderr.encoding=UTF-8 %ANT_OPTS%"

call "%ANT_HOME%\bin\ant.bat" %*