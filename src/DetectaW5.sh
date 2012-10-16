#!/bin/bash

#variable interna
sis_valido=false
error_ambiente=false
codigo_rechazo=0

#verifico inicializacion de ambiente
#verifico que las variables no sean nulas
if [ -z $ARRIDIR ]; then
        error_ambiente=true
elif [ -z $ACEPDIR ]; then
        error_ambiente=true
elif [ -z $RECHDIR ]; then
        error_ambiente=true
elif [ -z $PROCDIR ]; then
        error_ambiente=true
fi

#verifico existencia de directorios
if [ ! -d $ARRIDIR ]; then
	error_ambiente=true
elif [ ! -d $RECHDIR ]; then
        error_ambiente=true
elif [ ! -d $ACEPDIR ]; then
        error_ambiente=true
elif [ ! -d $PROCDIR ]; then
        error_ambiente=true
fi

#verifico que no haya error de inicializacion de ambiente
if [ $error_ambiente != false ]; then
	echo "Error, inicializacion del ambiente erronea"
	#borro dato oculto que hace que se ejecute infinitamente	
	rm ./.cont_temp
	exit 1
fi

#CICLO PRINCIPAL	

while [ -e ./.cont_temp ] #mientras exista el archivo temporal cont_temp se continua ejecutando el ciclo
do

	#guardo archivos de ARRIDIR en un temporal
	ls -1p $ARRIDIR | grep -v /\$ > .archivos_temp


	#cuento cantidad de archivos
	cant_archivos=$(wc -l < .archivos_temp)
	
	# obtengo todo los codigos de sistema con su fecha de alta y baja
	cut -f1,3,4 -d',' $MAEDIR/sistemas > .cod_sis_temp
	cant_sistemas=$(wc -l < .cod_sis_temp)
	
	#recorro cada archivo de ARRIDIR y los valido contra MAEDIR/sistemas
	for i in $(seq 1 $cant_archivos)
	do
	   
	    sis_valido=false
	    #obtengo nombre del primer archivo
	    archivo=$(head -n $i .archivos_temp | tail -n 1)
	
	   
	    #valido formato codigoSistema_aaaa-mm-dd
	    if [ $(echo $archivo | grep '.*_[0-9]\{4,4\}-[0-9]\{1,2\}-[0-9]\{1,2\}' -c -i) -eq 1 ]; then
			
		    #valido que sea un archivo de texto
		    if [ -r $ARRIDIR/$archivo ]; then
		
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
				    
				    sis_hallado=false

				    #recorro archivo de sistemas para validar sis_id y fechas
				    for j in $(seq 1 $cant_sistemas)
				    do
					sistema=$(head -n $j .cod_sis_temp | tail -n 1)
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
					    sis_hallado=true
					    if [ $fecha_arch -le $fecha_actual ]; then
						if [ $fecha_arch -ge $fecha_alta_sist ]; then
						    if [ ! -z $fecha_baja ]; then
							if [ $fecha_arch -le $fecha_baja_sist ]; then
							    			    
							    sis_valido=true
							else
							    codigo_rechazo=7
							fi
						    else
							sis_valido=true
						    fi
						else
						    codigo_rechazo=6						
						fi
					    else
					    	codigo_rechazo=5
					    fi
					fi

				    done # for - de sistemas
				    
				    if [ $sis_hallado == false ]; then
					codigo_rechazo=3
				    fi
			    else
				codigo_rechazo=4
			    fi
		    else
		    	codigo_rechazo=2
		    fi
	    
	    else
		codigo_rechazo=1
	    fi


	    if [ "$sis_valido" != false ]; then 
			
		#habilitar lo que sigue cuando se integre todo			
		#sh MoverW5
		mensaje="Se movio el archivo $archivo al directorio de aceptados"
		sh LoguearW5.sh "DetectarW5" "I" "$mensaje"	
			
		#comentar lo que sigue cuando se integre
		mv $ARRIDIR/$archivo $ACEPDIR/$archivo
		
	    else
		
		if [ $codigo_rechazo -eq 1 ]; then
		    mensaje="Error formato del archivo: $archivo. Se movio al directorio de rechazados"
		    sh LoguearW5.sh "DetectarW5" "E" "$mensaje"
		elif [ $codigo_rechazo -eq 2 ]; then
		    mensaje="Tipo archivo invalido: $archivo. Se movio al directorio de rechazados"
		    sh LoguearW5.sh "DetectarW5" "E" "$mensaje"
		elif [ $codigo_rechazo -eq 3 ]; then
		    mensaje="No existe sistema asociado al cod_id del archivo $archivo, se movio a rechazados"
		   sh LoguearW5.sh "DetectarW5" "E" "$mensaje"
		elif [ $codigo_rechazo -eq 4 ]; then
		    mensaje="Fecha invalida en el $archivo, se movio al directorio de rechazados"
		    sh LoguearW5.sh "DetectarW5" "E" "$mensaje"
		elif [ $codigo_rechazo -eq 5 ]; then
		    mensaje="Error, fecha posterior a la actual. Se movio el archivo $archivo a rechazados"
		    sh LoguearW5.sh "DetectarW5" "E" "$mensaje"
		elif [ $codigo_rechazo -eq 6 ]; then
		    mensaje="Error, fecha anterior a la de Alta. Se movio el archivo $archivo a rechazados"
		    sh LoguearW5.sh "DetectarW5" "E" "$mensaje"
		elif [ $codigo_rechazo -eq 7 ]; then
		    mensaje="Error, fecha posterior a la de Baja. Se movio el archivo $archivo a rechazados"
		    sh LoguearW5.sh "DetectarW5" "E" "$mensaje"
		fi		
		#habilitar lo que sigue cuando se integre todo			
		#sh MoverW5
					
		#comentar lo que sigue cuando se integre
		mv $ARRIDIR/$archivo $RECHDIR/$archivo
	    fi
		    

	    #vuelvo a ponerlo en false para analizar el siguiente archivo
	    sis_valido=false
	    fecha_valida=false
	
	done #for - de archivos
    

    #chequeo existencia de archivos en directorio ACEPDIR
    
    ls -1p $ACEPDIR | grep -v /\$ > .archivos_acep_temp
    cant_acep=$(wc -l < .archivos_acep_temp)
    
    #si existen archivos en ACEPDIR ejecuto comando BuscarW5.sh
    if [ $cant_acep -ne 0 ]; then
	#DESCOMENTAR CUANDO FUNCIONE BUSCARW5.SH	
	#chequeo que buscarw5 se este ejecutando solo una vez
	echo "invoque a Buscar.sh"	
	#sh BuscarW5.sh     
    fi

    sleep 10s
    rm .archivos_temp
    rm .cod_sis_temp
    rm .archivos_acep_temp

done
