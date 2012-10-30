#!/bin/bash

#variable interna
error_ambiente=false

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
elif [ -z "$MAEDIR" ]; then
        error_ambiente=true
elif [ -z "$CONFDIR" ]; then
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
elif [ ! -d "$MAEDIR" ]; then
        error_ambiente=true
elif [ ! -d "$CONFDIR" ]; then
        error_ambiente=true
fi

#verifico que no haya error de inicializacion de ambiente
if [ $error_ambiente != false ]; then
	echo "Error: No se puede iniciar BuscarW5, inicializacion del ambiente erronea"
	exit 1
fi


#Cuento la cantidad de archivos a procesar

#Guardo archivos de ARRIDIR en un temporal
ls -1p "$ACEPDIR" | grep -v /\$ > .temp_archivosB

#Cuento cantidad de archivos
cant_archivos=$(wc -l < .temp_archivosB)

#Busco numero de ciclo en archivo de configuracion y lo actualizo
nro_ciclo=$(grep -o 'SECUENCIA2=[0-9][0-9]*' "$CONFDIR/InstalaW5.conf" | cut -d \= -f 2 ) 
let nro_ciclo+=1 

#var="sed -i 's/SECUENCIA2=[0-9][0-9]*/SECUENCIA2=${nro_ciclo}/' "$CONFDIR/InstalaW5.conf""
evalsed=$(sed -i "s/SECUENCIA2=[0-9][0-9]*/SECUENCIA2=${nro_ciclo}/" "$CONFDIR/InstalaW5.conf") 
#evalsed=$(eval $var)

#Inicializar el log
LoguearW5.sh "BuscarW5" "I" "Inicio BuscarW5 - Ciclo Nro.: ${nro_ciclo} - Cantidad de Archivos ${cant_archivos}"

#Inicializo variables
cant_hzgo=0
cant_s_hzgo=0
cant_s_patron=0

#Procesar archivos aceptados

while read linea; do
	#Logueo
	LoguearW5.sh "BuscarW5" "I" "Archivo a procesar: ${linea}"

	#Verifico que el archivo no haya sido procesado
	if [ $(find "$PROCDIR" -name $linea | wc -l) -eq 1 ]
	then
		#Logueo y muevo el archivo
		LoguearW5.sh "BuscarW5" "E" "Archivo ${linea} ya se encuentra procesado"
		#comentar lo que sigue cuando se integre
		MoverW5.sh "$ACEPDIR/$linea" "$RECHDIR" "BuscarW5"
	fi

	#Inicializo variables
	conpatron=0
	conhallazgo=0

	#Recorro archivo de patrones
	while read lineap; do
		
		#separo los campos
		pat_id=$(echo $lineap | cut -d \, -f 1)
		pat_exp=$(echo $lineap | cut -d \, -f 2)
		pat_exp=$( echo "$pat_exp" | tr -d "\'")
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

			#bus="grep -n "$pat_exp" "$ACEPDIR/$linea" >> .busqueda"
			#eval $bus
lalala="$ACEPDIR/$linea"

			grep -n "${pat_exp}" "${lalala}" >> .busqueda
#cat .busqueda
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
						cuantosguardo=$cuantos
						while [ $cuantosguardo -ne 0 ]; do
							let cuantosguardo-=1
							
							#hallar="head -$nro_linealog "$ACEPDIR/$linea" | tail -1" 
							hallado=$(head -$nro_linealog "$ACEPDIR/$linea" | tail -1)
							echo "${nro_ciclo}${separador}${linea}${separador}${nro_linealog}${separador}${hallado}" >> "${PROCDIR}/resultados.${pat_id}"			
						let nro_linealog+=1						
						done
					done < .busqueda
				
				#si tengo que guardar caracteres					
				elif [ "$pat_con" = "caracter" ]; then
				#cuento cantidad de archivos
				cant_lineasarch=$(wc -l < .busqueda)
				for i in $(seq 1 $cant_lineasarch)
					do
						IFSOLD=$IFS
						IFS="\n"
						#obtengo nombre del primer archivo
	    					linealog=$(head -n $i .busqueda | tail -n 1)
						echo $linealog >> .buslinea
						nro_linealog=$(grep -o "^[0-9][0-9]*" .buslinea)
						
						rm .buslinea
						echo $linealog | sed "s/^[0-9][0-9]*://" >>.bus 2> "/dev/null"

						#expre="grep -bo $pat_exp .bus|cut -d\: -f 1" 
						pos_hallado=$(grep -bo "$pat_exp" .bus|cut -d\: -f 1) 
						let pos_hallado+=1
						hastacar=0
						desdecar=0	
						let desdecar+=pos_hallado
						let desdecar+=desde
						let desdecar-=1
						let hastacar+=desdecar
						let hastacar+=cuantos
						let hastacar-=1

						hallado=$(cat .bus | cut -c$desdecar-$hastacar) 
						rm .bus
						IFS=$IFSOLD
						echo "${nro_ciclo}${separador}${linea}${separador}${nro_linealog}${separador}${hallado}" >> "${PROCDIR}/resultados.${pat_id}"			
					done 
				
				fi  	
			fi
			rm .busqueda
			echo "${nro_ciclo},${linea},${cant_hzgo_arch},${pat_exp},${pat_con},${desde},${hasta}" >> "${PROCDIR}/rglobales.${pat_id}"
		fi	
		
	done < "$MAEDIR/patrones"	

	if [ $conhallazgo -eq 1 ]; then 
		let cant_hzgo+=1
	else 
		let cant_s_hzgo+=1
	fi

	if [ $conpatron -eq 0 ]; then 
		LoguearW5.sh "BuscarW5" "I" "No hay patrones aplicables para este archivo"
		let cant_s_patron+=1
	fi

	#habilitar lo que sigue cuando se integre todo
        MoverW5.sh "$ACEPDIR/$linea" "$PROCDIR" "BuscarW5"
	
done < .temp_archivosB

#fin de todos los archivos procesados
LoguearW5.sh "BuscarW5" "I" "Fin de ciclo: ${nro_ciclo} - Cant Arch con Hallazgos: ${cant_hzgo} - Cant. Arch sin Hallazgos: ${cant_s_hzgo} - Cant Arch sin Patron Aplicable: ${cant_s_patron} "


#Borro archivos temporales
rm .temp_archivosB
