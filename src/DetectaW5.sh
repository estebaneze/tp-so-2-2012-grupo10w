#!/bin/bash

#variable interna
sis_valido=false


#verifico inicializacion de ambiente
#verifico que las variables no sean nulas
if [ -z $ARRIDIR ]; then
        echo "Error, inicializacion del ambiente erronea"
	exit 1
fi
if [ -z $ACEPDIR ]; then
        echo "Error, inicializacion del ambiente erronea"
	exit 1
fi
if [ -z $RECHDIR ]; then
        echo "Error, inicializacion del ambiente erronea"
	exit 1
fi
if [ -z $PROCDIR ]; then
        echo "Error, inicializacion del ambiente erronea"
	exit 1
fi


#verifico existencia de directorios
if [ ! -d $GRUPO$ARRIDIR ]; then
	echo "Error, no existe directorio de arribos $GRUPO$ARRIDIR"
	exit 2
elif [ ! -d $GRUPO$RECHDIR ]; then
        echo "Error, no existe directorio de rechazados $GRUPO$RECHDIR"
	exit 2
elif [ ! -d $GRUPO$ACEPDIR ]; then
        echo "Error, no existe directorio de aceptados $GRUPO$ACEPDIR"
	exit 2
elif [ ! -d $GRUPO$PROCDIR ]; then
        echo "Error, no existe directorio de procesados $GRUPO$PROCDIR"
	exit 2
fi

#CICLO PRINCIPAL	

while [ -e ./cont_temp ] #mientras exista el archivo temporal cont_temp se continua ejecutando el ciclo
do

	#guardo archivos de ARRIDIR en un temporal
	ls -1p $GRUPO$ARRIDIR | grep -v /\$ > archivos_temp


	#cuento cantidad de archivos
	cant_archivos=$(wc -l < archivos_temp)
	echo $cant_archivos
	# obtengo todo los codigos de sistema con su fecha de alta y baja
	cut -f1,3,4 -d',' $GRUPO/MAEDIR/sistemas > cod_sis_temp
	cant_sistemas=$(wc -l < cod_sis_temp)
	
	#recorro cada archivo de ARRIDIR y los valido contra MAEDIR/sistemas
	for i in $(seq 1 $cant_archivos)
	do
	   
	    sis_valido=false
	    #obtengo nombre del primer archivo
	    archivo=$(head -n $i archivos_temp | tail -n 1)
	
	   
	    #valido formato codigoSistema_aaaa-mm-dd
	    if [ $(echo $archivo | grep '.*_[0-9]\{4,4\}-[0-9]\{1,2\}-[0-9]\{1,2\}' -c -i) -eq 1 ]; then
			
		    #valido que sea un archivo de texto
		    if [ -r $GRUPO$ARRIDIR/$archivo ]; then
		
			    #separo los campos
			    sis_id1=$(echo $archivo | cut -d \_ -f 1) 
			    fecha=$(echo $archivo | cut -d \_ -f 2)
			    #separo fecha
			    anio=$(echo $fecha |cut -d \- -f 1)
			    mes=$(echo $fecha |cut -d \- -f 2)
			    dia=$(echo $fecha |cut -d \- -f 3)

			    
			   

			    if [ $anio -ge 2000 -a $anio -le $(date +%Y) ]; then 
			    # invalido si el año no va de 2000 al actual
				if [ $mes -ge 1 -a $mes -le 12 ]; then 
				# invaildo si el mes no esta entre los numeros 1 y 12
				    if [ $dia -ge 1 -a $dia -le 31 ]; then 
				    #invalido si el dia no esta entre los numeros 1 y 31
					fecha_valida=true
				
				    fi
				fi
			    fi
	
			    if [ $fecha_valida != false ]; then
			
				    #trasformo fecha a formato para comparar
				    fecha_arch=$(echo $fecha | sed "s-\---g")

				    #recorro archivo de sistemas para validar sis_id y fechas
				    for j in $(seq 1 $cant_sistemas)
				    do
					sistema=$(head -n $j cod_sis_temp | tail -n 1)
					#separo los campos	
					sis_id=$(echo $sistema | cut -d \, -f 1)	
					fecha_alta=$(echo $sistema | cut -d \, -f 2)
					fecha_baja=$(echo $sistema | cut -d \, -f 3 )
	
					fecha_alta_sist=$(echo $fecha_alta | sed "s-\---g")
					fecha_baja_sist=$(echo $fecha_baja | sed "s-\---g")
	
					#obtengo fecha actual en el formato que necesito
					fecha_actual=$(echo $(date +%Y)$(date +%m)$(date +%d))	
	
					# valido que el id del sistema exista
					if [ $sis_id -eq $sis_id1 ]; then
					    if [ $fecha_arch -le $fecha_actual ]; then
						if [ $fecha_arch -ge $fecha_alta_sist ]; then
						    if [ ! -z $fecha_baja ]; then
							if [ $fecha_arch -le $fecha_baja_sist ]; then
							    sis_valido=true
							fi
						    else
							sis_valido=true
						    fi
						fi
					    fi
					fi

				    done # for - de sistemas
			    fi
		    fi
	    
	    fi


	    if [ "$sis_valido" != false ]; then 
			
		#habilitar lo que sigue cuando se integre todo			
		#sh MoverW5
		mensaje="Se movio el archivo $archivo al directorio de aceptados"
		sh LoguearW5.sh "DetectarW5" "I" "$mensaje"	
			
		#comentar lo que sigue cuando se integre
		mv $GRUPO$ARRIDIR/$archivo $GRUPO$ACEPDIR/$archivo
		
	    else
		#habilitar lo que sigue cuando se integre todo			
		#sh MoverW5
		mensaje="Se movio el archivo $archivo al directorio de rechazados"
		sh LoguearW5.sh "DetectarW5" "I" "$mensaje"	
			
		#comentar lo que sigue cuando se integre
		mv $GRUPO$ARRIDIR/$archivo $GRUPO$RECHDIR/$archivo
	    fi
		    

	    #vuelvo a ponerlo en false para analizar el siguiente archivo
	    sis_valido=false
	    fecha_valida=false
	

	done #for - de archivos
    sleep 10s
    
    
done

