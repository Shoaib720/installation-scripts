#!/bin/bash

verify_prometheus_installation {
    prometheus --version 2>/dev/null && promtool --version 2>/dev/null >/dev/null
    if [ "$?" -ne "0" ]
    then
        echo "An unkown error occured!"
        echo "Exiting with code 1"
        exit 1
    fi
}

install_prometheus{
    apt update -y
    adduser prometheus
    mkdir /etc/prometheus
    mkdir /var/lib/prometheus
    chown prometheus:prometheus /etc/prometheus
    chown prometheus:prometheus /var/lib/prometheus
    cd /opt/
    read -p "Enter prometheus file URL: " FILE_URL
    FILE_NAME=`basename $FILE_URL`
    wget $FILE_URL
    tar xvf $FILE_NAME
    cp /opt/${FILE_NAME}/{prometheus,promtool} /usr/local/bin/
    chown prometheus:prometheus /usr/local/bin/{prometheus,promtool}
    cp -r /opt/${FILE_NAME}/{consoles,console_libraries,prometheus.yml} /etc/prometheus
    chown -R prometheus:prometheus /etc/prometheus/{consoles,console_libraries,prometheus.yml}
    verify_prometheus_installation
}

create_systemd_file {
    LOCATION="/etc/systemd/system/prometheus.service"
    touch $LOCATION
    printf "[Unit]\n" > $LOCATION
    printf "Description=Prometheus\n" >> $LOCATION
    printf "Wants=network-online.target\n" >> $LOCATION
    printf "After=network-online.target\n\n" >> $LOCATION
    printf "[Service]\n" >> $LOCATION
    printf "User=prometheus\n" >> $LOCATION
    printf "Group=prometheus\n" >> $LOCATION
    printf "Type=simple\n" >> $LOCATION
    printf "ExecStart=/usr/local/bin/prometheus \\" >> $LOCATION
    printf "\n--config.file /etc/prometheus/prometheus.yml \\" >> $LOCATION
    printf "\n--storage.tsdb.path /var/lib/prometheus/ \\" >> $LOCATION
    printf "\n--web.console.templates=/etc/prometheus/consoles \\" >> $LOCATION
    printf "\n--web.console.libraries=/etc/prometheus/console_libraries\n\n" >> $LOCATION
    printf "[Install]\n" >> $LOCATION
    printf "WantedBy=multi-user.target\n" >> $LOCATION
}

if [ $(id -u) -ne "0" ]
then
    echo "This script needs root privileges."
else
    echo "Installing prometheus..."
    install_prometheus
    echo "Installation completed."
    echo "Creating Prometheus Systemd file"
    create_systemd_file
    echo "Systemd file created."
    echo "Reloading daemon..."
    systemctl daemon-reload
    echo "Starting prometheus..."
    systemctl start prometheus
    echo "Enabling prometheus..."
    systemctl enable prometheus
    echo
    echo
    echo "Installtion & configuration completed."
    echo "Don't forget to allow in Firewall!"
fi
