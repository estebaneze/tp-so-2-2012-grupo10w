#! /bin/bash

#funcion que imprime el correcto uso de la herramienta
function errorParametro {
        echo "Error uso LoguearW5"
        echo "Forma Correcta:"
        echo "LoguearW5 <comando> <tipoMensaje [I, A, E, SE]> <mensaje>"
}

#Estan los parametros requeridos?
if [ $# -ne 3 ]
then
        errorParametro
        exit 1
fi

comando=$1
tipoMensaje=$2
mensaje=$3


#TipoMensaje OK?
if [ $tipoMensaje != "I" ] && [ $tipoMensaje != "A" ] && [ $tipoMensaje != "E" ] && [ $tipoMensaje != "SE" ]
then
        errorParametro
        exit 1
fi

#extension y directorio estan definidos? Sino => valores default
if [ -z "$logdir" ]; then
	logdir="logdir"
fi

if [ -z "$logext" ]; then
        logext="log"
fi

#path de la carpeta de logueo
logPath="$grupo/$logdir"

#si no existe carpeta logueo, la creo
if [ ! -d "$logPath" ]; then
        mkdir "$logPath" -p -m 777
fi

nombreArchivoLog="$comando.$logext"
archivoLog="$logPath/$nombreArchivoLog"

when=$(date)
who=$(whoami)
where=$comando
what=$tipoMensaje
why=$mensaje

#escribe en el archivo
echo "$when-$who-$where-$what-$why" >> "$archivoLog"

exit 0