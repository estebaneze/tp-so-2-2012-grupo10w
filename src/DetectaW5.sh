#!/bin/bash

#variable interna
sis_valido=false
error_ambiente=false
codigo_rechazo=0

#verifico inicializacion de ambiente
#verifico que las variables no sean nulas
if [ -z "$ARRIDIR" ]; then
        error_ambiente=true
elif [ -z "$ACEPDIR" ]; then
        error_ambiente=true
elif [ -z "$RECHDIR" ]; then
        error_ambiente=true
elif [ -z "$PROCDIR" ]; then
        error_ambiente=true
fi

#verifico existencia de directorios
if [ ! -d "$ARRIDIR" ]; then
	error_ambiente=true
elif [ ! -d "$RECHDIR" ]; then
        error_ambiente=true
elif [ ! -d "$ACEPDIR" ]; then
        error_ambiente=true
elif [ ! -d "$PROCDIR" ]; then
        error_ambiente=true
fi

#verifico que no haya error de inicializacion de ambiente
if [ $error_ambiente != false ]; then
	echo "Error, inicializacion del ambiente erronea."
	echo "Se detendra el demonio."
	#borro dato oculto que hace que se ejecute infinitamente	
	rm "${TEMPDIR}/.cont_temp"
	
fi

#CICLO PRINCIPAL	

