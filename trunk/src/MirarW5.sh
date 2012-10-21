#!/bin/bash

# Funcion para ver de forma amigable los logs

function mirarW5 {

if [[ ! $LOGDIR ]] ; then
echo "Variable LOGDIR no definida"
return 1
fi

if [[ ! $LOGEXT ]] ; then
echo "Variable LOGEXT no definida"
return 1
fi

COMANDO=$BASH_ARGV     # Comprobar solo Bash >= 3.0
ARCH=$LOGDIR"/"$COMANDO$LOGEXT
NLINES=
FIND=
ONLY=

while getopts “g:n:o:0123456789” OPTION
do
	case $OPTION in
		g)
		FIND=$OPTARG
		;;
		n)
		if [[ $OPTARG =~ ^[0-9]+$ ]] && [[ ! $LINES ]];
		then
			NLINES=$OPTARG
		else
			echo "Numero de lineas no valido"
			return 1
		fi
		;;
		o)
		ONLY=$OPTARG
		;;
		[0-9])
		NLINES=$NLINES$OPTION
		;;
		?)
		return 1
		;;
	esac
done

if [[ $NLINES ]] ;
then

IFS=$'\n'
for LINE in $(tail -n$NLINES $ARCH | grep ""$FIND); do
	FECHA=$(echo $LINE | cut -d"-" -f1 | cut -d" " -f1)
	HORA=$(echo $LINE | cut -d"-" -f1 | cut -d" " -f2)
	USUARIO=$(echo $LINE | cut -d"-" -f2)
	COMANDO=$(echo $LINE | cut -d"-" -f3)
	TIPO=$(echo $LINE | cut -d"-" -f4)
	MOTIVO=$(echo $LINE | cut -d"-" -f5)
	
	if [[ ! $ONLY ]] || [[ $ONLY = $TIPO ]] ; then
	echo "FECHA: $FECHA	HORA: $HORA"
	echo "	USUARIO: $USUARIO"
	echo "	COMANDO: $COMANDO"
	echo "	TIPO DE MENSAJE: $TIPO"
	echo "	MOTIVO: $MOTIVO"
	echo
	fi
done

else

IFS=$'\n'
for LINE in $(cat $ARCH | grep ""$FIND); do
	FECHA=$(echo $LINE | cut -d"-" -f1 | cut -d" " -f1)
	HORA=$(echo $LINE | cut -d"-" -f1 | cut -d" " -f2)
	USUARIO=$(echo $LINE | cut -d"-" -f2)
	COMANDO=$(echo $LINE | cut -d"-" -f3)
	TIPO=$(echo $LINE | cut -d"-" -f4)
	MOTIVO=$(echo $LINE | cut -d"-" -f5)

	if [[ ! $ONLY ]] || [[ $ONLY = $TIPO ]] ; then
	echo "FECHA: $FECHA	HORA: $HORA"
	echo "	USUARIO: $USUARIO"
	echo "	COMANDO: $COMANDO"
	echo "	TIPO DE MENSAJE: $TIPO"
	echo "	MOTIVO: $MOTIVO"
	echo
	fi
done

fi
return 0
}


mirarW5 $1 $2 $3 $4
