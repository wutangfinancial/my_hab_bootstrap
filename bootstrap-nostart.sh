#/bin/bash

# this script needs to be run via sudo or many functions will not work!

# globals
HAB_VERSION="0.59.0"
# hab-sup 0.59.0 stable transitive dependancy on cacerts 2017.09.20/20171014212239
CACERTS_VERSION="2017.09.20"
CACERTS_RELEASE="20171014212239"

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
    #SystemD Init
        # install hab-sup service
    if [[ ! -f /etc/systemd/system/hab-sup.service ]]; then
        cat << EOF > /etc/systemd/system/hab-sup.service
[Unit]
Description=Habitat Supervisor

[Service]
ExecStartPre=/bin/bash -c "/bin/systemctl set-environment SSL_CERT_FILE=/hab/pkgs/core/cacerts/$CACERTS_VERSION/$CACERTS_RELEASE/ssl/cert.pem"
ExecStart=/bin/hab run

[Install]
WantedBy=default.target
EOF

        # start the supervisor
        systemctl daemon-reload
        systemctl daemon-reexec
        systemctl enable hab-sup.service
        # systemctl start hab-sup.service
    fi
}

function main {
    package_install tcpdump
    package_install telnet
    
    yum -y update
    
    install_hab
    export HAB_ORIGIN="wutangfinancial"
    echo "HAB_ORIGIN: $HAB_ORIGIN"
    hab pkg install core/hab-sup/$HAB_VERSION -c stable

    add_hab_service
    
}
    
main | tee -a /tmp/my_hab_bootstrap.log
