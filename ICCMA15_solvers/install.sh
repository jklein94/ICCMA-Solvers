#!/bin/bash

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
required_version="4.9.3"
 if [ "$current_version" != "$required_version" ]; then
    echo "Installing required compiler versions"
    echo "deb http://dk.archive.ubuntu.com/ubuntu/ xenial main" | sudo tee -a /etc/apt/sources.list
    echo "deb http://dk.archive.ubuntu.com/ubuntu/ xenial universe" | sudo tee -a /etc/apt/sources.list
    sudo apt update
    sudo apt --yes install g++-4.9 gcc-4.9
    sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.9 4
    sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.9 4
 fi

# ArgSemSat Installation
echo "Installing ArgSemSAT"
if [ -f "./ArgSemSAT_1.0rc2/ArgSemSAT" ]; then
    echo "ArgSemSAT is already installed."
else
    argsemsat_archive_name='2 ArgSemSAT.zip'
    unzip "$argsemsat_archive_name"
    cd "ArgSemSAT_1.0rc2" || exit
    ./build
    echo "Done installing ArgSemSAT!"
    probo2 add-solver -n ArgSemSAT --version ICCMA15 -p ./ArgSemSAT --guess

fi

cd ..