while [ -e "${TEMPDIR}/.cont_temp" ] #mientras exista el archivo temporal cont_temp se continua ejecutando el ciclo
do

	#guardo archivos de ARRIDIR en un temporal
	ls -1p "$ARRIDIR" | grep -v /\$ > "${TEMPDIR}/.archivos_temp"


	#cuento cantidad de archivos
	cant_archivos=$(wc -l < "${TEMPDIR}/.archivos_temp")
	
	# obtengo todo los codigos de sistema con su fecha de alta y baja
	cut -f1,3,4 -d',' "$MAEDIR/sistemas" > "${TEMPDIR}/.cod_sis_temp"
	cant_sistemas=$(wc -l < "${TEMPDIR}/.cod_sis_temp")
	
	#recorro cada archivo de ARRIDIR y los valido contra MAEDIR/sistemas
	for i in $(seq 1 $cant_archivos)
	do
	   
	    sis_valido=false
	    #obtengo nombre del primer archivo
	    archivo=$(head -n $i "${TEMPDIR}/.archivos_temp" | tail -n 1)
	
	   
	    #valido formato codigoSistema_aaaa-mm-dd
	    if [ $(echo $archivo | grep '.*_[0-9]\{4,4\}-[0-9]\{1,2\}-[0-9]\{1,2\}$' -c -i) -eq 1 ]; then
			
		    #valido que sea un archivo de texto
		    if [ -r "$ARRIDIR/$archivo" ]; then
		
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
				    fecha_arch=$(echo $fecha | sed "s-\---g") 2> "/dev/null"
				    
				    sis_hallado=false

				    #recorro archivo de sistemas para validar sis_id y fechas
				    for j in $(seq 1 $cant_sistemas)
				    do
					sistema=$(head -n $j "${TEMPDIR}/.cod_sis_temp" | tail -n 1)
					#separo los campos	
					sis_id=$(echo $sistema | cut -d \, -f 1)	
					fecha_alta=$(echo $sistema | cut -d \, -f 2)
					fecha_baja=$(echo $sistema | cut -d \, -f 3 )
					if [[ ! $fecha_baja =~ ^[0-9].* ]] ; then
						fecha_baja=
					fi
					fecha_alta_sist=$(echo $fecha_alta | sed "s-\---g") 2> "/dev/null"
					fecha_baja_sist=$(echo $fecha_baja | sed "s-\---g") 2> "/dev/null"

					#obtengo fecha actual en el formato que necesito
					fecha_actual=$(echo $(date +%Y)$(date +%m)$(date +%d))	
	
					# valido que el id del sistema exista
					#echo "fecha archivo: $fecha_arch"
					#echo "actual: $fecha_actual"
					#echo "${fecha_baja}"
					#echo "alta: $fecha_alta"
					#echo "alta sis: $fecha_alta_sist"


				if [ $sis_id = $sis_id1 ]; then
					    sis_hallado=true
					    if [ $fecha_arch -le $fecha_actual ]; then
						if [ $fecha_arch -ge $fecha_alta_sist ]; then
						    if [ -z $fecha_baja ]; then

							sis_valido=true
						    else
							echo "Sistema $sistema"
							echo "baja: $fecha_baja"
							if [ $fecha_arch -le $fecha_baja_sist ]; then   			    
							    sis_valido=true
							else
							    codigo_rechazo=7
							fi
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
		MoverW5.sh "$ARRIDIR/$archivo" "$ACEPDIR" "DetectaW5"
		mensaje="Se movio el archivo $archivo al directorio de aceptados"
		LoguearW5.sh "DetectaW5" "I" "$mensaje"	
			
	    else
		
		if [ $codigo_rechazo -eq 1 ]; then
		    mensaje="Error formato del archivo: $archivo. Se movio al directorio de rechazados"
		    LoguearW5.sh "DetectaW5" "E" "$mensaje"
		elif [ $codigo_rechazo -eq 2 ]; then
		    mensaje="Tipo archivo invalido: $archivo. Se movio al directorio de rechazados"
		    LoguearW5.sh "DetectaW5" "E" "$mensaje"
		elif [ $codigo_rechazo -eq 3 ]; then
		    mensaje="No existe sistema asociado al cod_id del archivo $archivo, se movio a rechazados"
		    LoguearW5.sh "DetectaW5" "E" "$mensaje"
		elif [ $codigo_rechazo -eq 4 ]; then
		    mensaje="Fecha invalida en el $archivo, se movio al directorio de rechazados"
		    LoguearW5.sh "DetectaW5" "E" "$mensaje"
		elif [ $codigo_rechazo -eq 5 ]; then
		    mensaje="Error, fecha posterior a la actual. Se movio el archivo $archivo a rechazados"
		    LoguearW5.sh "DetectaW5" "E" "$mensaje"
		elif [ $codigo_rechazo -eq 6 ]; then
		    mensaje="Error, fecha anterior a la de Alta. Se movio el archivo $archivo a rechazados"
		    LoguearW5.sh "DetectaW5" "E" "$mensaje"
		elif [ $codigo_rechazo -eq 7 ]; then
		    mensaje="Error, fecha posterior a la de Baja. Se movio el archivo $archivo a rechazados"
		    LoguearW5.sh "DetectaW5" "E" "$mensaje"
		fi		
		#habilitar lo que sigue cuando se integre todo			
		MoverW5.sh "$ARRIDIR/$archivo" "$RECHDIR" "DetectaW5"
					
		#comentar lo que sigue cuando se integre
		#mv $ARRIDIR/$archivo $RECHDIR/$archivo
	    fi
		    

	    #vuelvo a ponerlo en false para analizar el siguiente archivo
	    sis_valido=false
	    fecha_valida=false
	
	done #for - de archivos
    

    #chequeo existencia de archivos en directorio ACEPDIR
    
    ls -1p "$ACEPDIR" | grep -v /\$ > "${TEMPDIR}/.archivos_acep_temp"
    cant_acep=$(wc -l < "${TEMPDIR}/.archivos_acep_temp")
    
    #si existen archivos en ACEPDIR ejecuto commando BuscarW5.sh
    if [ $cant_acep -ne 0 ]; then
	
	BuscarW5.sh 
    fi

	tiempo_espera=10
	for j in $(seq 1 $tiempo_espera)
	do
		if  [ -e "${TEMPDIR}/.cont_temp" ]; then 
			sleep 1s
		else 
			j=$tiempo_espera
		fi
	done
	
    #sleep 10s
    rm "${TEMPDIR}/.archivos_temp"
    rm "${TEMPDIR}/.cod_sis_temp"
    rm "${TEMPDIR}/.archivos_acep_temp"

done
