#!/usr/bin/env bash
#Comando IniciarW5

#ARCH_CONFIG='./conf/InstalaW5.conf'
#ARCH_BLOQUEO_INICIAR='./temp/iniciar.bloqueo'

BDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ARCH_CONFIG="${BDIR}/conf/InstalaW5.conf"
ARCH_BLOQUEO_INICIAR="${BDIR}/temp/iniciar.bloqueo"
TERMINAR_INI=false
clear

while ! $TERMINAR_INI
do

	#verifica que iniciar no haya sido ejecutado antes
	if [ -e "$ARCH_BLOQUEO_INICIAR" ]; then
	#escribe un mensaje en el log indicando que iniciar ya fue ejecutado en esta sesión, muestra el estado de los componentes y sale
		"${BINDIR}"/LoguearW5.sh "IniciarW5" I "Inicio de ejecución"
		"${BINDIR}"/LoguearW5.sh "IniciarW5" E "Se intentó inicializar un ambiente ya inicializado"

		echo "Componentes existentes:"
		echo "----------------------"
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
			echo
			echo "Componentes faltantes: "
			echo "----------------------"
			echo "${NULLS[@]}"
			echo ; echo
			echo "Estado de la instalación: INCOMPLETA"
			echo "Proceso de inicialización cancelado"
			echo
			"${BINDIR}"/LoguearW5.sh "IniciarW5" E "La instalación está incompleta"
			read -p "Presione Enter para salir..."
			echo ; echo ; echo
			break
		fi

		"${BINDIR}"/LoguearW5.sh "IniciarW5" I "Fin de la ejecución"
		echo "No está permitido reinicializar el sistema"
		echo
		read -p "Presione Enter para salir..."
		break
	fi

	###################################################################

	#levanta las variables a memoria desde el archivo de configuración
	declare -a VARS=()
	declare -a VALS=()
	
	oIFS=$IFS
	IFS="="
	while read linea; do
		if [ -z "$linea" ]; then continue; fi
		var=$(echo "$linea" | cut -d'=' -f1)
		VARS=(${VARS[@]} "$var")
		val=$(echo "$linea" | cut -d'=' -f2)
		VALS=(${VALS[@]} "$val")
		declare -x "$(echo "$var")=$(echo "$val")"
	done < "$ARCH_CONFIG"
	IFS=$oIFS

	#si no se puede leer BINDIR, indica el error y sale
	if [ -z "$BINDIR" ]; then
		echo "No se indicó directorio para los archivos binarios, imposible continuar"
		echo "Fin de la ejecución"
		echo
		read -p "Presione Enter para salir..."
		break
	fi

	#agrega BINDIR al PATH
	PATH=${PATH}:${BINDIR}

	#inicializa el log
	if [ -d "${LOGDIR}" ]; then chmod u+wr "${LOGDIR}"
	else
		echo "No se encuentra el directorio de logueo. Fin de la ejecución"
		echo
		read -p "Presione Enter para salir..."
		break
	fi

	LoguearW5.sh "IniciarW5" I "Inicio de ejecución"

	###################################################################

	#revisa y muestra el estado de las variables
	echo "Componentes existentes:"
	echo "----------------------"
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
		echo
		echo "Componentes faltantes: "
		echo "----------------------"
		echo "${NULLS[@]}"
		echo ; echo ; echo
		echo "Estado de la instalación: INCOMPLETA"
		echo "Proceso de inicialización cancelado"
		echo		
		LoguearW5.sh "IniciarW5" E "La instalación está incompleta"
		read -p "Presione Enter para salir..."
		break
		echo; echo; echo
	fi

	###################################################################

	#verifica los archivos maestros y sus permisos
	if [[ -f "${MAEDIR}/patrones" && -f "${MAEDIR}/sistemas" ]]; then
		chmod u=r "${MAEDIR}/patrones"
		chmod u=r "${MAEDIR}/sistemas"
	else
		LoguearW5.sh "IniciarW5" SE "Archivo maestro no encontrado"
		LoguearW5.sh "IniciarW5" I "Fin de la ejecución"
		echo "Faltan archivos maestros. Fin de la ejecución"
		echo
		read -p "Presione Enter para salir..."
		break
	fi

	#verifica los ejecutables
	faltan_binarios=false
	if [ -d "$BINDIR" ]; then
		if [ "$(ls "${BINDIR}" | grep "DetectaW5.sh")" ]; then chmod u+rx "${BINDIR}/DetectaW5.sh"
		else faltan_binarios=true; fi
		if [ "$(ls "${BINDIR}" | grep "BuscarW5.sh")" ]; then chmod u+rx "${BINDIR}/BuscarW5.sh"
		else faltan_binarios=true; fi
		if [ "$(ls "${BINDIR}" | grep "ListarW5.pl")" ]; then chmod u+rx "${BINDIR}/ListarW5.pl"
		else faltan_binarios=true; fi
		if [ "$(ls "${BINDIR}" | grep "MoverW5.sh")" ]; then chmod u+rx "${BINDIR}/MoverW5.sh"
		else faltan_binarios=true; fi
		if [ "$(ls "${BINDIR}" | grep "LoguearW5.sh")" ]; then chmod u+rx "${BINDIR}/LoguearW5.sh"
		else faltan_binarios=true; fi
		if [ "$(ls "${BINDIR}" | grep "MirarW5.sh")" ]; then chmod u+rx "${BINDIR}/MirarW5.sh"
		else faltan_binarios=true; fi
		if [ "$(ls "${BINDIR}" | grep "StopD")" ]; then chmod u+rx "${BINDIR}/StopD"
		else faltan_binarios=true; fi
		if [ "$(ls "${BINDIR}" | grep "StartD")" ]; then chmod u+rx "${BINDIR}/StartD"
		else faltan_binarios=true; fi
		if [ "$(ls "${BINDIR}" | grep "Terminar.sh")" ]; then chmod u+rx "${BINDIR}/Terminar.sh"
		else faltan_binarios=true; fi
	
		if ${faltan_binarios} ; then
			LoguearW5.sh "IniciarW5" SE "Binarios no encontrados"
			LoguearW5.sh "IniciarW5" I "Fin de la ejecución"
			echo "Faltan archivos binarios. Fin de la ejecución"
			echo
			read -p "Presione Enter para salir..."
			break
		fi
	else
		LoguearW5.sh "IniciarW5" SE "Directorio de binarios no encontrado"
		LoguearW5.sh "IniciarW5" I "Fin de la ejecución"
		echo "No se encuentra el directorio de binarios. Fin de la ejecución"
		echo		
		read -p "Presione Enter para salir..."
		break
	fi

	#verifica el resto de los directorios
	faltan_carpetas=false
	if [ -d "$ARRIDIR" ]; then chmod u+wr "$ARRIDIR"
	else faltan_carpetas=true; fi
	if [ -d "$ACEPDIR" ]; then chmod u+wr "$ACEPDIR"
	else faltan_carpetas=true; fi
	if [ -d "$RECHDIR" ]; then chmod u+wr "$RECHDIR"
	else faltan_carpetas=true; fi
	if [ -d "$PROCDIR" ]; then chmod u+wr "$PROCDIR"
	else faltan_carpetas=true; fi
	if [ -d "$REPODIR" ]; then chmod u+wr "$REPODIR"
	else faltan_carpetas=true; fi

	if ${faltan_carpetas} ; then
		LoguearW5.sh "IniciarW5" SE "Directorios no encontrados"
		LoguearW5.sh "IniciarW5" I "Fin de la ejecución"
		echo "Faltan directorios del sistema. Fin de la ejecución"
		echo
		read -p "Presione Enter para salir..."
		break
	fi

	echo "Estado del sistema: INICIALIZADO"

	###################################################################

	#si no estaba ya iniciado, invoca a DetectaW5, y luego verifica que se esté ejecutando 
	echo ; echo ; echo
	PIDDETECTA=$(pgrep "DetectaW5.sh" -o)
	if [[ ! -z "$PIDDETECTA" ]]; then
		LoguearW5.sh "IniciarW5" A "DetectaW5 ya estaba en ejecución"
		LoguearW5.sh "IniciarW5" I "Proceso de inicialización concluido"
		echo "El demonio ya estaba corriendo bajo el nro. $PIDDETECTA"
		echo "Proceso de inicialización concluido"
		echo
	else
		StartD
		PIDDETECTA=$(pgrep "DetectaW5.sh" -o)
		if [[ ! -z "$PIDDETECTA" ]]; then
			LoguearW5.sh "IniciarW5" I "Demonio corriendo bajo el nro. $PIDDETECTA"
			LoguearW5.sh "IniciarW5" I "Proceso de inicialización concluido"
			echo "Demonio corriendo bajo el nro. $PIDDETECTA"
			echo "Proceso de inicialización concluido"
			echo
		else
			LoguearW5.sh "IniciarW5" A "Fallo al tratar de iniciar el demonio"
			LoguearW5.sh "IniciarW5" I "Proceso de inicialización concluido"
			echo "Fallo al tratar de iniciar el demonio"
			echo "Proceso de inicialización concluido"
			echo
		fi

	fi

	###################################################################

	#crea un archivo de bloqueo, que permite saber que el proceso ya se ejecutó, y termina
	touch "$ARCH_BLOQUEO_INICIAR"
	
	TERMINAR_INI=true

done
