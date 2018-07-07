#/bin/bash

# this script needs to be run via sudo or many functions will not work!

# globals
HAB_VERSION="0.57.0"
HAB_LAUNCHER_VERSION="7797"

function package_install {
    local package=${1}

    # first check if the package is installed
    if rpm -q ${package} > /dev/null; then
        true
    else
        sudo yum -y install ${package}
    fi
}

function install_hab {
    curl https://raw.githubusercontent.com/habitat-sh/habitat/master/components/hab/install.sh | bash
}

function add_hab_service {
    # install hab-sup service
    curl -x https://raw.githubusercontent.com/wutangfinancial/my_hab_bootstrap/master/hap-sup-initscript -o /etc/init.d/hap-sup
    chmod 755 /etc/init.d/hap-sup

    # start the supervisor at boot
    /sbin/chkconfig hab-sup on
    /sbin/service hab-sup start
}

function main {
    package_install tcpdump
    
    yum -y update
    
    install_hab
    export HAB_ORIGIN="wutangfinancial"
    echo "HAB_ORIGIN: $HAB_ORIGIN"
    hab pkg install core/hab-sup/$HAB_VERSION -c stable
    hab pkg install core/hab-launcher/$HAB_LAUNCHER_VERSION -c stable
    add_hab_service
    
}
    
main | tee -a /tmp/my_hab_bootstrap.log

