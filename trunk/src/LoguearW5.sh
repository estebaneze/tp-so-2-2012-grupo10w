#! /bin/bash

#funcion que imprime el correcto uso de la herramienta
errorParametro() {
        echo 'Error uso LoguearW5'
        echo 'Forma Correcta:'
        echo 'LoguearW5 <comando> <tipoMensaje [I, A, E, SE]> <mensaje>'
}

errorDirectorioGrupo() {
        echo 'Por favor, defina variable GRUPO antes de utilizar LoguearW5'
}

#Estan los parametros requeridos?
if [ -z "$GRUPO" ]; then
        errorDirectorioGrupo
        exit 1
fi

#Estan los parametros requeridos?
if [ $# -ne 3 ]; then
        errorParametro
        exit 1
fi

comando=$1
tipoMensaje=$2
mensaje=$3

directorioLogPar=$LOGDIR
extensionLogPar=$LOGEXT
tamanoLogPar=$LOGSIZE

#elimino espacion repetidos 
mensaje=`echo $mensaje | sed "s/ +/ /g"`                      

#tamano maximo mensaje 120 caracteres
mensaje=`echo $mensaje | cut -c -120`

#TipoMensaje OK?
if [ $tipoMensaje != "I" ] && [ $tipoMensaje != "A" ] && [ $tipoMensaje != "E" ] && [ $tipoMensaje != "SE" ]; then
        errorParametro
        exit 1
fi

#si comando que llama Instalar => directorio conf
if [ $comando = "InstalaW5" ]; then
	directorioLogPar="conf"
else
	# estan definido? Sino => valor default
	if [ -z "$directorioLogPar" ]; then
		directorioLogPar="logdir"
	fi
fi


#extension definido? Sino => valor default
if [ -z "$extensionLogPar" ]; then
        extensionLogPar=".log"
fi

#tamano definido? Sino => valor default
if [ -z "$tamanoLogPar" ]; then
        tamanoLogPar=100
fi

#path de la carpeta de logueo
logPath="$GRUPO/$directorioLogPar"

#si no existe carpeta logueo, la creo
if [ ! -d "$logPath" ]; then
        mkdir "$logPath" -p -m 777
fi

nombreArchivoLog="$comando$extensionLogPar"
archivoLog="$logPath/$nombreArchivoLog"

when=$(date '+%Y%m%d %T')
who=$(whoami)
where=$comando
what=$tipoMensaje
why=$mensaje

#escribe en el archivo
echo "$when-$who-$where-$what-$why" >> "$archivoLog"

#valido tamano Log
tamanoLog=`echo "$(stat -c%s $archivoLog)/1024" | bc`

if [ $tamanoLog -ge "$tamanoLogPar" ]; then
	when=$(date '+%Y%m%d %T')
	what="I"
	why="Log Excedido"
	totalLineasLog=$(wc -l < "$archivoLog")
     	mitadLineasLog=`echo "$totalLineasLog/2" | bc`

	#elimino mitad del archivo de log y copio en temporal
    	sed "1,${mitadLineasLog}d" $archivoLog>${archivoLog}.tmp
    	mv ${archivoLog}.tmp $archivoLog
	echo "$when-$who-$where-$what-$why" >> "$archivoLog"
fi

exit 0