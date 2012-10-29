#!/bin/bash
####################################################################################################
#Comando InstalaW5
####################################################################################################
#Realiza la Instalación del Sistema
#Si la instalación se ha realizado con anterioridad informa si la instalación está completa,
#y en caso que no lo esté completa la instalación con los parametros de instalación pasados
#en la instalación anterior.
#Todos los archivos de instalación necesarios ya sea para realizar una instalación nueva o para 
#completar una instalación anterior se deben encontrar en el mismo directorio en donde se encuentra 
#este archivo.
#Codigos de salida:
#		0: Normal
#		1: Falta Perl
#		2: Instalacion cancelada por el usuario
#		3: Faltan archivos para realizar la instalacion	
####################################################################################################
	
####################################################################################################
##                                          FUNCIONES                                             ##
####################################################################################################

#Si Perl 5 o superior esta instalado imprime 
#version y retorna 0, sino retorna 1
function ChequearPerl {	
	perl -v >/dev/null 2>&1
	VPERL=$?
	#Si no devuelve 0 no esta instalado
	if [ $VPERL==0 ]; then
		#Obtengo la version
		VPERL=$( perl -v | grep -o -m1 'v[0-9].[0-9]*.[0-9]*' )
		if [ ${VPERL:1:1} -ge 5 ]; then
			echo "Perl Version: $VPERL"
			return 0;
		fi
	fi
	Loguear "SE" "Para instalar el TP es necesario contar con Perl 5 o superior instalado. Efectue su instalacion e intentelo nuevamente" 0
	Loguear "SE" "Proceso de Instalacion Cancelado" 0
	return 1;
}

####################################################################################################

