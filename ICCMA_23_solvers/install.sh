#!/bin/bash
# INSTALLING ICCMA23 solvers
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

# Check if Rust is installed
if command -v rustc &>/dev/null; then
    echo "Rust is already installed."
else
    # Install Rust using rustup
    echo "Rust is not installed. Installing..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    source $HOME/.cargo/env
    echo "Rust has been installed."
fi


# mu-toksia Installation
echo "Installing mu-toksia"
if [ -f "./mu-toksia-crypto/build/release/bin/mu-toksia" ]; then
    echo "Mu-Toksia is already installed."
else
    mu_toksia_archive_name='mu-toksia.zip'
    unzip "$mu_toksia_archive_name"
    # Step 1: Create a copy of directory "mu_toksia" as "mu_toksia_glucose"
    cp -r mu-toksia mu-toksia-glucose

    # Step 2: Rename directory "mu_toksia" to "mu_toksia_crypto"
    mv mu-toksia mu-toksia-crypto
    cd "mu-toksia-glucose" || exit
    SAT_SOLVER=glucose make
    probo2 add-solver -n mu-toksia-glucose --version ICCMA23 -p ./build/release/bin/mu-toksia -ft --yes -f apx -f tgf -f i23
    echo "Done installing mu-toksia-glucose!"
    cd ..

    cd "mu-toksia-crypto" || exit
    SAT_SOLVER=cryptominisat make
    probo2 add-solver -n mu-toksia-crypto --version ICCMA23 -p ./build/release/bin/mu-toksia -ft --yes -f apx -f tgf -f i23
    echo "Done installing mu-toksia-crypto!"
    cd ..

fi



echo "Installing crustabri"
if [ -f "./crustabri/crustabri/target/release/crustabri_iccma23" ]; then
    echo "crustabri is already installed."
else
    crustabri_archive_name='crustabri.zip'
    unzip "$crustabri_archive_name"
    cd "crustabri/crustabri" || exit
    cargo build --release
    probo2 add-solver -n crustabri --version ICCMA23 -p ./target/release/crustabri_iccma23 -ft --yes -f i23
    echo "Done installing crustabri!"
    cd ..
    cd ..
fi


echo "Installing Fudge"
if [ -f "./fudge_v3.2.8/src/taas-fudge" ]; then
    echo "Fudge is already installed."
else
    fudge_archive_name='fudge.zip'
    unzip "$fudge_archive_name"
    cd "fudge_v3.2.8/src" || exit
    sudo apt install libglib2.0-dev
    sudo update
    bash build-taas-fudge.sh
    probo2 add-solver -n Fudge --version ICCMA23 -p ./taas-fudge -ft --yes -f i23 -f tgf
    echo "Done installing Fudge!"
    cd ..
    cd ..
fi

echo "Installing PORTSAT"
if [ -f "./PORTSAT/target/release/portsat " ]; then
    echo "PORTSAT is already installed."
else
    portsat_archive_name='portsat.zip'
    unzip "$portsat_archive_name"
    cd "PORTSAT" || exit
    make
    probo2 add-solver -n PORTSAT --version ICCMA23 -p ./target/release/portsat -ft --yes -f i23
    echo "Done installing PORTSAT!"
    cd ..
   
fi
