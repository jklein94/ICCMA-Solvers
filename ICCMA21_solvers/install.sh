#!/bin/bash
# INSTALLING ICCMA21 solvers
# Check if unzip is installed
REQUIRED_PKG="unzip"
PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PKG|grep "install ok installed")
echo -n Checking for $REQUIRED_PKG:
if [ "" = "$PKG_OK" ]; then
  echo " No $REQUIRED_PKG. Setting up $REQUIRED_PKG."
  sudo apt-get --yes install $REQUIRED_PKG

else
    echo " Installed."
fi

# Check gcc version
current_version="$(gcc -dumpversion)"
required_version="10"
 if [ "$current_version" != "$required_version" ]; then
    echo "Installing required compiler versions"
    sudo apt --yes install g++-$required_version gcc-$required_version
    sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-$required_version 10
    sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-$required_version 10
 fi

# ArgSemSat Installation
echo "Installing mu-toksia"
if [ -f "./mu-toksia/mu-toksia" ]; then
    echo "Mu-Toksia is already installed."
else
    mu_toksia_archive_name='andreasniskanen-mu-toksia-a56fe626fa87.zip'
    unzip "$mu_toksia_archive_name" && mv "andreasniskanen-mu-toksia-a56fe626fa87" "mu-toksia"
    cd "mu-toksia" || exit
    ./build.sh
    probo2 add-solver -n mu-toksia --version ICCMA21 -p ./mu-toksia --guess --yes
    echo "Done installing mu-toksia!"
    cd ..
fi



echo "Installing MatrixX"
if [ -f "./MatrixX-main/matrixx.sh" ]; then
    echo "MatrixX is already installed."
else
    matrixx_archive_name='MatrixX-main.zip'
    unzip "$matrixx_archive_name"
    cd "MatrixX-main" || exit
    mv "matrixx" "matrixx.sh"
    probo2 add-solver -n mu-MatrixX --version ICCMA21 -p ./matrixx.sh --guess --yes
    echo "Done installing MatrixX!"
    cd ..

fi



echo "Installing ConArg"
if [ -f "./conarg/ProboInterface.sh" ]; then
    echo "ConArg is already installed."
else
    mkdir "conarg"
    conarg_archive_name='conarg_x64.tgz'
    tar -xvf $conarg_archive_name -C ./conarg
    cd "conarg" || exit
    probo2 add-solver -n ConArg --version ICCMA21 -p ./ProboInterface.sh --guess --yes
    echo "Done installing ConArg!"
    cd ..

fi


echo "Installing Pyglaf"
if [ -f "./Pyglaf/pyglaf.py" ]; then
    echo "Pyglaf is already installed."
else

    pyglaf_archive_name='pyglaf-iccma2021.zip'
    unzip $pyglaf_archive_name && mv "ICCMA21" "pyglaf"
    cd "pyglaf" || exit
    probo2 add-solver -n Pyglaf --version ICCMA21 -p ./pyglaf.py --guess --yes
    echo "Done installing Pyglaf!"
    cd ..

fi


echo "Installing Harper"
if [ -f "./taas-harper-main/taas-harper" ]; then
    echo "Harper is already installed."
else
    harper_archive_name='taas-harper-main.zip'
    unzip "$harper_archive_name"
    cd "taas-harper-main" || exit
    sudo apt install libglib2.0-dev
    sudo update
    gcc taas-harper.c $(pkg-config --cflags --libs glib-2.0) -o taas-harper
    probo2 add-solver -n Harper --version ICCMA21 -p ./taas-harper --guess --yes
    echo "Done installing Harper!"
    cd ..

fi



echo "Installing A-Folio-DPDB"
if [ -f "./A-Folio-DPDB/solver.sh" ]; then
    echo "A-Folio-DPDB is already installed."
else

    a_folio_archive_name='dp_on_dbs-competition.zip'
    unzip "$a_folio_archive_name" && mv "dp_on_dbs-competition" "A-Folio-DPDB"
    cd "A-Folio-DPDB" || exit
    bash build.sh
    probo2 add-solver -n A-Folio-DPDB --version ICCMA21 -p ./solver.sh --guess --yes
    echo "Done installing A-Folio-DPDB!"
    cd ..

fi



echo "Installing Aspartix-V"
if [ -f "./aspartix-v-2021-2/aspartix-V-interface.sh" ]; then
    echo "Aspartix-V is already installed."
else

    aspartix_archive_name='aspartix-v-2021-2.zip'
    unzip "$aspartix_archive_name"
    cd "aspartix-v-2021-2" || exit
    sudo chmod +x clingo
    sudo chmod +x clingo440
    probo2 add-solver -n ASPARTIX-V --version ICCMA21 -p./aspartix-V-interface.sh -f apx --guess --yes
    echo "Done installing Aspartix-V!"
    cd ..

fi

echo "Installing Fudge"
if [ -f "./taas-fudge-main/taas-fudge" ]; then
    echo "Fudge is already installed."
else
    fudge_archive_name='taas-fudge-main.zip'
    unzip "$fudge_archive_name"
    cd "taas-fudge-main" || exit
    sudo apt install libglib2.0-dev
    sudo update
    bash build-taas-fudge.sh
    probo2 add-solver -n Fudge --version ICCMA21 -p ./taas-fudge --guess --yes
    echo "Done installing Fudge!"

fi