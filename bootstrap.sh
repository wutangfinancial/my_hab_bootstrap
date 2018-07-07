#/bin/bash

function install_hab {
    curl https://raw.githubusercontent.com/habitat-sh/habitat/master/components/hab/install.sh | sudo bash
}

function package_install {
    local package=${1}

    # first check if the package is installed
    if rpm -q ${package} > /dev/null; then
        true
    else
        sudo yum install ${package}
    fi
}

function add_service {
    # install hab-sup service
    if [[ ! -f /etc/systemd/system/hab-sup.service ]]; then
        cat << EOF > /etc/systemd/system/hab-sup.service
[Unit]
Description=Habitat Supervisor
[Service]
ExecStartPre=/bin/bash -c "/bin/systemctl set-environment SSL_CERT_FILE=/hab/pkgs/core/cacerts/2017.09.20/20171014212239/ssl/$
ExecStart=/bin/hab run
[Install]
WantedBy=default.target
EOF

        # start the supervisor
        systemctl daemon-reload
        systemctl daemon-reexec
        /sbin/chkconfig hab-sup on
        /sbin/service hab-sup start
    fi
}

function main {
    install_hab

    #export HAB_BLDR_URL="http://ito000604.fhc.ford.com"
    #echo "HAB_BLDR_URL: $HAB_BLDR_URL"

    package_install tcpdump

    echo "Installing the hab-sup package... "
    hab pkg install core/hab-sup/$HAB_VERSION -c stable

    add_service
    
}
    
main | tee -a /tmp/my_hab_bootstrap.log
