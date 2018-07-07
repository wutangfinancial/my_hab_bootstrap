#/bin/bash

# this script needs to be run via sudo or many functions will not work!

# globals
HAB_VERSION="0.58.0"
# HAB 0.58.0 stable depends on cacerts 2017.09.20/20171014212239
CACERTS_VERSION="2017.09.2"
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
    # SysV Init (not fully tested)
    #     # create the hab user
    #     useradd hab
    #     # install hab-sup service
    #     curl https://raw.githubusercontent.com/wutangfinancial/my_hab_bootstrap/master/hab-sup-initscript -o /etc/init.d/hab-sup
    #     chmod 755 /etc/init.d/hab-sup

    #     # start the supervisor at boot
    #     /sbin/chkconfig hab-sup on
    #     /sbin/service hab-sup start
    
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
        systemctl start hab-sup.service
    fi
}

function main {
    package_install tcpdump
    
    yum -y update
    
    install_hab
    export HAB_ORIGIN="wutangfinancial"
    echo "HAB_ORIGIN: $HAB_ORIGIN"
    hab pkg install core/hab-sup/$HAB_VERSION -c stable

    add_hab_service
    
}
    
main | tee -a /tmp/my_hab_bootstrap.log

