#!/bin/bash
#Comando InstalaW5

##########################################
##            FUNCIONES                 ##
##########################################

#Si Perl 5 o superior esta instalado imprime 
#version y retorna 0, sino retorna 1
function ChequearPerl {	
	perl -v >/dev/null 2>&1
	VPERL=$?
	#Si no devuelve 0 no esta instalado
	if [ $VPERL==0 ]; then
		#Obtengo la version
		VPERL=$(perl -v | grep -o -m1 '(v.*)' | cut -d'v' -f2 | cut -d')' -f1)
		if [ ${VPERL:0:1} -ge 5 ]; then
			echo "Perl Version: $VPERL"
			return;
		fi
	fi
	echo "Para instalar el TP es necesario contar con Perl 5 o superior instalado. Efectue su instalacion e intentelo nuevamente\n"
	echo "Proceso de Instalacion Cancelado"
	exit 1;
}

#Define el directorio en la variable pasada como segundo
#parametro, el primer parametro es el mensaje a mostrarse,
#el tercero el directorio default
function DefinirDirectorio {
	local linea
	if [ -n ${!2} ]; then
		eval "$2=$GRUPO$3"
	fi
	echo "${!1} (${!2}): "
	read linea
	if [ "$linea" != "" ]; then
		echo "$linea"
		if [[ $linea == /* ]]; then
			eval "$2=$GRUPO$linea"	#uso eval para hacer doble dereferenciacion
		else
			eval "$2=$GRUPO/$linea"
		fi
	fi
}

function DefinirDataSize {
	echo "Defina el espacio mínimo libre para el arribo de archivos externos en MBytes ($DATASIZE):"
	read linea
	if [ "$linea" != "" ]; then
		DATASIZE=$linea
	fi
	ARRIDIRTEMP=$ARRIDIR
	while test ! -e $ARRIDIRTEMP; do
		ARRIDIRTEMP=$(dirname $ARRIDIRTEMP)
	done
	ESPACIOLIBRE=0
	while [ $ESPACIOLIBRE -lt $DATASIZE ]; do
		ESPACIOLIBRE=$(df -k $ARRIDIRTEMP | awk 'NR == 2 {print $4}')
		if [ $ESPACIOLIBRE -lt $DATASIZE ]; then
			echo "Insuficiente espacio en disco."
			echo "Espacio disponible: $ESPACIOLIBRE Mb."
			echo "Espacio requerido $DATASIZE Mb."
			echo "Cancele la instalación e inténtelo más tarde o vuelva a intentarlo con otro valor."
		fi
	done
}

function CrearDirectorio {
	if [ ! -d $1 ]; then 
		echo "$1"
		mkdir -m777 $1
	fi
}
############################################
##             COMIENZO                   ##
############################################

GRUPO=$PWD
CONFDIR=$GRUPO/confdir
CONFARCH=$CONFDIR/InstalaW5.conf
#Compruebo que exista el directorio de configuracion
#Si no existe, lo creo
if [ ! -d $CONFDIR ]; then
	mkdir -m777 $CONFDIR
fi
#Si no existe el archivo de configuración quiere decir
#que no se instalo nunca

#Chequeo que este instalado Perl
ChequearPerl
MSG="Defina el directorio de grabación de los ejecutables"
#BINDIR=$GRUPO/bin
DefinirDirectorio MSG BINDIR /bin
MSG="Defina el directorio de instalación de los archivos maestros"
#MAEDIR=$GRUPO/mae
DefinirDirectorio MSG MAEDIR /mae
while [ "$RESPUESTA" != "Si" ]
do
	MSG="Defina el directorio de grabación de archivos externos"
	#ARRIDIR=$GRUPO/arribos
	DefinirDirectorio MSG ARRIDIR /arribos
	DATASIZE=100
	DefinirDataSize		#revisar linea del dirname
	MSG="Defina el directorio de grabación de los archivos externos rechazados"
	#RECHDIR=$GRUPO/rechazados
	DefinirDirectorio MSG RECHDIR /rechazados
	MSG="Defina el directorio de grabación de los archivos externos aceptados"
	#ACEPDIR=$GRUPO/aceptados
	DefinirDirectorio MSG ACEPDIR /aceptados
	MSG="Defina el directorio de grabación de los archivos procesados"
	#PROCDIR=$GRUPO/procesados
	DefinirDirectorio MSG PROCDIR /procesados
	LOGDIR=$GRUPO/log
	LOGEXT=.log
	LOGSIZE=400
	echo "Defina el tamaño máximo para los archivos $LOGEXT en Kbytes ($LOGSIZE): "
	read linea
	if [ "$linea" != "" ]; then
		LOGSIZE=$linea
	fi
	MSG="Defina el directorio de grabación de los reportes de salida"
	#REPODIR=$GRUPO/reportes
	DefinirDirectorio MSG REPODIR /reportes
	clear
	echo "Librería del Sistema: $CONFDIR"
	echo "Ejecutables: $BINDIR"
	echo "Archivos maestros: $MAEDIR"
	echo "Directorio de arribo de archivos externos: $ARRIDIR"
	echo "Espacio mínimo libre para arribos: $DATASIZE Mb"
	echo "Archivos externos aceptados: $ACEPDIR"
	echo "Archivos externos rechazados: $RECHDIR"
	echo "Archivos procesados: $PROCDIR"
	echo "Reportes de salida: $REPODIR"
	echo "Logs de auditoria del Sistema: $LOGDIR/<comando>$LOGEXT"
	echo "Tamaño máximo para los archivos del log del sistema: $LOGSIZE Kb"
	echo "Estado de la instalacion: LISTA"
	while [ "$RESPUESTA" != "Si" -a "$RESPUESTA" != "No" ]
	do
		echo "Los datos ingresados son correctos? (Si-No)"
		read RESPUESTA
	done

	if [ "$RESPUESTA" = "No" ]; then
		RESPUESTA=
		clear
	fi
done
RESPUESTA=
while [ "$RESPUESTA" != "Si" -a "$RESPUESTA" != "No" ]
do
	echo "Iniciando Instalación. Esta Ud seguro? (Si-No)"
	read RESPUESTA
done
if [ "$RESPUESTA" = "No" ]; then
	#cerrar archivo log
	exit 2
fi


echo "Creando Estructura de directorio. . . ."
CrearDirectorio $BINDIR
CrearDirectorio $MAEDIR
CrearDirectorio $ARRIDIR
CrearDirectorio $RECHDIR
CrearDirectorio $ACEPDIR
CrearDirectorio $PROCDIR
CrearDirectorio $LOGDIR
CrearDirectorio $REPODIR


echo "Instalando Archivos Maestros"
#Mover Archivos

echo "Instalando Programas y Funciones"
#Mover Archivos

echo "Actualizando la configuración del sistema"

