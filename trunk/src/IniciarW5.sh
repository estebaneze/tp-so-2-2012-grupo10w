#!/usr/bin/env bash
#Comando IniciarW5
#devuelve 0 si finaliza sin problemas; devuelve 1, 2 o 3 en los demás casos

ARCH_CONFIG="${CONFDIR}/InstalaW5"
ARCH_BLOQUEO_INICIAR="${TEMPDIR}/iniciar.bloqueo"

function Mostrar_componentes{

	echo "Componentes existentes: \n"
	declare -a NULLS=()
	contador=0
	for i in $1
	do
		if [ -z "$2["$contador"]" ]; then
			NULLS=(${NULLS[@]} "echo $i")
		else
			echo "$i: $2["$contador"]"
			ls "$2["$contador"]"
		fi
		contador=`$contador + 1`
	done

	#mensajes por pantalla y en el log en caso de instalación incompleta
	if [ ! -z ${#NULLs[@]} ]; then
		echo -n "Componentes faltantes: "
		echo "$NULLS \n"
		echo "Estado de la instalación: INCOMPLETA \n"
		echo "Proceso de inicialización cancelado"
		${3}/LoguearW5 E "La instalación está incompleta"
		return 0
	else
		echo "Estado del sistema: INICIALIZADO"
		return 1
	fi
}

###################################################################

#verifica que iniciar no haya sido ejecutado antes
if [ -e "$ARCH_BLOQUEO_INICIAR" ]; then
#escribe un mensaje en el log indicando que iniciar ya fue ejecutado en esta sesión, muestra el estado de los componentes y sale
	${BINDIR}/LoguearW5 I "Inicio de ejecución"
	${BINDIR}/LoguearW5 E "Se intentó inicializar un ambiente ya inicializado"
	Mostrar_componentes "$VARS" "$VALS" "$BINDIR"
	${BINDIR}/LoguearW5 I "Fin de la ejecución"
	echo "No está permitido reinicializar el sistema"
	return 1 #ya estaba inicializado
fi

###################################################################

#levanta las variables a memoria desde el archivo de configuración
declare -a VARS=()
declare -a VALS=()

while read linea; do
	if [ -z "$linea" ]; then continue; fi
    var=$(echo $linea | cut -d'=' -f1)
	VARS=(${VARS[@]} "echo $var")
    val=$(echo $linea | cut -d'=' -f2)
	VALS=(${VALS[@]} "echo $val")
    declare "$(echo $var)=$(echo $val)"
done < "$ARCH_CONFIG"

#si no se puede leer BINDIR, indica el error y sale
if [ -z "$BINDIR" ]; then
	echo "No se indicó directorio para los archivos binarios, imposible continuar"
	echo "Fin de la ejecución"
	return 2 #falta BINDIR
fi

#agrega BINDIR al PATH
PATH=${PATH}:${BINDIR}

#inicializa el log
LoguearW5 I "Inicio de ejecución"

#revisa y muestra el estado de las variables
INI_ESTADO=´Mostrar_componentes "$VARS" "$VALS" "$BINDIR"´
if [ -z "$INI_ESTADO" ]; then return 3; fi #instalación incompleta

###################################################################

#verifica los archivos maestros y sus permisos
if [[ -s "${MAEDIR}/patrones" && -s "${MAEDIR}/sistemas" ]]; then
	chmod u=r "${MAEDIR}/patrones"
	chmod u=r "${MAEDIR}/sistemas"
else
	LoguearW5 SE "Archivo maestro no encontrado"
	LoguearW5 I "Fin de la ejecución"
	echo "Faltan componentes. Fin de la ejecución"
	return 4
fi

#verifica los ejecutables
faltan_binarios=false
if [ -d "$BINDIR" ]; then
	if [ "$(ls ${BINDIR} | grep "DetectaW5\.sh")" ]; then chmod u=x "${BINDIR}/DetectaW5\.sh"
	else faltan_binarios=true; fi
	if [ "$(ls ${BINDIR} | grep "BuscarW5\.sh")" ]; then chmod u=x "${BINDIR}/BuscarW5\.sh"
	else faltan_binarios=true; fi
	if [ "$(ls ${BINDIR} | grep "ListarW5\.pl")" ]; then chmod u=x "${BINDIR}/ListarW5\.pl"
	else faltan_binarios=true; fi
	if [ "$(ls ${BINDIR} | grep "MoverW5\.sh")" ]; then chmod u=x "${BINDIR}/MoverW5\.sh"
	else faltan_binarios=true; fi
	if [ "$(ls ${BINDIR} | grep "LoguearW5\.sh")" ]; then chmod u=x "${BINDIR}/LoguearW5\.sh"
	else faltan_binarios=true; fi
	if [ "$(ls ${BINDIR} | grep "MirarW5\.sh")" ]; then chmod u=x "${BINDIR}/MirarW5\.sh"
	else faltan_binarios=true; fi
	if [ "$(ls ${BINDIR} | grep "StopD\.sh")" ]; then chmod u=x "${BINDIR}/StopD\.sh"
	else faltan_binarios=true; fi
	if [ "$(ls ${BINDIR} | grep "StartD\.sh")" ]; then chmod u=x "${BINDIR}/StartD\.sh"
	else faltan_binarios=true; fi
	
	if [ ${faltan_binarios} ]; then
		LoguearW5 SE "Binarios no encontrados"
		LoguearW5 I "Fin de la ejecución"
		echo "Faltan componentes. Fin de la ejecución"
		return 4
	fi
else
	LoguearW5 SE "Directorio de binarios no encontrado"
	LoguearW5 I "Fin de la ejecución"
	echo "Faltan componentes. Fin de la ejecución"
	return 4
fi

#verifica el resto de los directorios
if [ ! -d "$ARRIDIR" -o ! -d "$ACEPDIR" -o ! -d "$RECHDIR" -o ! -d "$PROCDIR" -o ! -d "$REPODIR" -o ! -d "$LOGDIR"]
then
	LoguearW5 SE "Directorios no encontrados"
	LoguearW5 I "Fin de la ejecución"
	echo "Faltan componentes. Fin de la ejecución"
	return 4
fi

###################################################################

#si no estaba ya iniciado, invoca a DetectaW5, y luego verifica que se esté ejecutando 
if [ ps ax | grep -v grep | grep 'DetectaW5' > '/dev/null' ]; then
	LoguearW5 A "DetectaW5 ya estaba en ejecución"
	LoguearW5 I "Proceso de inicialización concluido"
else
	DetectaW5
	if [ ps ax | grep -v grep | grep 'DetectaW5' > '/dev/null' ]; then
		PID_DETECTA=´pidof DetectaW5´
		LoguearW5 I "Demonio corriendo bajo el nro. ${PID_DETECTA}"
		LoguearW5 I "Proceso de inicialización concluido"
		echo "Demonio corriendo bajo el nro. ${PID_DETECTA}"
		echo "Proceso de inicialización concluido"
	else
		LoguearW5 A "Fallo al tratar de iniciar el demonio"
		LoguearW5 I "Proceso de inicialización concluido"
		echo "Fallo al tratar de iniciar el demonio"
		echo "Proceso de inicialización concluido"
	fi
fi

###################################################################

#crea un archivo de bloqueo, que permite saber que el proceso ya se ejecutó, y termina
touch "$ARCH_BLOQUEO_INICIAR"
return 0