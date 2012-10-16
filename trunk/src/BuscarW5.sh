#!/bin/bash

#variable interna
error_ambiente=false

##borrar
#GRUPO="./"
#ACEPDIR="acepdir"
#CONFDIR="confdir"
#CONFARCH="confdir/InstalaW5.conf"
#PROCDIR="procdir"
#RECHDIR="rechdir"
#MAEDIR="maedir"
#ARRIDIR="arridir"


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
elif [ -z $MAEDIR ]; then
        error_ambiente=true
elif [ -z $CONFDIR ]; then
        error_ambiente=true
fi

#verifico existencia de directorios
if [ ! -d $GRUPO$ARRIDIR -o ! -d $GRUPO$RECHDIR -o ! -d $GRUPO$ACEPDIR -o ! -d $GRUPO$PROCDIR -o ! -d $GRUPO$MAEDIR -o ! -d $GRUPO$CONFDIR ]; then
        error_ambiente=true
fi

#verifico que no haya error de inicializacion de ambiente
if [ $error_ambiente != false ]; then
	echo "Error: No se puede iniciar BuscarW5, inicializacion del ambiente erronea"
	exit 1
fi


#Cuento la cantidad de archivos a procesar

#Guardo archivos de ARRIDIR en un temporal
ls -1p $GRUPO$ACEPDIR | grep -v /\$ > .temp_archivosB

#Cuento cantidad de archivos
cant_archivos=$(wc -l < .temp_archivosB)

#Busco numero de ciclo en archivo de configuracion y lo actualizo
nro_ciclo=$(grep 'SECUENCIA2=[0-9]' $GRUPO$CONFARCH | sed 's/\(SECUENCIA2=\)\([0-9][0-9]*\)/\2/' ) 
nro_ciclo=`expr $nro_ciclo + 1`

sed 's/\(SECUENCIA2=\)\([0-9][0-9]*\)/\1'${nro_ciclo}'/'  $GRUPO$CONFARCH

#Inicializar el log
sh LoguearW5.sh "BuscarW5" "I" "Inicio BuscarW5 - Ciclo Nro.: ${nro_ciclo} - Cantidad de Archivos ${cant_archivos}"

#Inicializo variables
cant_hzgo=0
cant_s_hzgo=0
cant_s_patron=0

#Procesar archivos aceptados

while read linea; do
	#Logueo
	sh LoguearW5.sh "BuscarW5" "I" "Archivo a procesar: ${linea}"

	#Verifico que el archivo no haya sido procesado
	if [ $(find $GRUPO$PROCDIR -name $linea | wc -l) -eq 1 ]
	then
		#Logueo y muevo el archivo
		sh LoguearW5.sh "BuscarW5" "I" "Archivo ${linea} ya se encuentra procesado"
		#comentar lo que sigue cuando se integre
		mv $GRUPO$ACEPDIR/$linea $GRUPO$RECHDIR/$linea
	fi

	#Inicializo variables
	conpatron=0
	conhallazgo=0

	#Recorro archivo de patrones
	while read lineap; do
		
		#separo los campos
		pat_id=$(echo $lineap | cut -d \, -f 1)
		pat_exp=$(echo $lineap | cut -d \, -f 2)
		sis_id=$(echo $lineap | cut -d \, -f 3)
		pat_con=$(echo $lineap | cut -d \, -f 4)
		desde=$(echo $lineap | cut -d \, -f 5)
		hasta=$(echo $lineap | cut -d \, -f 6)
		nhasta=$(echo $hasta | grep -o '[0-9][0-9]*')
		sis_id1=$(echo $linea | cut -d \_ -f 1) 
	
		if [ $sis_id1 = $sis_id ];
		then 	
			conpatron=1
			cant_hzgo_arch=0
			separador="+-#-+"
			nro_linea=0

			bus="grep -n  $pat_exp  $GRUPO$ACEPDIR/$linea >> .busqueda"
			eval $bus 
			cant_hzgo_arch=$(wc -l < .busqueda)

			if [ $cant_hzgo_arch > 0 ];
			then
				conhallazgo=1	
				
				#calculo cuantos caracteres o lineas debo guardar	
				cuantos=1
				let cuantos+=nhasta
				let cuantos-=desde
				
				#si tengo que guardar lineas
				if [ "$pat_con" = "linea" ]; then			
					while read linealog; do
						nro_linealog=$(echo $linealog | cut -d \: -f 1)
						let nro_linealog-=1
						let nro_linealog+=desde

						while [ $cuantos -ne 0 ]; do
							let cuantos-=1
							
							hallar="head -$nro_linealog $GRUPO$ACEPDIR/$linea | tail -1" 
							hallado=$(eval $hallar)
							echo "${nro_ciclo}${separador}${linea}${separador}${nro_linealog}${separador}${hallado}" >> $GRUPO$PROCDIR/resultados."${pat_id}"			
						let nro_linealog+=1						
						done
					done < .busqueda
				
				#si tengo que guardar caracteres					
				elif [ "$pat_con" = "caracter" ]; then
			
					while read linealog; do
						nro_linealog=$(echo -e $linealog | cut -d \: -f 1)
						#busco patron en la linea
						pos_hal="echo cambiarrrrrrrrrrrrrrrrrrrrr|grep -bo $pat_exp"                                                      
						pos_hall=$(eval $pos_hal)
						pos_hallado=$(echo $pos_hall | cut -d\: -f1)
						hastacar=0
						let hastacar+=cuantos
						let hastacar+=pos_hallado
						hallado=$(echo $linealog|cut -c$pos_hallado-$hastacar) 
						echo "${nro_ciclo}${separador}${linea}${separador}${nro_linealog}${separador}${hallado}" >> $GRUPO$PROCDIR/resultados."${pat_id}"			
					done < .busqueda
				fi  	
			fi
			rm .busqueda
			echo "${nro_ciclo},${linea},${cant_hzgo_arch},${pat_exp},${pat_con},${desde},${hasta}" >> $GRUPO$PROCDIR/rglobales."${pat_id}"
		fi
		
	done < $GRUPO$MAEDIR/patrones	

	if [ $conhallazgo -eq 1 ]; then 
		let cant_hzgo+=1
	else 
		let cant_s_hzgo+=1
	fi

	if [ $conpatron -eq 0 ]; then 
		sh LoguearW5.sh "BuscarW5" "I" "No hay patrones aplicables para este archivo"
		let cant_s_patron+=1
	fi

	#comentar lo que sigue cuando se integre
	mv $GRUPO$ACEPDIR/$linea $GRUPO$PROCDIR/$linea
	
done < .temp_archivosB


#fin de todos los archivos procesados
sh LoguearW5.sh "BuscarW5" "I" "Fin de ciclo: ${nro_ciclo} - Cantidad de Archivos con Hallazgos: ${cant_hzgo} - Cantidad de Archivos sin Hallazgos: ${cant_s_hzgo} - Cantidad de Archivos sin Patron aplicable: ${cant_s_patron} "

#Borro archivos temporales
rm .temp_archivosB



