#!/bin/bash
set -e

if ! dpkg -s apache2 &> /dev/null; then
    echo "ERROR: Apache2 no está instalado. Ejecuta primero: sudo ./scripts/install_apache.sh"
    exit 1
fi

DIR_SCRIPT="$(cd "$(dirname "${BASH_SOURCE}")" && pwd)"
ENV_FILE="$DIR_SCRIPT/.env"

if [ ! -f "$ENV_FILE" ]; then
    echo "ERROR: No se encuentra el archivo $ENV_FILE. Cópialo desde .env.example."
    exit 1
fi

source "$ENV_FILE"

echo "Generando certificado autofirmado para $DOMINIO ($IP_ELASTICA)..."
mkdir -p "$(dirname "$RUTA_CERT")" "$(dirname "$RUTA_KEY")"

openssl req -x509 -nodes -days "$DIAS_VALIDEZ" -newkey rsa:2048 \
    -keyout "$RUTA_KEY" \
    -out "$RUTA_CERT" \
    -subj "/C=$CERT_C/ST=$CERT_ST/L=$CERT_L/O=$CERT_O/OU=$CERT_OU/CN=$CERT_CN/emailAddress=$CERT_EMAIL" \
    -addext "subjectAltName=DNS:$DOMINIO,IP:$IP_ELASTICA"

chmod 600 "$RUTA_KEY"

echo "Configurando VirtualHosts en Apache..."
REPO_ROOT="$(dirname "$DIR_SCRIPT")"
cp "$REPO_ROOT/conf/000-default.conf" /etc/apache2/sites-available/000-default.conf
cp "$REPO_ROOT/conf/practica-https-ssl.conf" /etc/apache2/sites-available/practica-https-ssl.conf

sed -i "s/__DOMINIO__/$DOMINIO/g" /etc/apache2/sites-available/000-default.conf
sed -i "s/__DOMINIO__/$DOMINIO/g" /etc/apache2/sites-available/practica-https-ssl.conf

echo "Habilitando módulos SSL, Rewrite y sitio HTTPS..."
a2enmod ssl
a2enmod rewrite
a2ensite practica-https-ssl.conf

echo "Validando sintaxis de configuración..."
if apache2ctl configtest; then
    echo "Sintaxis correcta. Reiniciando Apache..."
    systemctl restart apache2
    echo "¡Despliegue completado con éxito!"
else
    echo "ERROR: Fallo en la sintaxis de Apache. No se reinició el servicio."
    exit 1
fi
