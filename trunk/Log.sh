#!/bin/bash
#LoguearW5 [-i|-a|-e|-se] [mensaje|código de error] [argumentos de error]

CARACTERES_VALIDOS=':print:'
MODO_DE_USO="\n"\
"Modo de Uso:\n"\
"LoguearW5 [opción] [mensaje|código de error] [argumentos de error]\n"\
"\n"\
"La opción deberá ser una de las siguientes:\n"\
"-i, -I, --info : guarda mensajes de información.\n"\
"-a, -A, --alerta : guarda mensajes de alerta.\n"\
"-e, -E, --error : guarda mensajes de error.\n"\
"-se, -SE, -sev-error : guarda mensajes de error graves.\n"\
"-h, -H, --help : muestra modo de uso.\n"\
"\n"\
"El parámetro [mensaje] es único y obligatorio para -i y -a.\n"\
"El parámetro [código de error] es único y obligatorio para las opciones -e y -se\n"

TABLA_ERRORES="./errores.txt"

if [ -z "$GRUPO" ]
then 
  echo "Variable GRUPO no inicializada" >&2
  exit 1
fi

#La extensión por default será “log”  (si no se definio en la configuracion o var de ambiente).
if [ -z $LOGEXT ]
then  
   LOGEXT="log"
fi

#El tamanio maximo para cada archivo de log es 100 KB (si no se definio en la configuracion o var de ambiente).

if [ -z $LOGSIZE ]
then  
   LOGSIZE=102400
fi

#El directorio por default será $grupo/logdir (si no se definio en la configuracion o var de ambiente).
if [ -z $LOGDIR ]
then  
  LOGDIR="$GRUPO/LOGDIR" 
fi

#Si el directorio no existe, se debe crear
if [ ! -d "$LOGDIR" ]
then
        mkdir $LOGDIR  2> /dev/null
        echo $LOGDIR
        if [ $? -ne 0 ]
        then
                echo "El directorio es inexistente y no se puede crear"
                exit 5000
        fi      
fi


FECHA=`date '+%x %X '`          #devuelve la fecha del sistema dd/MM/yy hh:mm:ss
USUARIO=`whoami`                #devuelve usuario actual del sistema
COMANDO=`ps -p $PPID -o comm=`  #obtengo nombre del comando que lo invoco
FILE=$LOGDIR/$COMANDO.$LOGEXT   #nombre del archivo logger a generar
echo $FILE
#------------ Funciones --------------#

function validar_argumento_mensaje {
# $1 : mensaje , $2 : cant argumentos
  if [ -z "$1" ] 
  then
    echo "Falta el argumento [Mensaje].">&2
    echo -e $MODO_DE_USO >&2
    exit 1 
  fi

  if [ $2 -ne 2 ] 
  then
    echo "Demasiados argumentos.">&2
    echo -e $MODO_DE_USO>&2
    exit 1 
  fi
}

function obtener_mensaje {
# $1 : tipo de error
  cod_error=${argv[1]}
  declare -a args
  local i=2
  while [ $i -lt ${#argv[@]} ]
  do
    args[(($i-2))]=${argv[$i]}
    let i++
  done

  local cant_arg=`sed -n "s/^$cod_error $1 \([0-9]\).*/\1/p" "$TABLA_ERRORES"`
  msj_error=`sed -n "s/^$cod_error $1 [0-9] \(.*\)/\1/p" "$TABLA_ERRORES"`
  
  if [ -z "$msj_error" ] 
  then
    echo "El codigo de error $cod_error de tipo $1 es inválido.">&2
    echo -e $MODO_DE_USO >&2
    exit 1 
  fi

  i=0
  for arg in "${args[@]}"
  do 
    let i++
  done

  if [ $i -gt $cant_arg ] 
  then
    echo "Demasiados argumentos de error para error $cod_error.">&2
    echo -e $MODO_DE_USO >&2
    exit 1 
  else 
    if [ $i -lt $cant_arg ] 
    then
      echo "Faltan argumentos de error para error $cod_error.">&2
      echo -e $MODO_DE_USO >&2
      exit 1
    fi
  fi  

  i=1
  for arg in "${args[@]}" 
  do
    msj_error=`echo $msj_error|sed "s~@@${i}~$arg~g"`
    let i++
  done
}

function escribir_log {
  local str=""
  if [ $# -eq 2 ] 
  then
    str="$1-$2"
  else
    if [ $# -eq 3 ] 
    then
      str="$1-$2-$3"
    fi
  fi

  
  str=`echo $str | sed "s/ +/ /g"`                      #reemplazo los espacios blancos  
  str=`echo $str | sed "s/[^[$CARACTERES_VALIDOS]]//g"`  #borro los caracteres invalidos
  
  echo "$FECHA-$USUARIO-$COMANDO-$str" >>$FILE          #Copio todo en el archivo
 
}

function controlar_tamanio {
  local filesize=`stat -c%s "$FILE"`

  if [ $filesize -gt $LOGSIZE ]
  then 
    local LINEAS=`grep -c ".*" $FILE`
    local MITAD_LINEAS=`expr $LINEAS / 2`

    sed "1,${MITAD_LINEAS}d" $FILE>${FILE}.aux          #copio la mitad del archivo de log y logueo un mensaje de error
    mv ${FILE}.aux $FILE
    echo "$FECHA-$USUARIO-$COMANDO-a-Log Excedido">>$FILE
  fi
}

#-------------------------------------------------#

# $@ : lista de elementos a imprimir
i=0
argv=()
for arg in "$@"; do
    argv[$i]="$arg"
    let i++
done 

          
case $1 in
  -i|-I|--info )
      validar_argumento_mensaje "$2" $#
      escribir_log 'I' "$2" ;;
  -a|-A|--alerta )
      validar_argumento_mensaje "$2" $#
      escribir_log 'A' "$2" ;;
  -e|-E|--error )
      obtener_mensaje E
      escribir_log 'E' $cod_error "$msj_error" ;;
  -se|-SE|--sev-error )
      obtener_mensaje SE
      escribir_log 'SE' $cod_error "$msj_error" ;;
  -h|-H|--help ) 
      echo -e $MODO_DE_USO
      exit 0 ;;
  *)  echo "$1 : Opción Inválida.">&2
      echo -e $MODO_DE_USO >&2
      exit 1 ;;
esac

controlar_tamanio

exit 0
