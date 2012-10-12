#!/usr/bin/perl -w
#
#   Comando de consultas y listados: ListarV5 y ListarW5
#
#       DESCRIPCIÓN
#       1. El propósito de este programa perl es resolver consultas
#          efectuadas sobre los archivos de resultados globales y
#          resultados detallados
#           • Es el cuarto en orden de ejecución
#           • Se dispara manualmente
#           • No Graba en el archivo de Log
#
#       2. Opciones
#           2.1. Opción –h
#               • muestra la ayuda del comando
#           2.2. Opción –g (Opción default)
#               • La consulta resolverá consultas sobre cantidad de 
#                 hallazgos (RGLOBALES.PAT_ID)
#           2.3. Opción –r
#               • La consulta listará resultados extraídos de los
#                 archivos RESULTADOS.PAT_ID
#           2.4. Opción –x
#               • Siempre el reporte se muestra por pantalla,
#                 pero si se ingresa esta opción además debe grabarse
#                 el informe en el directorio REPODIR
#               • Esta opción puede combinarse con la opción –g y con
#                 la opción –r
#
#       3. Las opciones –g y –r son mutuamente excluyentes
#
#       4. Grabar los informes solo cuando se solicita
#           • El nombre del archivo que se graba al emitir el informe
#             debe ser salida_xxx donde xxx es un descriptor siempre
#             distinto que asegura no sobrescribir ningún informe
#             previo.
#           • Puede usar la variable SECUENCIA1 del archivo de 
#             configuración si requiere almacenar este valor.
#
#       5. Emplear estructuras Hash en la resolución 
#          (requisito indispensable)
#
#       6. Debido al alto grado de libertad que se les permite en el
#          desarrollo de este comando, documentarlo detalladamente.
#
#
#
#   REQUERIMIENTOS PARA LA OPCIÓN –r
#
#       La solución debe listar los Resultados provenientes de los 
#       archivos RESULTADOS.PAT_ID, “guiar” al usuario en el ingreso
#       de filtros (primer paso) hasta dar con los resultados que el
#       usuario está buscando (segundo paso)
#
#       Primer PASO:
#           Si ingresa un patrón, listarle todos los ciclos y archivos
#           para que elija cuales quiere ver en detalle
#           (puede indicar 1 o más de cada uno)
#
#           Si ingresa un ciclo, listarle todos los patrones-ER y 
#           archivos para que elija cuales quiere ver en detalle 
#           (puede indicar 1 o más de cada uno)
#
#           Si ingresa un archivo, listarle todos los patrones-ER para
#           que elija cuales quiere ver en detalle
#           (puede indicar 1 o más de uno)
#
#       Segundo PASO:
#           Mostrar los resultados con un titulo representativo de la
#           consulta y los filtros usados
#               • Mostrar el total de registros listados
#
#
#
#   REQUERIMIENTOS PARA LA OPCIÓN –g
#
#       La solución debe resolver consultas relacionadas con Totales 
#       de hallazgos y debe poder responder a “preguntas” tales como:
#           • ¿En qué patrón y/o sistema y/o archivo se produjo la mayor
#             cantidad de hallazgos?
#           • ¿En qué patrón y/o sistema y/o archivo NO se produjo ningún
#             hallazgo?
#           • ¿Cuáles son las 5 Expresiones Regulares que registraron la
#             mayor cantidad de hallazgos?
#           • ¿Cuáles son las 5 Expresiones Regulares que registraron la
#             menor cantidad de hallazgos?
#           • Que archivos presentaron hallazgos en el rango xx-yy
#           • Cualquier otra consulta relacionada con la cantidad de
#             hallazgos que quieran incluir
#
#       La solución debe poder aceptar filtros tales como:
#
#           • Para un patrón, dos patrones, tres patrones, etc.
#             o para todos
#           • Para un ciclo en particular, o para un rango de ciclos,
#             o para todos
#           • Para un sistema en particular, o para una lista de sistemas,
#             o para todos
#           • Para un archivo en particular, o para todos
#
#       Cuando corresponde ingresar:
#           • Patrón, ciclo, cantidad: validar que sean numéricos
#           • Sistema: validar que exista en el maestro de sistemas
#
#       En el Informe siempre mostrar
#           • Un titulo representativo de la consulta
#           • Los filtros usados
#           • Mostrar el total de hallazgos de lo que se esta listando


use strict;
use warnings;
use Getopt::Std;

# Subrutinas
sub mensaje_ayuda {
    print "mensaje de ayuda";
}

sub get_cantidad_reportes {
    # Obtengo la cantidad de reportes ya guardados en REPODIR
    # Para eso, hago un grep con el formato de nombre los reportes

    my $dir = $ENV{"REPODIR"};

    opendir(DIR, $dir) or die $!;

    my @reportes
            = grep { 
                    /^salida_[0-9]{3}$/
                        && -f "$dir/$_"
                    } readdir(DIR);

    my $cant_reportes = @reportes;

    closedir(DIR);

    return $cant_reportes;
}

sub get_proximo_nombre_reporte {
    # Genero el nuevo nombre, obteniendo la cantidad de reportes, mas uno
    # y prependeandole 'salida_'
    my $cant_reportes = get_cantidad_reportes();
    my $nuevo_nombre = $ENV{"REPODIR"}."/"."salida_";
    $nuevo_nombre = $nuevo_nombre.sprintf( "%03d", $cant_reportes + 1 );
    return $nuevo_nombre;
}


exit 0;

# Comienzo del programa principal

my %opciones=();
getopts("hgrx", \%opciones);

# Opciones
# Opción –h

if ( defined $opciones{h} ) {
    # muestra la ayuda del comando y sale
    mensaje_ayuda();
    exit 1;
}

if ( not defined $opciones{g} && not defined $opciones{r} ) {
    print "ListarW5 Error. Ninguna opcion elegida.\n\n";
    mensaje_ayuda();
    exit 1;
}

if ( defined $opciones{g} && defined $opciones{r} ) {
    print "ListarW5 Error. opciones -g y -r mutuamente excluyentes.\n\n";
    mensaje_ayuda();
    exit 1;
}

if ( defined $opciones{g} ) {
#           2.2. Opción –g (Opción default)
#               • La consulta resolverá consultas sobre cantidad de 
#                 hallazgos (RGLOBALES.PAT_ID)
    if ( defined $opciones{x} ) {
        print &get_proximo_nombre_reporte();
#       4. Grabar los informes solo cuando se solicita
#           • El nombre del archivo que se graba al emitir el informe
#             debe ser salida_xxx donde xxx es un descriptor siempre
#             distinto que asegura no sobrescribir ningún informe
#             previo.
    }
}

if ( defined $opciones{r} ) {
#           2.3. Opción –r
#               • La consulta listará resultados extraídos de los
#                 archivos RESULTADOS.PAT_ID
    if ( defined $opciones{x} ) {
        print &get_proximo_nombre_reporte();
#           2.4. Opción –x
#               • Siempre el reporte se muestra por pantalla,
#                 pero si se ingresa esta opción además debe grabarse
#                 el informe en el directorio REPODIR
    }
}

