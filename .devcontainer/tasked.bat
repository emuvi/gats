@echo off
call clean.bat
call begin.bat
docker exec qin_con_qif_gats bash -c "cd /workspaces/qif_gats && ./run-sensitive.sh"