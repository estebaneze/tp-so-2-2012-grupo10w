#!/usr/bin/env bash
#Comando IniciarW5
#devuelve 1, 2, 3 o 4 si termina con error

ARCH_CONFIG="${CONFDIR}/config"
ARCH_BLOQUEO_INICIAR="${TEMPDIR}/iniciar.bloqueo"

###################################################################

#verifica que iniciar no haya sido ejecutado antes
if [ -e "$ARCH_BLOQUEO_INICIAR" ]; then
#escribe un mensaje en el log indicando que iniciar ya fue ejecutado en esta sesión, muestra el estado de los componentes y sale
	${BINDIR}/LoguearW5.sh "IniciarW5" I "Inicio de ejecución"
	${BINDIR}/LoguearW5.sh "IniciarW5" E "Se intentó inicializar un ambiente ya inicializado"

	echo "Componentes existentes:"
	declare -a NULLS=()
	contador=0
	for i in ${VARS[@]}
	do
		if [ -z "${VALS[$contador]}" ]; then
			NULLS=("${NULLS[@]}" "$i")
		else
			echo "$i ---- ${VALS[$contador]}"
			ls "${VALS[$contador]}" 2>'/dev/null'
		fi
		let contador=contador+1
	done

	#en caso de instalación incompleta
	if [ ! -z "${NULLS[@]}" ]; then
		echo -n "Componentes faltantes: "
		echo "${NULLS[@]}"
		echo "Estado de la instalación: INCOMPLETA"
		echo "Proceso de inicialización cancelado"
		LoguearW5.sh "IniciarW5" E "La instalación está incompleta"
		read -p "Presione Enter para salir..."
		exit 3
	else
		echo "Estado del sistema: INICIALIZADO"
	fi

	${BINDIR}/LoguearW5.sh "IniciarW5" I "Fin de la ejecución"
	echo "No está permitido reinicializar el sistema"
	read -p "Presione Enter para salir..."
	exit 1 #ya estaba inicializado
fi

###################################################################

#levanta las variables a memoria desde el archivo de configuración
declare -a VARS=()
declare -a VALS=()

while read linea; do
	if [ -z "$linea" ]; then continue; fi
    var=$(echo $linea | cut -d'=' -f1)
	VARS=(${VARS[@]} "$var")
    val=$(echo $linea | cut -d'=' -f2)
	VALS=(${VALS[@]} "$val")
    declare "$(echo $var)=$(echo $val)"
done < "$ARCH_CONFIG"

#si no se puede leer BINDIR, indica el error y sale
if [ -z "$BINDIR" ]; then
	echo "No se indicó directorio para los archivos binarios, imposible continuar"
	echo "Fin de la ejecución"
	read -p "Presione Enter para salir..."
	exit 2 #falta BINDIR
fi

#agrega BINDIR al PATH
PATH=${PATH}:${BINDIR}

#inicializa el log
LoguearW5.sh "IniciarW5" I "Inicio de ejecución"

###################################################################

#revisa y muestra el estado de las variables
echo "Componentes existentes:"
declare -a NULLS=()
contador=0
for i in ${VARS[@]}
do
	if [ -z "${VALS[$contador]}" ]; then
		NULLS=("${NULLS[@]}" "$i")
	else
		echo "$i ---- ${VALS[$contador]}"
		ls "${VALS[$contador]}" 2>'/dev/null'
	fi
	let contador=contador+1
done

#en caso de instalación incompleta
if [ ! -z "${NULLS[@]}" ]; then
	echo -n "Componentes faltantes: "
	echo "${NULLS[@]}"
	echo "Estado de la instalación: INCOMPLETA"
	echo "Proceso de inicialización cancelado"
	LoguearW5.sh "IniciarW5" E "La instalación está incompleta"
	read -p "Presione Enter para salir..."
	exit 3
else
	echo "Estado del sistema: INICIALIZADO"
fi

###################################################################

#verifica los archivos maestros y sus permisos
if [[ -f "${MAEDIR}/patrones" && -f "${MAEDIR}/sistemas" ]]; then
	chmod u=r "${MAEDIR}/patrones"
	chmod u=r "${MAEDIR}/sistemas"
else
	LoguearW5.sh "IniciarW5" SE "Archivo maestro no encontrado"
	LoguearW5.sh "IniciarW5" I "Fin de la ejecución"
	echo "Faltan componentes. Fin de la ejecución"
	read -p "Presione Enter para salir..."
	exit 4
