#!/bin/sh

. $(dirname $(readlink -f "$0"))/_lib/auxiliar.sh

CALLA=$1

lista_paquetes()
{
    echo "postgresql-$1 postgresql-client-$1 postgresql-contrib-$1"
}

VER=10

LIST=/etc/apt/sources.list.d/pgdg.list
if [ ! -f $LIST ]; then
    mensaje "Activando el repositorio de PostgreSQL..."
    echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -sc)-pgdg main" | sudo tee $LIST > /dev/null
    if ! apt-key list | grep -qs ACCC4CF8; then
        wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
    fi
    sudo apt update
else
    mensaje "Repositorio de PostgreSQL ya activado."
fi

mensaje "Instalando paquetes de PostgreSQL..."
P=$(lista_paquetes $VER)
echo "\033[1;32m\$\033[0m\033[35m sudo apt -y install $P\033[0m"
sudo apt -y install $P

CONF="/etc/postgresql/$VER/main/postgresql.conf"
asigna_param_postgresql "intervalstyle" "'iso_8601'" $CONF
asigna_param_postgresql "timezone" "'UTC'" $CONF
asigna_param_postgresql "lc_messages" "'en_US.UTF-8'" $CONF
asigna_param_postgresql "lc_monetary" "'en_US.UTF-8'" $CONF
asigna_param_postgresql "lc_numeric" "'en_US.UTF-8'" $CONF
asigna_param_postgresql "lc_time" "'en_US.UTF-8'" $CONF
asigna_param_postgresql "default_text_search_config" "'pg_catalog.english'" $CONF

for V in 9.6 10; do
    if [ "$V" != "$VER" ]; then
        if [ -d /etc/postgresql/$V ]; then
            mensaje "Se ha detectado la versión $V anterior."
            pregunta SN "¿Migrar los datos a la versión $VER y desinstalar?" S $CALLA
            if [ "$SN" = "S" ]; then
                sudo service postgresql stop
                mensaje "Eliminando clúster main de la versión $VER..."
                sudo pg_dropcluster --stop $VER main
                mensaje "Migrando clúster main a la versión $VER..."
                sudo pg_upgradecluster -m upgrade $V main
            fi
            pregunta SN "¿Desinstalar la versión $V anterior?" S $CALLA
            if [ "$SN" = "S" ]; then
                P=$(lista_paquetes $V)
            fi
            echo "\033[1;32m\$\033[0m\033[35m sudo apt -y --purge remove $P\033[0m"
            sudo apt -y --purge remove $P
        fi
    fi
done

mensaje "Reiniciando PostgreSQL..."
sudo service postgresql restart
