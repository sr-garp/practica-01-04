#!/bin/bash

if dpkg -s apache2 &> /dev/null; then
    echo "Apache2 ya está instalado en el sistema. Saliendo sin realizar cambios..."
    exit 0
fi

echo "Apache2 no detectado. Iniciando instalación..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y apache2

systemctl enable apache2
systemctl start apache2

echo "Apache2 instalado, habilitado y en ejecución."