fi

#verifica los ejecutables
faltan_binarios=false
if [ -d "$BINDIR" ]; then
	if [ "$(ls ${BINDIR} | grep "DetectaW5.sh")" ]; then chmod u+rx "${BINDIR}/DetectaW5.sh"
	else faltan_binarios=true; fi
	if [ "$(ls ${BINDIR} | grep "BuscarW5.sh")" ]; then chmod u+rx "${BINDIR}/BuscarW5.sh"
	else faltan_binarios=true; fi
	if [ "$(ls ${BINDIR} | grep "ListarW5.pl")" ]; then chmod u+rx "${BINDIR}/ListarW5.pl"
	else faltan_binarios=true; fi
	if [ "$(ls ${BINDIR} | grep "MoverW5.sh")" ]; then chmod u+rx "${BINDIR}/MoverW5.sh"
	else faltan_binarios=true; fi
	if [ "$(ls ${BINDIR} | grep "LoguearW5.sh")" ]; then chmod u+rx "${BINDIR}/LoguearW5.sh"
	else faltan_binarios=true; fi
	if [ "$(ls ${BINDIR} | grep "MirarW5.sh")" ]; then chmod u+rx "${BINDIR}/MirarW5.sh"
	else faltan_binarios=true; fi
	if [ "$(ls ${BINDIR} | grep "StopD.sh")" ]; then chmod u+rx "${BINDIR}/StopD.sh"
	else faltan_binarios=true; fi
	if [ "$(ls ${BINDIR} | grep "StartD.sh")" ]; then chmod u+rx "${BINDIR}/StartD.sh"
	else faltan_binarios=true; fi
	
	if ${faltan_binarios} ; then
		LoguearW5.sh "IniciarW5" SE "Binarios no encontrados"
		LoguearW5.sh "IniciarW5" I "Fin de la ejecución"
		echo "Faltan componentes. Fin de la ejecución"
		read -p "Presione Enter para salir..."
		exit 4
	fi
else
	LoguearW5.sh "IniciarW5" SE "Directorio de binarios no encontrado"
	LoguearW5.sh "IniciarW5" I "Fin de la ejecución"
	echo "Faltan componentes. Fin de la ejecución"
	read -p "Presione Enter para salir..."
	exit 4
fi

#verifica el resto de los directorios
if [ ! -d "$ARRIDIR" -o ! -d "$ACEPDIR" -o ! -d "$RECHDIR" -o ! -d "$PROCDIR" -o ! -d "$REPODIR" -o ! -d "$LOGDIR" -o ! -d "$TEMPDIR" ]
then
	LoguearW5.sh "IniciarW5" SE "Directorios no encontrados"
	LoguearW5.sh "IniciarW5" I "Fin de la ejecución"
	echo "Faltan componentes. Fin de la ejecución"
	read -p "Presione Enter para salir..."
	exit 4
fi

###################################################################

#si no estaba ya iniciado, invoca a DetectaW5, y luego verifica que se esté ejecutando 
if [ ps ax | grep -v grep | grep 'DetectaW5' > '/dev/null' ]; then
	LoguearW5.sh "IniciarW5" A "DetectaW5 ya estaba en ejecución"
	LoguearW5.sh "IniciarW5" I "Proceso de inicialización concluido"
else
	StartD.sh
	if [ ps ax | grep -v grep | grep 'DetectaW5' > '/dev/null' ]; then
		PID_DETECTA=´pidof DetectaW5´
		LoguearW5.sh "IniciarW5" I "Demonio corriendo bajo el nro. ${PID_DETECTA}"
		LoguearW5.sh "IniciarW5" I "Proceso de inicialización concluido"
		echo "Demonio corriendo bajo el nro. ${PID_DETECTA}"
		echo "Proceso de inicialización concluido"
	else
		LoguearW5.sh "IniciarW5" A "Fallo al tratar de iniciar el demonio"
		LoguearW5.sh "IniciarW5" I "Proceso de inicialización concluido"
		echo "Fallo al tratar de iniciar el demonio"
		echo "Proceso de inicialización concluido"
	fi
fi

###################################################################

#crea un archivo de bloqueo, que permite saber que el proceso ya se ejecutó, y termina
touch "$ARCH_BLOQUEO_INICIAR"
