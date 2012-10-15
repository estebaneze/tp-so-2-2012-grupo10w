#!/bin/bash
#Comando InstalaW5
#Codigos de salida:
#		0: Normal
#		1: Falta Perl
#		2: Instalacion cancelada por el usuario
#		3: Faltan archivos para realizar la instalacion		
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
			return 0;
		fi
	fi
	echo "Para instalar el TP es necesario contar con Perl 5 o superior instalado. Efectue su instalacion e intentelo nuevamente"
	echo "Proceso de Instalacion Cancelado"
	return 1;
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
		if [[ $linea == /* ]]; then
			eval "$2=$GRUPO$linea"
		else
			eval "$2=$GRUPO/$linea"
		fi
	fi
}

#Define el valor de DATASIZE, si el valor definido por el usuario es mayor
#al espacio libre, se le da la opción de ingresa un nuevo valor
#Retorna 0 si se definió el valor, 1 en caso contrario
function DefinirDataSize {
	ESPACIOLIBRE=0
	while [ $ESPACIOLIBRE -lt $DATASIZE ]; do
	echo "Defina el espacio mínimo libre para el arribo de archivos externos en MBytes ($DATASIZE):"
	read linea
	if [ "$linea" != "" ]; then
		IsNumber $linea
		while [ ! $? -eq 0 ]
		do
			echo "Debe ingresar un numero entero. Por favor reingrese el valor:"
			read linea
			IsNumber $linea
		done
		DATASIZE=$linea
	fi
	ARRIDIRTEMP=$ARRIDIR
	while test ! -e $ARRIDIRTEMP; do
		ARRIDIRTEMP=$(dirname $ARRIDIRTEMP)
	done	
		ESPACIOLIBRE=$(df -k $ARRIDIRTEMP | awk 'NR == 2 {print $4}')
		if [ $ESPACIOLIBRE -lt $DATASIZE ]; then
			echo "Insuficiente espacio en disco."
			echo "Espacio disponible: $ESPACIOLIBRE Mb."
			echo "Espacio requerido $DATASIZE Mb."
			echo "Cancele la instalación e inténtelo más tarde o vuelva a intentarlo con otro valor."
			while [ $linea!="Si" -a $linea!="No" ] 
			do
				echo "Desea ingresar otro valor? (Si-No)"
			done
			if [ $linea="No" ]; then
				echo "Saliendo de la Instalación"
				return 1
			fi
		fi
	done
	return 0
}

#Crea todos los directorios que no existan de las rutas pasadas como parametro
function CrearDirectorios {
	for i in "$@"
	do
		if [ ! -d $i ]; then 
			echo "$i"
			mkdir -p -m777 $i
		fi
	done
}

#Imprime por salida estandar y en el archivo de log de instalación
# Parametro 1: Tipo de Mensaje
# Parametro 2: Mensaje
# Parametro 3: 0 para imprimir por stdout y loguear, 1 solo para loguear
function ImprimirYLoguear {
	echo "$2"
	$LOGW5/LoguearW5.sh "InstalaW5" "$1" "$2"
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
}

#Carga las variables de ambiente del archivo de configuración
function CargarVariables {
	while read linea; 
	do
        if [ -z "$linea" ]; then
			continue
		fi
    	var=$(echo $linea | cut -d'=' -f1)
    	val=$(echo $linea | cut -d'=' -f2)
    	eval "$var=$val"
	done < "$CONFARCH"
}

#Revisa la instalación del sistema en caso que ya haya sido instalado anteriormente
#Determina si la instalación está completa o faltan archivos.
#En caso que la instalación esté completa informa que está completa y retorna 0
#En caso que la instalación esté incompleta informa que archivos o directorios faltan y retorna 1
#En caso que la instalación esté incompleta pero no estén los archivos faltantes en la carpeta
#de instalación para instalarse retorna 2
function ChequearInstalacion {

	#Si alguna variable no esta seteada o no existe la seteo al valor default
	#No deberia pasar, pero por las dudas que el usuario haya tocado
	#el archivo de configuracion
	if [ -z $BINDIR ]; then	BINDIR=$GRUPO/bin; fi
	if [ -z $CONFDIR ]; then CONFDIR=$BINDIR/conf; fi
	if [ -z $TEMPDIR ]; then TEMPDIR=$BINDIR/temp; fi
	if [ -z $MAEDIR ]; then	MAEDIR=$GRUPO/mae; fi
	if [ -z $ARRIDIR ]; then ARRIDIR=$GRUPO/arribos; fi
	if [ -z $ACEPDIR ]; then ACEPDIR=$GRUPO/aceptados; fi
	if [ -z $RECHDIR ]; then RECHDIR=$GRUPO/rechazados; fi
	if [ -z $PROCDIR ]; then PROCDIR=$GRUPO/procesados; fi
	if [ -z $REPODIR ]; then REPODIR=$GRUPO/reportes; fi
	if [ -z $LOGDIR ]; then LOGDIR=$GRUPO/log; fi
	if [ -z $LOGEXT ]; then LOGEXT=".log"; fi
	if [ -z $LOGSIZE ]; then LOGSIZE=400; fi
	if [ -z $DATASIZE ]; then DATASIZE=100; fi	
	
	#Chequeo que todos los directorios estén creados y tengan los 
	#archivos que corresponden, los que no estén los agrego al array
	#de faltantes
	
	declare -a archfaltantes
	declare -a directorios
	declare -a binarios
	declare -a maestros
	declare -a dirfaltantes
	directorios=( $BINDIR $MAEDIR $ARRIDIR $ACEPDIR $RECHDIR $PROCDIR $REPODIR $LOGDIR )
	binarios=( IniciarW5.sh DetectaW5.sh BuscarW5.sh ListarW5.pl MoverW5.sh LoguearW5.sh MirarW5.sh StopD StartD )
	maestros=( patrones sistemas )

	#Reviso si hay archivos o directorios faltantes
	for i in "${directorios[@]}"
	do
		if [ ! -d $i ]; then
			dirfaltantes+=($i)
		fi
	done
	for i in "${binarios[@]}"
	do
		if [ ! -e $BINDIR/$i ]; then
			archfaltantes+=($i)
		fi
	done
	for i in "${maestros[@]}"
	do
		if [ ! -e $MAEDIR/$i ]; then
			archfaltantes+=($i)
		fi
	done

	#Si no hay archivos ni directorios faltantes listo la ubicacion de todo y retorno 0
	if [ ${#archfaltantes[@]} -eq 0 -a ${#dirfaltantes[@]} -eq 0 ]; then
		LOGW5=$BINDIR
		echo "Librería del Sistema: $CONFDIR"
		if [ -e $CONFDIR/InstalaW5.conf ]; then echo "	InstalaW5.conf"; fi
		if [ -e $CONFDIR/InstalaW5.log ]; then echo "	InstalaW5.log"; fi
		echo "Ejecutables: $BINDIR"
		for i in "${binarios[@]}"
		do
			echo "	$i"
		done
		echo "Archivos Maestros: $MAEDIR"
		for i in "${maestros[@]}"
		do
			echo "	$i"
		done
		echo "Directorio de arribo de archivos externos: $ARRIDIR"
		echo "Archivos externos aceptados: $ACEPDIR"
		echo "Archivos externos rechazados: $RECHDIR"
		echo "Archivos procesados: $PROCDIR"
		echo "Reportes de salida: $REPODIR"
		echo "Logs de auditoria del Sistema: $LOGDIR/<comando>$LOGEXT"
		echo "Estado de la instalación: COMPLETA"
		echo "Proceso de Instalación Cancelado"
		return 0
	else
		#Chequeo que Perl esté instalado
		ChequearPerl
		#Si no esta instalado salgo con 1
		if [ $? -eq 1 ]; then
			exit 1
		fi
		#Chequeo que se encuentren todos los archivos faltantes para instalar
		#Si no estan salgo retornando 2		
		ChequearInstalables ${archfaltantes[@]}
		if [ $? -eq 1 ]; then 
			return 2
		fi

		#Listo los componentes existentes y faltantes y retorno 1
		echo "Componentes Existentes:"
		if [ -d $BINDIR ]; then
			echo "	Ejecutables: $BINDIR"
			for i in "${binarios[@]}"
			do
				if [ -e $BINDIR/$i ]; then
					echo "		$i"
				fi
			done
		else
			echo "	Ejecutables: Ninguno"
		fi
		if [ -d $MAEDIR ]; then
			echo "	Archivos Maestros: $MAEDIR"
			for i in "${maestros[@]}"
			do
				if [ -e $MAEDIR/$i ]; then
					echo "		$i"
				fi
			done
		else
			echo "	Archivos Maestros: Ninguno"
		fi
		echo "Componentes faltantes:"
		for i in "${dirfaltantes[@]}"
		do
			echo "	$i"
		done
		for i in "${archfaltantes[@]}"
		do
			echo "	$i"
		done
		echo "Estado de la instalacion: INCOMPLETA"
		return 1;
	fi
}

#Informa los directorios y datos con los que se procederá la instalación
function InformarDatosInstalacion {
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
}

#Retorna 0 si se encuentran todos los archivos instalables, caso contrario 1
function ChequearInstalables {
	declare local contador
	contador=0
	for i in "$@"
	do
		if [ ! -e $GRUPO/$i ]; then
			if [ $contador -eq 0 ]; then
				echo "No se encuentran los siguientes archivos de instalación en $GRUPO:"
			fi
			echo "	$i"
			let contador=contador+1
		fi
	done
	if [ $contador -gt 0 ]; then
		echo "Deben encontrarse todos los archivos de instalación necesarios en $GRUPO para proceder con la instalación"
		echo "Para más información lea el archivo readme.txt"
		echo "Saliendo de la instalación"
		return 1
	fi
	return 0
}

#Mueve los archivos pasados desde el segundo parametro en 
#adelante de $GRUPO al directorio pasado en el primer parametro
#ambos directorios deben estar creados y los archivos deben existir
function MoverArchivos {
	for i in $(seq 2 $#)
	do
		if [ ! -e "$1/${!i}" ]; then
			mv $GRUPO/${!i} $1
		fi
	done
}

#Chequea si el valor pasado por parametro es un numero.
#Si es un numero devuelve 0, sino 1
function IsNumber {
	if [[ $1 =~ ^[0-9]+$ ]]; then
		return 0
	fi
	return 1
}

############################################
##             COMIENZO                   ##
############################################

#Inicio de instalacion
GRUPO=$PWD
INSTCONFDIR=$GRUPO/confdir

INSTCONFPATH=$INSTCONFDIR/ConfPath.conf
LOGINSTARCH=$INSTCONFDIR/InstalaW5.log



#Compruebo que exista el directorio de configuracion
#Si no existe, lo creo
if [ ! -d $INSTCONFDIR ]; then
	mkdir -m777 $INSTCONFDIR
fi
CONFDIR=
CONFARCH=
if [ -e $INSTCONFPATH ]; then
	read CONFDIR < $INSTCONFPATH
fi
if [ ! -z $CONFDIR ] && [ -d $CONFDIR ]; then
	CONFARCH=$CONFDIR/InstalaW5.conf
fi
#Si no existe el archivo de configuración quiere decir
#que no se instalo nunca
if [ -z $CONFARCH ] || [ ! -e $CONFARCH ]; then
	#Chequeo que estén todos los archivos de instalación, si falta alguno salgo
	archivosInstalacion=( IniciarW5.sh DetectaW5.sh BuscarW5.sh ListarW5.pl MoverW5.sh LoguearW5.sh MirarW5.sh StopD StartD patrones sistemas )
	ChequearInstalables ${archivosInstalacion[@]}
	if [ $? -eq 1 ]; then 
		exit 3
	fi
	#Seteo LOGW5 al path donde esta el comando LoguearW5.sh
	LOGW5=$GRUPO
	#Chequeo que este instalado Perl
	ChequearPerl
	#Si no esta instalado salgo con 1
	if [ $? -eq 1 ]; then
		exit 1
	fi
	#Defino datos de instalacion
	MSG="Defina el directorio de grabación de los ejecutables"
	DefinirDirectorio MSG BINDIR /bin
	CONFDIR=$BINDIR/conf
	TEMPDIR=$BINDIR/temp
	CONFARCH=$CONFDIR/InstalaW5.conf
	MSG="Defina el directorio de instalación de los archivos maestros"
	DefinirDirectorio MSG MAEDIR /mae
	while [ "$RESPUESTA" != "Si" ]
	do
		MSG="Defina el directorio de grabación de archivos externos"
		DefinirDirectorio MSG ARRIDIR /arribos
		DATASIZE=100
		DefinirDataSize
		if [ $? -eq 1 ]; then
			echo "Instalacion cancelada por el usuario"
			exit 2
		fi
		MSG="Defina el directorio de grabación de los archivos externos rechazados"
		DefinirDirectorio MSG RECHDIR /rechazados
		MSG="Defina el directorio de grabación de los archivos externos aceptados"
		DefinirDirectorio MSG ACEPDIR /aceptados
		MSG="Defina el directorio de grabación de los archivos procesados"
		DefinirDirectorio MSG PROCDIR /procesados
		LOGDIR=$GRUPO/log
		LOGEXT=.log
		LOGSIZE=400
		echo "Defina el tamaño máximo para los archivos $LOGEXT en Kbytes ($LOGSIZE): "
		read linea
		if [ "$linea" != "" ]; then
			IsNumber $linea
			while [ ! $? -eq 0 ]
			do
				echo "Debe ingresar un numero entero. Por favor reingrese el valor:"
				read linea
				IsNumber $linea
			done
			LOGSIZE=$linea
		fi
		MSG="Defina el directorio de grabación de los reportes de salida"
		DefinirDirectorio MSG REPODIR /reportes
		clear
		InformarDatosInstalacion
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
else
	#Cargo las variables del archivo de configuracion
	CargarVariables
	#Chequeo donde está LoguearW5.sh y seteo la variable LOGW5 al path
	#en que se encuentre, si no se encuentra sale de la instalacion
	#devolviendo 4
	
	#Chequeo en que estado quedó la instalacion anterior
	ChequearInstalacion
	salida=$?
	#Si la instalacion esta completa salgo con 0
	if [ $salida -eq 0 ]; then
		exit 0
	fi
	#Si no estan todos los archivos de instalacion necesarios salgo con 3
	if [ $salida -eq 2 ]; then
		exit 3
	fi
	RESPUESTA=
	while [ "$RESPUESTA" != "Si" -a "$RESPUESTA" != "No" ]
	do
		echo "Se procederá a la instalación de los componentes faltantes. Continuar? (Si-No)"
		read RESPUESTA	
	done
	#Sale con 2 si el usuario no quiere proseguir con la instalacion
	if [ "$RESPUESTA" = "No" ]; then
		echo "Instalacion de componentes faltantes finalizada por el usuario"
		exit 2
	fi
	clear
	InformarDatosInstalacion
	echo "La instalación se llevará a cabo con estos datos."
fi
RESPUESTA=
while [ "$RESPUESTA" != "Si" -a "$RESPUESTA" != "No" ]
do
	echo "Iniciando Instalación. Esta Ud seguro? (Si-No)"
	read RESPUESTA
done
#Salgo con 2 si el usuario no quiere proseguir con la instalacion
if [ "$RESPUESTA" = "No" ]; then
	echo "Instalacion cancelada por el usuario"
	exit 2
fi

#Comienza la instalacion
echo "Creando Estructura de directorios. . . ."
CrearDirectorios $BINDIR $MAEDIR $ARRIDIR $RECHDIR $ACEPDIR $PROCDIR $LOGDIR $REPODIR $CONFDIR $TEMPDIR

echo "Instalando Archivos Maestros"
MoverArchivos $MAEDIR patrones sistemas

echo "Instalando Programas y Funciones"
MoverArchivos $BINDIR IniciarW5.sh DetectaW5.sh BuscarW5.sh ListarW5.pl MoverW5.sh LoguearW5.sh MirarW5.sh StopD StartD

echo "$CONFDIR" > $INSTCONFPATH
#Seteo LOGW5 al path donde esta el comando LoguearW5.sh
LOGW5=$BINDIR
echo "Actualizando la configuración del sistema"
GuardarVariables

echo "Instalación Concluida"

exit 0