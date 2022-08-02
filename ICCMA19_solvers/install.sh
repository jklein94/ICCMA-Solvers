#!/bin/bash
#Install ICCMA19 solvers

cd yonas || exit
probo2 add-solver -n yonas -v ICCMA19 -p ./generic-interface-2019.sh --guess --yes --no_check
cd ..

cd EqArgSolver || exit
sudo chmod +x eqargsolver-2.78
probo2 add-solver -n EqArgSolver -v ICCMA19 -p ./eqargsolver-2.78 --guess --yes
cd ..

cd argpref || exit
probo2 add-solver -n Argpref -v ICCMA19 -p ./generic-interface-2019.sh --guess --yes
cd ..

cd aspartix || exit
sudo chmod +x clingo
sudo chmod +x clingo440
sudo chmod +x query.lp
probo2 add-solver -n ASPARTIX-V19 -v ICCMA19 -p ./aspartix-V-interface-2019.sh --guess --yes
cd ..

cd mu-toksia || exit
sudo chmod +x mu-toksia
probo2 add-solver -n mu-toksia -v ICCMA19 -p ./mu-toksia --guess --yes
cd ..

cd pyglaf || exit
sudo chmod +x circumscriptino-static
probo2 add-solver -n pyglaf -v ICCMA19 -p ./pyglaf.py --guess --yes
cd ..

cd taas-dredd || exit
sudo chmod +x taas-dredd
probo2 add-solver -n DREDD -v ICCMA19 -p ./taas-dredd --guess --yes