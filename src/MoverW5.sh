#!/bin/bash

# Funcion que copia archivos contemplando la posibilidad de archivos duplicados, asignandoles un numero de secuencia.

function moverW5 {

	if [ $# -lt 2 ]
	then
		
		${BINDIR}/LoguearW5.sh $3 "E" "Error al mover. Argumentos Insuficientes"
		echo "Argumentos insuficientes" 1>&2
		return 1
	else
		if [ -e $1 ]
		then
			if [ -d $2 ]
			then
				SEC=$(ls $2 | grep $(basename $1) | cut -d. -f3 | tail -1)
				((SEC++))

				NEWPATH=$2"/"$(basename $1)"."$SEC
				cp $1 $NEWPATH

				# GUARDO EN EL ARCHIVO DE LOG
				${BINDIR}/LoguearW5.sh $3 "I" "Copiado $1 a $2"
				return 0
			else
				
				${BINDIR}/LoguearW5.sh $3 "E" "Error al mover. No existe el directorio $2"
				echo "No existe el directorio $2" 1>&2
				return 1
			fi
		else
			${BINDIR}/LoguearW5.sh $3 "E" "Error al mover. No existe el archivo $1"
			echo "No existe el archivo $1" 1>&2
			return 1
		fi

	fi
}

ORIGEN=$1
DESTINO=$2
COMANDO=$3
moverW5 $ORIGEN $DESTINO $COMANDO
RET=$?

exit $RET