#Define el directorio en la variable pasada como segundo
#parametro, el primer parametro es el mensaje a mostrarse,
#el tercero el directorio default
function DefinirDirectorio {
	local linea


	eval $2="'$GRUPO/$3'"

	Loguear "I" "${!1} ($3): " 0
	read linea
	ChequearSalida $linea
	if [ "$linea" != "" ]; then
		Loguear "I" "El usuario ingresó: $linea" 1
		if [[ "$linea" = /* ]]; then
			eval ${2}="'$GRUPO$linea'"
		else
			eval ${2}="'$GRUPO/$linea'"
		fi
	else
		Loguear "I" "El usuario ingresó el valor por omisión: $3" 1
	fi

}

####################################################################################################

#Define el valor de DATASIZE, si el valor definido por el usuario es mayor
#al espacio libre, se le da la opción de ingresa un nuevo valor
#Retorna 0 si se definió el valor, 1 en caso contrario
function DefinirDataSize {
	ESPACIOLIBRE=0
	while [ $ESPACIOLIBRE -lt $DATASIZE ]; do
	Loguear "I" "Defina el espacio mínimo libre para el arribo de archivos externos en MBytes ($DATASIZE):" 0
	read linea
	ChequearSalida $linea
	if [ "$linea" != "" ]; then
		IsNumber $linea
		while [ ! $? -eq 0 ]
		do
			echo "Debe ingresar un numero entero. Por favor reingrese el valor:"
			read linea
			ChequearSalida $linea
			IsNumber $linea
		done
		Loguear "I" "El usuario ingresó: $linea" 1
		DATASIZE=$linea
	else
		Loguear "I" "El usuario ingresó el valor por omisión: $DATASIZE" 1
	fi
	ARRIDIRTEMP="$ARRIDIR"
	while test ! -e "$ARRIDIRTEMP"; do
		ARRIDIRTEMP=$(dirname "$ARRIDIRTEMP")
	done	
		ESPACIOLIBRE=$(df -k "$ARRIDIRTEMP" | awk 'NR == 2 {print $4}')
		if [ $ESPACIOLIBRE -lt $DATASIZE ]; then
			Loguear "A" "Insuficiente espacio en disco." 0
			Loguear "A" "Espacio disponible: $ESPACIOLIBRE Mb." 0
			Loguear "A" "Espacio requerido $DATASIZE Mb." 0
			Loguear "A" "Cancele la instalación e inténtelo más tarde o vuelva a intentarlo con otro valor." 0
			Loguear "I" "Desea ingresar otro valor? (Si-No)" 1
			while [ $linea!="Si" -a $linea!="No" ] 
			do
				echo "Desea ingresar otro valor? (Si-No)"
				read linea
				ChequearSalida $linea
			done
			if [ $linea="No" ]; then
				echo "Saliendo de la Instalación"
				Loguear "I" "Instalacion cancelada por el usuario" 1
				return 1
			else
				Loguear "I" "El usuario elegirá un nuevo valor para DATASIZE" 1
			fi
		fi
	done
	return 0
}

####################################################################################################

#Crea todos los directorios que no existan de las rutas pasadas como parametro
function CrearDirectorios {
	for i in "$@"
	do
		if [ ! -d "$i" ]; then 			
			mkdir -p -m777 "$i"
			Loguear "I" "	$i" 0
		fi
	done
}

####################################################################################################

#Imprime por salida estandar y en el archivo de log de instalación
#Parametros:
#		Parametro 1: Tipo de Mensaje
#		Parametro 2: Mensaje
#		Parametro 3: 0 para imprimir por stdout y loguear, 1 solo para loguear
function Loguear {
	if [ $3 -eq 0 ]; then	
		echo "$2"
	fi
	"$LOGW5/LoguearW5.sh" "InstalaW5" "$1" "$2"
}

#Guarda las variables de ambiente en el archivo de configuración
function GuardarVariables {
	usuario=$(whoami)
	fechaHora=$(date +"%d/%m/%y %I:%M%P")
	echo "GRUPO=$GRUPO=$usuario=$fechaHora" > "$CONFARCH"
	echo "CONFDIR=$CONFDIR=$usuario=$fechaHora" >> "$CONFARCH"
	echo "TEMPDIR=$TEMPDIR=$usuario=$fechaHora" >> "$CONFARCH"
	echo "BINDIR=$BINDIR=$usuario=$fechaHora" >> "$CONFARCH"
	echo "MAEDIR=$MAEDIR=$usuario=$fechaHora" >> "$CONFARCH"
	echo "ARRIDIR=$ARRIDIR=$usuario=$fechaHora" >> "$CONFARCH"
	echo "ACEPDIR=$ACEPDIR=$usuario=$fechaHora" >> "$CONFARCH"
	echo "RECHDIR=$RECHDIR=$usuario=$fechaHora" >> "$CONFARCH"
	echo "PROCDIR=$PROCDIR=$usuario=$fechaHora" >> "$CONFARCH"
	echo "REPODIR=$REPODIR=$usuario=$fechaHora" >> "$CONFARCH"
	echo "LOGDIR=$LOGDIR=$usuario=$fechaHora" >> "$CONFARCH"
	echo "LOGEXT=$LOGEXT=$usuario=$fechaHora" >> "$CONFARCH"
	echo "LOGSIZE=$LOGSIZE=$usuario=$fechaHora" >> "$CONFARCH"
	echo "DATASIZE=$DATASIZE=$usuario=$fechaHora" >> "$CONFARCH"
	echo "SECUENCIA1=0=$usuario=$fechaHora" >> "$CONFARCH"
	echo "SECUENCIA2=0=$usuario=$fechaHora" >> "$CONFARCH"
	Loguear "I" "Se guardaron las variables de ambiente en: $CONFARCH" 1
}

####################################################################################################

#Carga las variables de ambiente del archivo de configuración
function CargarVariables {
	while read linea; 
	do
        if [ -z "$linea" ]; then
	continue
	fi
    	var=$(echo "$linea" | cut -d'=' -f1)
    	val=$(echo "$linea" | cut -d'=' -f2)
    	eval "$var='$val'"
	done < "$CONFARCH"
}

####################################################################################################

#Revisa la instalación del sistema en caso que ya haya sido instalado anteriormente
#Determina si la instalación está completa o faltan archivos.
#Valor de retorno:
#			0: Instalación Completa
#			1: Instalación Incompleta
#			2: No se encuentran todos los archivos requeridos para completar la instalación
#			3: Perl 5 o superior no está instalado
function ChequearInstalacion {

	#Si alguna variable no esta seteada o no existe la seteo al valor default
	#No deberia pasar, pero por las dudas que el usuario haya tocado
	#el archivo de configuracion
	if [ -z "$BINDIR" ]; then	BINDIR="$GRUPO/bin"; fi
	if [ -z "$CONFDIR" ]; then CONFDIR="$BINDIR/conf"; fi
	if [ -z "$TEMPDIR" ]; then TEMPDIR="$BINDIR/temp"; fi
	if [ -z "$MAEDIR" ]; then	MAEDIR="$GRUPO/mae"; fi
	if [ -z "$ARRIDIR" ]; then ARRIDIR="$GRUPO/arribos"; fi
	if [ -z "$ACEPDIR" ]; then ACEPDIR="$GRUPO/aceptados"; fi
	if [ -z "$RECHDIR" ]; then RECHDIR="$GRUPO/rechazados"; fi
	if [ -z "$PROCDIR" ]; then PROCDIR="$GRUPO/procesados"; fi
	if [ -z "$REPODIR" ]; then REPODIR="$GRUPO/reportes"; fi
	if [ -z "$LOGDIR" ]; then LOGDIR="$GRUPO/log"; fi
	if [ -z "$LOGEXT" ]; then LOGEXT=".log"; fi
	if [ -z "$LOGSIZE" ]; then LOGSIZE=400; fi
	if [ -z "$DATASIZE" ]; then DATASIZE=100; fi	
	
	#Chequeo que se encuentre en $BINDIR o $GRUPO el archivo LoguearW5.sh
	#Si no se encuentra sale de la instalación, si se encuentra, se setea la 
	#variable LOGW5 a donde se encuentre
	if [ -e "$BINDIR/LoguearW5.sh" ]; then
		LOGW5="$BINDIR"
	elif [ -e "$GRUPO/LoguearW5.sh" ]; then
		LOGW5="$GRUPO"
		#Seteo permiso de ejecucion al LoguearW5
		chmod 755 "$GRUPO/LoguearW5.sh"
	else
		echo "No se encuentra el archivo LoguearW5.sh en $GRUPO. No se puede continuar con la instalación"
		echo "Saliendo de la instalacion"		
		return 2;
	fi
	Loguear "I" "Comando InstalaW5 Inicio de Ejecución" 1
	#Chequeo que todos los directorios estén creados y tengan los 
	#archivos que corresponden, los que no estén los agrego al array
	#de faltantes
	
	declare -a archfaltantes
	declare -a directorios
	declare -a binarios
	declare -a maestros
	declare -a dirfaltantes
	directorios=( "$BINDIR" "$MAEDIR" "$ARRIDIR" "$ACEPDIR" "$RECHDIR" "$PROCDIR" "$REPODIR" "$LOGDIR" )
	binarios=( IniciarW5.sh DetectaW5.sh BuscarW5.sh ListarW5.pl MoverW5.sh LoguearW5.sh MirarW5.sh StopD StartD Terminar.sh )
	maestros=( patrones sistemas )

	#Reviso si hay archivos o directorios faltantes
	for i in "${directorios[@]}"
	do
		if [ ! -d "$i" ]; then
			dirfaltantes+=("$i")
		fi
	done
	for i in "${binarios[@]}"
	do
		if [ ! -e "$BINDIR/$i" ]; then
			archfaltantes+=("$i")
		fi
	done
	for i in "${maestros[@]}"
	do
		if [ ! -e "$MAEDIR/$i" ]; then
			archfaltantes+=("$i")
		fi
	done
	#Chequeo que Perl esté instalado
	ChequearPerl
	#Si no esta instalado salgo con 1
	if [ $? -eq 1 ]; then
		return 3
	fi
	#Si no hay archivos ni directorios faltantes listo la ubicacion de todo y retorno 0
	if [ ${#archfaltantes[@]} -eq 0 -a ${#dirfaltantes[@]} -eq 0 ]; then
		Loguear "I" "Librería del Sistema: $CONFDIR" 0
		Loguear "I" "	InstalaW5.conf" 0
		Loguear "I" "	InstalaW5.log" 0
		Loguear "I" "Ejecutables: $BINDIR" 0
		for i in "${binarios[@]}"
		do
			Loguear "I" "	$i" 0
		done
		Loguear "I" "Archivos Maestros: $MAEDIR" 0
		for i in "${maestros[@]}"
		do
			Loguear "I" "	$i" 0
		done
		Loguear "I" "Directorio de arribo de archivos externos: $ARRIDIR" 0
		Loguear "I" "Archivos externos aceptados: $ACEPDIR" 0
		Loguear "I" "Archivos externos rechazados: $RECHDIR" 0
		Loguear "I" "Archivos procesados: $PROCDIR" 0
		Loguear "I" "Reportes de salida: $REPODIR" 0
		Loguear "I" "Logs de auditoria del Sistema: $LOGDIR/<comando>$LOGEXT" 0
		Loguear "I" "Estado de la instalación: COMPLETA" 0
		Loguear "I" "Proceso de Instalación Cancelado" 0
		return 0
	else		
		#Chequeo que se encuentren todos los archivos faltantes para instalar
		#Si no estan salgo retornando 2		
		ChequearInstalables ${archfaltantes[@]}
		if [ $? -eq 1 ]; then 
			return 2
		fi

		#Listo los componentes existentes y faltantes y retorno 1
		Loguear "I" "Componentes Existentes:" 0
		if [ -d "$BINDIR" ]; then
			Loguear "I" "	Ejecutables: $BINDIR" 0
			for i in "${binarios[@]}"
			do
				if [ -e "$BINDIR/$i" ]; then
					Loguear "I" "		$i" 0
				fi
			done
		else
			Loguear "I" "	Ejecutables: Ninguno" 0
		fi
		if [ -d "$MAEDIR" ]; then
			Loguear "I" "	Archivos Maestros: $MAEDIR" 0
			for i in "${maestros[@]}"
			do
				if [ -e "$MAEDIR/$i" ]; then
					Loguear "I" "		$i" 0
				fi
			done
		else
			Loguear "I" "	Archivos Maestros: Ninguno" 0
		fi
		Loguear "I" "Componentes faltantes:" 0
		for i in "${dirfaltantes[@]}"
		do
			Loguear "I" "	Directorio: $i" 0
		done
		for i in "${archfaltantes[@]}"
		do
			Loguear "I" "	Archivo $i" 0
		done
		Loguear "I" "Estado de la instalacion: INCOMPLETA" 0
		return 1;
	fi
}

####################################################################################################

#Informa los directorios y datos con los que se procederá la instalación
function InformarDatosInstalacion {
	Loguear "I" "Librería del Sistema: $CONFDIR" 0
	Loguear "I" "Ejecutables: $BINDIR" 0
	Loguear "I" "Archivos maestros: $MAEDIR" 0
	Loguear "I" "Directorio de arribo de archivos externos: $ARRIDIR" 0
	Loguear "I" "Espacio mínimo libre para arribos: $DATASIZE Mb" 0
	Loguear "I" "Archivos externos aceptados: $ACEPDIR" 0
	Loguear "I" "Archivos externos rechazados: $RECHDIR" 0
	Loguear "I" "Archivos procesados: $PROCDIR" 0
	Loguear "I" "Reportes de salida: $REPODIR" 0
	Loguear "I" "Logs de auditoria del Sistema: $LOGDIR/<comando>$LOGEXT" 0
	Loguear "I" "Tamaño máximo para los archivos del log del sistema: $LOGSIZE Kb" 0
}

####################################################################################################

#Chequea que se encuentren todos los archivos instalables pasados por parametro
#Valor de retorno:
#			0: Se encuentran todos los archivos
#			1: No están todos los archivos
function ChequearInstalables {
	declare local contador
	contador=0
	for i in "$@"
	do
		if [ ! -e "$GRUPO/$i" ]; then
			if [ $contador -eq 0 ]; then
				Loguear "SE" "No se encuentran los siguientes archivos de instalación en $GRUPO:" 0
			fi
			Loguear "SE" "	$i" 0
			let contador=contador+1
		fi
	done
	if [ $contador -gt 0 ]; then
		echo "Deben encontrarse todos los archivos de instalación necesarios en $GRUPO para proceder con la instalación"
		echo "Para más información lea el archivo readme.txt"
		Loguear "SE" "Saliendo de la instalación" 0
		return 1
	fi
	return 0
}

####################################################################################################

#Mueve los archivos pasados desde el segundo parametro en 
#adelante de $GRUPO al directorio pasado en el primer parametro si no existen en
#el directorio de destino
#Ambos directorios deben estar creados y el archivo en $GRUPO debe existir
function MoverArchivos {
	for i in $(seq 2 $#)
	do
		if [ ! -e "$1/${!i}" ]; then
			mv "$GRUPO"/${!i} "$1"
			#Si estoy moviendo LoguearW5.sh seteo la variable LOGW5 al path donde lo movi
			if [ ${!i} = "LoguearW5.sh" ]; then
				LOGW5="$BINDIR"
			fi
			Loguear "I" "	${!i}" 0
		fi
	done
}

####################################################################################################

#Chequea si el valor pasado por parametro es un numero entero
#Valor de retorno:
#			0: es un numero entero
#			1: no es un numero entero
function IsNumber {
	if [[ $1 =~ ^[0-9]+$ ]]; then
		return 0
	fi
	return 1
}

####################################################################################################

#Chequea si el valor pasado por parámetro es el caracter de salida de la instalacion.
#En caso afirmativo sale de la instalación
function ChequearSalida {
	if [ "$1" == "#q" ]; then
		Loguear "I" "Instalacion cancelada por el usuario" 0
		Loguear "I" "Comando InstalaW5 Fin de Ejecución" 1 
		exit 2
	fi
}

####################################################################################################

#Chequea si el nombre de directorio pasado en el primer parametro es igual al resto de los nombres 
#de directorios pasados en los subsiguientes parametros
#Valor de retorno: 
#			0: el nombre de directorio no esta repetido
#			1: el nombre de directorio esta repetido
function ChequearDirectorioRepetido {
	for i in $(seq 2 $#)
	do
		if [ "$1" = "${!i}" ]; then
			echo "Ese nombre de directorio ya lo ha suministrado anteriormente, por favor elija otro."
			return 1 
		fi		
	done
	return 0
}

####################################################################################################
##                                          COMIENZO                                              ##
####################################################################################################

#Inicio de instalacion
export GRUPO="$PWD"
INSTCONFDIR="$GRUPO/confdir"

INSTCONFPATH="$INSTCONFDIR/ConfPath.conf"
LOGINSTARCH="$INSTCONFDIR/InstalaW5.log"



#Compruebo que exista el directorio de configuracion
#Si no existe, lo creo
if [ ! -d "$INSTCONFDIR" ]; then
	mkdir -m777 "$INSTCONFDIR"
fi
CONFDIR=
CONFARCH=
if [ -e "$INSTCONFPATH" ]; then
	read CONFDIR < "$INSTCONFPATH"
fi
if [ ! -z "$CONFDIR" ] && [ -d "$CONFDIR" ]; then
	CONFARCH="$CONFDIR/InstalaW5.conf"
fi
#Si no existe el archivo de configuración quiere decir
#que no se instalo nunca
if [ -z "$CONFARCH" ] || [ ! -e "$CONFARCH" ]; then
	#Chequeo que esté el LoguearW5 en $GRUPO, si no está salgo devolviendo 3
	if [ -e "$GRUPO/LoguearW5.sh" ]; then
		LOGW5="$GRUPO"
		#Seteo permiso de ejecucion al LoguearW5
		chmod 755 "$GRUPO/LoguearW5.sh"
	else
		echo "No se encuentra el archivo LoguearW5.sh en $GRUPO. No se puede continuar con la instalación"
		echo "Saliendo de la instalacion"		
		exit 3;
	fi

	Loguear "I" "Comando InstalaW5 Inicio de Ejecución" 1

	#Chequeo que estén todos los archivos de instalación, si falta alguno salgo
	archivosInstalacion=( IniciarW5.sh DetectaW5.sh BuscarW5.sh ListarW5.pl MoverW5.sh LoguearW5.sh MirarW5.sh StopD StartD patrones sistemas Terminar.sh )
	ChequearInstalables ${archivosInstalacion[@]}
	if [ $? -eq 1 ]; then
		Loguear "I" "Comando InstalaW5 Fin de Ejecución" 1 
		exit 3
	fi
	
	
	#Chequeo que este instalado Perl
	ChequearPerl
	#Si no esta instalado salgo con 1
	if [ $? -eq 1 ]; then
		Loguear "I" "Comando InstalaW5 Fin de Ejecución" 1 
		exit 1
	fi
	#Defino datos de instalacion
	#Defino el directorio de binarios
	MSG="Defina el directorio de grabación de los ejecutables"
	DefinirDirectorio MSG BINDIR bin
	CONFDIR="$BINDIR/conf"
	TEMPDIR="$BINDIR/temp"
	CONFARCH="$CONFDIR/InstalaW5.conf"
	#Defino el directorio de archivos maestros
	MSG="Defina el directorio de instalación de los archivos maestros"
	DefinirDirectorio MSG MAEDIR mae
	while [ "$RESPUESTA" != "Si" ]
	do
		#Defino el directorio de archivos externos
		DIR_NO_REPETIDO=1
		while [ $DIR_NO_REPETIDO -eq 1 ]
		do 
			MSG="Defina el directorio de grabación de archivos externos"
			DefinirDirectorio MSG ARRIDIR arribos
			ChequearDirectorioRepetido "$ARRIDIR" "$BINDIR" "$MAEDIR"
			if [ $? -eq 0 ]; then
				DIR_NO_REPETIDO=0
			fi
		done
		#Defino DATASIZE
		DATASIZE=100
		DefinirDataSize
		if [ $? -eq 1 ]; then
			Loguear "I" "Instalacion cancelada por el usuario" 1
			Loguear "I" "Comando InstalaW5 Fin de Ejecución" 1 
			exit 2
		fi
		#Defino el directorio de archivos rechazados
		DIR_NO_REPETIDO=1
		while [ $DIR_NO_REPETIDO -eq 1 ]
		do 
			MSG="Defina el directorio de grabación de los archivos externos rechazados"
			DefinirDirectorio MSG RECHDIR rechazados
			ChequearDirectorioRepetido "$RECHDIR" "$ARRIDIR" "$BINDIR" "$MAEDIR"
			if [ $? -eq 0 ]; then
				DIR_NO_REPETIDO=0
			fi
		done
		#Defino el directorio de archivos aceptados
		DIR_NO_REPETIDO=1
		while [ $DIR_NO_REPETIDO -eq 1 ]
		do 
			MSG="Defina el directorio de grabación de los archivos externos aceptados"
			DefinirDirectorio MSG ACEPDIR aceptados
			ChequearDirectorioRepetido "$ACEPDIR" "$ARRIDIR" "$RECHDIR" "$BINDIR" "$MAEDIR"
			if [ $? -eq 0 ]; then
				DIR_NO_REPETIDO=0
			fi
		done
		#Defino el directorio de archivos procesados
		DIR_NO_REPETIDO=1
		while [ $DIR_NO_REPETIDO -eq 1 ]
		do 
			MSG="Defina el directorio de grabación de los archivos procesados"
			DefinirDirectorio MSG PROCDIR procesados
			ChequearDirectorioRepetido "$PROCDIR" "$ACEPDIR" "$ARRIDIR" "$RECHDIR" "$BINDIR" "$MAEDIR"
			if [ $? -eq 0 ]; then
				DIR_NO_REPETIDO=0
			fi
		done
		#Defino el directorio de archivos de log
		DIR_NO_REPETIDO=1
		while [ $DIR_NO_REPETIDO -eq 1 ]
		do
			MSG="Defina el directorio de grabación de los archivos de log"
			DefinirDirectorio MSG LOGDIR log
			ChequearDirectorioRepetido "$LOGDIR" "$PROCDIR" "$ACEPDIR" "$ARRIDIR" "$RECHDIR"
			if [ $? -eq 0 ]; then
				DIR_NO_REPETIDO=0
			fi
		done
		#Defino la extension de los archivos de log
		LOGEXT=".log"
		Loguear "I" "Defina la extensión para los archivos de log ($LOGEXT): " 0
		read linea
		ChequearSalida $linea
		if [ "$linea" != "" ]; then
			if [[ "$linea" = .* ]]; then
				LOGEXT="$linea"
			else
				LOGEXT=".$linea"
			fi
		fi
		#Defino el tamaño de los archivos de log		
		LOGSIZE=400
		Loguear "I" "Defina el tamaño máximo para los archivos $LOGEXT en Kbytes ($LOGSIZE): " 0
		read linea
		ChequearSalida $linea
		if [ "$linea" != "" ]; then
			IsNumber $linea
			while [ ! $? -eq 0 ]
			do
				echo "Debe ingresar un numero entero. Por favor reingrese el valor:"
				read linea
				ChequearSalida $linea
				IsNumber $linea
			done
			Loguear "I" "El usuario ingresó: $linea" 1
			LOGSIZE=$linea
		else
			Loguear "I" "El usuario ingresó el valor por omisión: $LOGSIZE" 1
		fi
		#Defino el directorio de archivos de reportes
		DIR_NO_REPETIDO=1
		while [ $DIR_NO_REPETIDO -eq 1 ]
		do
			MSG="Defina el directorio de grabación de los reportes de salida"
			DefinirDirectorio MSG REPODIR reportes
			ChequearDirectorioRepetido "$REPODIR" "$PROCDIR" "$ACEPDIR" "$ARRIDIR" "$RECHDIR"
			if [ $? -eq 0 ]; then
				DIR_NO_REPETIDO=0
			fi
		done
		#Limpio pantalla e informo datos de instalacion		
		clear
		InformarDatosInstalacion
		Loguear "I" "Estado de la instalacion: LISTA" 0
		Loguear "I" "Los datos ingresados son correctos? (Si-No)" 1
		while [ "$RESPUESTA" != "Si" -a "$RESPUESTA" != "No" ]
		do
			echo "Los datos ingresados son correctos? (Si-No)"
			read RESPUESTA
			ChequearSalida $RESPUESTA
		done
		Loguear "I" "El usuario ingresó: $RESPUESTA" 1
		if [ "$RESPUESTA" = "No" ]; then
			RESPUESTA=
			clear
		fi
	done
else
	#Cargo las variables del archivo de configuracion
	CargarVariables
		
	#Chequeo en que estado quedó la instalacion anterior
	ChequearInstalacion
	salida=$?
	#Si la instalacion esta completa salgo con 0
	if [ $salida -eq 0 ]; then
		Loguear "I" "Comando InstalaW5 Fin de Ejecución" 1 
		exit 0
	fi
	#Si no estan todos los archivos de instalacion necesarios salgo con 3
	if [ $salida -eq 2 ]; then
		Loguear "I" "Comando InstalaW5 Fin de Ejecución" 1 
		exit 3
	fi
	#Si Perl no está instalado salgo con 1
	if [ $salida -eq 3 ]; then
		Loguear "I" "Comando InstalaW5 Fin de Ejecución" 1 
		exit 1
	fi
	RESPUESTA=
	Loguear "I" "Se procederá a la instalación de los componentes faltantes. Continuar? (Si-No)" 1
	while [ "$RESPUESTA" != "Si" -a "$RESPUESTA" != "No" ]
	do
		echo "Se procederá a la instalación de los componentes faltantes. Continuar? (Si-No)"
		read RESPUESTA
		ChequearSalida $RESPUESTA	
	done
	#Sale con 2 si el usuario no quiere proseguir con la instalacion
	Loguear "I" "El usuario ingresó: $RESPUESTA" 1
	if [ "$RESPUESTA" = "No" ]; then
		Loguear "I" "Instalacion cancelada por el usuario" 0
		Loguear "I" "Comando InstalaW5 Fin de Ejecución" 1 
		exit 2
	fi
	clear
	InformarDatosInstalacion
	Loguear "I" "La instalación se llevará a cabo con estos datos." 0
fi
RESPUESTA=
Loguear "I" "Iniciando Instalación. Esta Ud seguro? (Si-No)" 1
while [ "$RESPUESTA" != "Si" -a "$RESPUESTA" != "No" ]
do
	echo "Iniciando Instalación. Esta Ud seguro? (Si-No)"
	read RESPUESTA
	ChequearSalida $RESPUESTA
done
Loguear "I" "El usuario ingresó: $RESPUESTA" 1
#Salgo con 2 si el usuario no quiere proseguir con la instalacion
if [ "$RESPUESTA" = "No" ]; then
	Loguear "I" "Instalacion cancelada por el usuario" 0
	Loguear "I" "Comando InstalaW5 Fin de Ejecución" 1 
	exit 2
fi

#Comienza la instalacion
Loguear "I" "Creando Estructura de directorios. . . ." 0
CrearDirectorios "$BINDIR" "$MAEDIR" "$ARRIDIR" "$RECHDIR" "$ACEPDIR" "$PROCDIR" "$LOGDIR" "$REPODIR" "$CONFDIR" "$TEMPDIR"

Loguear "I" "Instalando Archivos Maestros. . . ." 0
MoverArchivos "$MAEDIR" patrones sistemas

Loguear "I" "Instalando Programas y Funciones. . . ." 0
MoverArchivos "$BINDIR" IniciarW5.sh DetectaW5.sh BuscarW5.sh ListarW5.pl MoverW5.sh LoguearW5.sh MirarW5.sh StopD StartD Terminar.sh

echo "$CONFDIR" > "$INSTCONFPATH"
Loguear "I" "Actualizando la configuración del sistema. . . ." 0
GuardarVariables

Loguear "I" "Instalación Concluida" 0
Loguear "I" "Comando InstalaW5 Fin de Ejecución" 1 
exit 0

####################################################################################################
