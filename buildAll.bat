@echo off
echo Bootstrapping ST Build...
rebuild src\stmanage\stbuild\main -oqobj\release -ofbin\stbuild_bootstrap -Isrc -release -C-O
move *.map obj\release > _junk_.junk 2> _junk_.junk2
del /Q _junk_.junk
del /Q _junk_.junk2
bin\stbuild_bootstrap all clean
bin\stbuild_bootstrap all release
bin\stbuild_bootstrap all debug

del /Q bin\stbuild_bootstrap.exe 2> _junk_.junk
del /Q _junk_.junk