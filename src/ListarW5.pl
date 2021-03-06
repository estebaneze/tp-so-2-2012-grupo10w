#!/usr/bin/perl -w

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


# MAEDIR/patrones
# .........................................................
# | Campo                       | Tipo         | Variable |
# ---------------------------------------------------------
# | Id de Patrón                | numérico     | PAT_ID   |
# |.......................................................|
# | Expresión Regular a aplicar | caracteres   | PAT_EXP  |
# |.......................................................|
# | Código de Sistema           | numérico     | SIS_ID   |
# |.......................................................|
# | Contexto de resultado       | 1 Carácter,  | PAT_CON  |
# |                             | valores      |          |
# |                             | posibles:    |          |
# |                             | Línea,       |          |
# |                             | Carácter     |          |
# |.......................................................|
# | Punto de Partida de         | numérico     | DESDE    |
# | aplicación del contexto     |              |          |
# |.......................................................|
# | Punto de Fin de aplicación  | numérico     | HASTA    |
# | del contexto                |              |          |
# ---------------------------------------------------------


#MAEDIR/sistemas
# .........................................................
# | Campo                       | Tipo         | Variable |
# ---------------------------------------------------------
# | Código de Sistema           | numérico     | SIS_ID   |
# |.......................................................|
# | Nombre del Sistema          | caracteres   | SIS_NOM  |
# |.......................................................|
# | Fecha de Alta               | fecha        | SIS_ALTA |
# |.......................................................|
# | Fecha de Baja               | fecha        | SIS_BAJA |
# --------------------------------------------------------






use strict;
use warnings;
use Getopt::Std;

# Subrutinas
sub mensaje_ayuda {
    print "ListarW5\n";
    print "\n";
    print "Modo de uso:\n";
    print "  -h\n";
    print "     muestra este mensaje y sale\n";
    print "  -g\n";
    print "     resuelve consultas globales\n";
    print "  -r\n";
    print "     resuelve consultas de resultados\n";
    print "  -x\n";
    print "     graba el resultado de las consultas\n";
}

sub get_cantidad_reportes {
    # Obtengo la cantidad de reportes ya guardados en REPODIR
    # Para eso, hago un grep con el formato de nombre los reportes
    my $cant_reportes = 0;

    if ( exists( $ENV{"REPODIR"} ) ) {
        my $dir = $ENV{"REPODIR"};

        opendir(DIR, $dir) or die $!;

        my @reportes
                = grep { 
                        /^salida_[0-9]{3}$/
                            && -f "$dir/$_"
                        } readdir(DIR);

        $cant_reportes = @reportes;

        closedir(DIR);
    }

    return $cant_reportes;
}

sub get_proximo_nombre_reporte {
    # • El nombre del archivo que se graba al emitir el informe
    #   debe ser salida_xxx donde xxx es un descriptor siempre
    #   distinto que asegura no sobrescribir ningún informe
    #   previo.
    my $nuevo_nombre = "/dev/null";
    # Genero el nuevo nombre, obteniendo la cantidad de reportes, mas uno
    # y prependeandole 'salida_'
    if ( exists( $ENV{"REPODIR"} ) ) {
        my $cant_reportes = get_cantidad_reportes();
        $nuevo_nombre = $ENV{"REPODIR"}."/"."salida_";
        $nuevo_nombre = $nuevo_nombre.sprintf( "%03d", $cant_reportes + 1 );
    }
    return $nuevo_nombre;
}

sub cargar_rglobales {
    my %rglobales = ();

    if ( ! exists( $ENV{"PROCDIR"} ) ) {
       print "Error: (ListarW5) Variable de Ambiente PROCDIR no seteada.\n";
       exit 1;
    }
    if ( ! exists( $ENV{"PROCDIR"} ) ) {
       print "Error: (ListarW5) Directorio PROCDIR no existe.\n";
       exit 1;
    }

    if ( exists( $ENV{"PROCDIR"} ) ) {
        my $dir = $ENV{"PROCDIR"};

        opendir(DIR, $dir) or die $!;

        my @archivos_resultado
                = grep { 
                        /^rglobales.[0-9]*$/
                            && -f "$dir/$_"
                        } readdir(DIR);

        closedir(DIR);

        foreach my $archivo ( @archivos_resultado ){
            my $reg_count = 0;
            my $pat_id = substr $archivo, index( $archivo, "." ) + 1;

            my $path = $dir."/".$archivo;
            open(FILE, $path ) or die ("Error: (ListarW5)\n");
            my @contenido_archivo = <FILE>;
            close(FILE);

            foreach my $linea_archivo (@contenido_archivo) {
                my @valores_resultado = split(',',$linea_archivo);
                my $cantidad_campos = @valores_resultado;
                if ( $cantidad_campos == 7 ) {
                    $rglobales{ $pat_id }{ $reg_count } = { 
                        ciclo     => $valores_resultado[ 0 ],
                        nombre    => $valores_resultado[ 1 ],
                        cantidad  => $valores_resultado[ 2 ],
                        regexp    => $valores_resultado[ 3 ],
                        contexto  => $valores_resultado[ 4 ],
                        desde     => $valores_resultado[ 5 ],
                        hasta     => $valores_resultado[ 6 ],
                    };
                    $reg_count++;
                } else {
                    print "Warning! archivo: $archivo defectuoso.\n";
                    print "Formato de linea inesperado:\n$linea_archivo\n";
                }
            }
        }
    }

    return %rglobales;
}

sub cargar_resultados {
    my %resultados = ();

    if ( ! exists( $ENV{"PROCDIR"} ) ) {
       print "Error: (ListarW5) Variable de Ambiente PROCDIR no seteada.\n";
       exit 1;
    }
    if ( ! exists( $ENV{"PROCDIR"} ) ) {
       print "Error: (ListarW5) Directorio PROCDIR no existe.\n";
       exit 1;
    }

    if ( exists( $ENV{"PROCDIR"} ) ) {
        my $dir = $ENV{"PROCDIR"};

        opendir(DIR, $dir) or die $!;

        my @archivos_resultado
                = grep { 
                        /^resultados.[0-9]*$/
                            && -f "$dir/$_"
                        } readdir(DIR);

        closedir(DIR);

        foreach my $archivo ( @archivos_resultado ){
            my $reg_count = 0;
            my $pat_id = substr $archivo, index( $archivo, "." ) + 1;

            my $path = $dir."/".$archivo;
            open(FILE, $path ) or die ("Error: (ListarW5)\n");
            my @contenido_archivo = <FILE>;
            close(FILE);

            foreach my $linea_archivo (@contenido_archivo) {
                my @valores_resultado = split('\+\-\#\-\+',$linea_archivo);
                my $cantidad_campos = @valores_resultado;
                if ( $cantidad_campos == 4 ) {
                    $resultados{ $pat_id }{ $reg_count } = { 
                        ciclo     => $valores_resultado[ 0 ],
                        nombre    => $valores_resultado[ 1 ],
                        registro  => $valores_resultado[ 2 ],
                        resultado => $valores_resultado[ 3 ],
                    };
                    $reg_count++;
                } else {
                    print "Warning! archivo: $archivo defectuoso.\n";
                    print "Formato de linea inesperado:\n$linea_archivo\n";
                }
            }
        }
    }

    return %resultados;
}

sub cargar_patrones {

    my $maestro_patrones = "";

    if ( exists( $ENV{"MAEDIR"} ) ) {
        $maestro_patrones = $ENV{"MAEDIR"}."/patrones";
        if (! -e $maestro_patrones ) {
            print "Error: (ListarW5) maestro de patrones no existe.\n";
            exit 1;
        }
    } else {
        print "Error: (ListarW5) Variable de Ambiente MAEDIR no seteada.\n";
        exit 1;
    }

    open(FILE, $maestro_patrones ) or die("Error: (ListarW5) patrones.\n");
    my @contenido_patrones = <FILE>;
    close(FILE);

    my %patrones = ();

    foreach my $linea_patron (@contenido_patrones) {
        my @valores_patron = split(',', $linea_patron );
        $patrones{ $valores_patron[0] }{pat_exp} = $valores_patron[1];
        $patrones{ $valores_patron[0] }{sis_id}  = $valores_patron[2];
        $patrones{ $valores_patron[0] }{pat_con} = $valores_patron[3];
        $patrones{ $valores_patron[0] }{desde}   = $valores_patron[4];
        $patrones{ $valores_patron[0] }{hasta}   = $valores_patron[5];
    }

    return %patrones;
}

sub cargar_sistemas {

    my $maestro_sistemas = "";

    if ( exists( $ENV{"MAEDIR"} ) ) {
        $maestro_sistemas = $ENV{"MAEDIR"}."/sistemas";
        if (! -e $maestro_sistemas ) {
            print "Error: (ListarW5) maestro de sistemas no existe.\n";
            exit 1;
        }
    } else {
        print "Error: (ListarW5) Variable de Ambiente MAEDIR no seteada.\n";
        exit 1;
    }

    open(FILE, $maestro_sistemas ) or die("Error: (ListarW5) sistemas.\n");
    my @contenido_sistemas = <FILE>;
    close(FILE);

    my %sistemas = ();

    foreach my $linea_sistema (@contenido_sistemas) {
        my @valores_sistema = split(',', $linea_sistema );
        $sistemas{ $valores_sistema[0] }{sis_nom}  = $valores_sistema[1];
        $sistemas{ $valores_sistema[0] }{sis_alta} = $valores_sistema[2];
        $sistemas{ $valores_sistema[0] }{sis_baja} = $valores_sistema[3];
    }

    return %sistemas;
}
my $grabar_reporte_en = "";




#opcion -r

my $linea_separadora = "-"x79;
my %resultados = cargar_resultados(); 
my %rglobales = cargar_rglobales();

my %sistemas = cargar_sistemas();
my %sistemas_seleccionados = ();
globales_sistemas_ingresar_todos();

my %patrones = cargar_patrones();
my %patrones_seleccionados = ();

my %ciclos = get_ciclos();
my %ciclos_seleccionados = ();

my %archivos = get_archivos();
my %archivos_seleccionados = ();

resultados_patrones_ingresar_todos();
resultados_archivos_ingresar_todos();
resultados_ciclos_ingresar_todos();

my %ciclos_globales = get_ciclos_globales();
my %ciclos_seleccionados_globales = ();
globales_ciclos_ingresar_todos();

my %archivos_globales = get_archivos_globales();
my %archivos_seleccionados_globales = ();
globales_archivos_ingresar_todos();

sub get_ciclos_globales {
    my %ciclos = ();

    for my $pat_id ( keys %rglobales ) {
        for my $linea ( keys %{$rglobales{ $pat_id }} ){
            my $ciclo = $rglobales{ $pat_id }{ $linea }{ ciclo };
            $ciclos{ $ciclo } = 1;
        }
    }
    return %ciclos;
}

sub get_ciclos {
    my %ciclos = ();

    for my $pat_id ( keys %resultados ) {
        for my $linea ( keys %{$resultados{ $pat_id }} ){
            my $ciclo = $resultados{ $pat_id }{ $linea }{ ciclo };
            $ciclos{ $ciclo } = 1;
        }
    }
    return %ciclos;
}

sub get_archivos {
    my %archivos = ();
    for my $pat_id ( keys %resultados ) {
        for my $linea ( keys %{$resultados{ $pat_id }} ){
            my $archivo = $resultados{ $pat_id }{ $linea }{ nombre };
            $archivos{ $archivo } = 1;
        }
    }
    return %archivos;
}

sub get_archivos_globales {
    my %archivos = ();
    for my $pat_id ( keys %rglobales ) {
        for my $linea ( keys %{$rglobales{ $pat_id }} ){
            my $archivo = $rglobales{ $pat_id }{ $linea }{ nombre };
            $archivos{ $archivo } = 1;
        }
    }
    return %archivos;
}


my $proceso_listo = 0;

sub resultados_generar_reporte;


sub resultados_salir {
    exit 0;
}

my $proceso_estado = "inicio";

#..................
sub resultados_welcome {
    my $indent = " "x( 2 ) ;
    print $indent."Opcion de Listado de Resultados.\n";
    print $indent."Elija una opcion.\n";
}

#..........................................................................
sub resultados_ver_patrones {
    $proceso_estado = "patrones_ver";
}

sub resultados_patrones_disponibles_y_elegidos {
    my $indent = " "x(2);
    print $indent."Patrones Disponibles:\n";
    for my $pat_id ( keys %patrones ) {
        my $pat_exp = $patrones{ $pat_id }{pat_exp};
        print $indent.$indent."$pat_id: $pat_exp \n";
    }
    print $indent."Patrones Seleccionados:\n";
    for my $pat_id ( keys %patrones_seleccionados ) {
        my $pat_exp = $patrones_seleccionados{ $pat_id }{pat_exp};
        print $indent.$indent."$pat_id: $pat_exp \n";
    }
}
#..........................................................................
sub resultados_patrones_ingresar {
    $proceso_estado = "patrones_ingresar";
}

sub resultados_patrones_ingresar_callback {
    my $arg = shift;
    if ( defined $patrones{ $arg } ) {
        $patrones_seleccionados{ $arg } = $patrones{ $arg };
    }
}
#..........................................................................
sub resultados_patrones_borrar {
    $proceso_estado = "patrones_borrar";
}

sub resultados_patrones_borrar_callback {
    my $arg = shift;
    if ( defined $patrones_seleccionados{ $arg } ) {
        delete $patrones_seleccionados{ $arg };
    }
}
#..........................................................................
sub resultados_patrones_todos {
    $proceso_estado = "patrones_todos";
}

sub resultados_patrones_ingresar_todos {
    for my $pat_id ( keys %patrones ) {
        $patrones_seleccionados{ $pat_id } = $patrones{ $pat_id };
    }
}

sub resultados_patrones_borrar_todos {
    for my $pat_id ( keys %patrones_seleccionados ) {
        delete $patrones_seleccionados{ $pat_id };
    }
}
#..........................................................................

sub resultados_ver_ciclos {
    $proceso_estado = "ciclos_ver";
}

sub resultados_ciclos_disponibles_y_elegidos {
    my $indent = " "x(2);
    print $indent."Ciclos Disponibles:\n";
    for my $ciclo ( keys %ciclos ) {
        print $indent.$indent."$ciclo \n";
    }
    print $indent."Ciclos Seleccionados:\n";
    for my $ciclo ( keys %ciclos_seleccionados ) {
        print $indent.$indent."$ciclo \n";
    }
}
#..........................................................................
sub resultados_ciclos_ingresar {
    $proceso_estado = "ciclos_ingresar";
}

sub resultados_ciclos_ingresar_callback {
    my $arg = shift;
    if ( defined $ciclos{ $arg } ) {
        $ciclos_seleccionados{ $arg } = $ciclos{ $arg };
    }
}
#..........................................................................
sub resultados_ciclos_borrar {
    $proceso_estado = "ciclos_borrar";
}

sub resultados_ciclos_borrar_callback {
    my $arg = shift;
    if ( defined $ciclos_seleccionados{ $arg } ) {
        delete $ciclos_seleccionados{ $arg };
    }
}
#..........................................................................
sub resultados_ciclos_todos {
    $proceso_estado = "ciclos_todos";
}

sub resultados_ciclos_ingresar_todos {
    for my $ciclo ( keys %ciclos ) {
        $ciclos_seleccionados{ $ciclo } = $ciclos{ $ciclo };
    }
}

sub resultados_ciclos_borrar_todos {
    for my $ciclo ( keys %ciclos_seleccionados ) {
        delete $ciclos_seleccionados{ $ciclo };
    }
}
#..........................................................................
#..........................................................................

sub resultados_ver_archivos {
    $proceso_estado = "archivos_ver";
}

sub resultados_archivos_disponibles_y_elegidos {
    my $indent = " "x(2);
    print $indent."Archivos Disponibles:\n";
    for my $archivo ( keys %archivos ) {
        print $indent.$indent."$archivo \n";
    }
    print $indent."Archivos Seleccionados:\n";
    for my $archivo ( keys %archivos_seleccionados ) {
        print $indent.$indent."$archivo \n";
    }
}
#..........................................................................
sub resultados_archivos_ingresar {
    $proceso_estado = "archivos_ingresar";
}

sub resultados_archivos_ingresar_callback {
    my $arg = shift;
    if ( defined $archivos{ $arg } ) {
        $archivos_seleccionados{ $arg } = $archivos{ $arg };
    }
}
#..........................................................................
sub resultados_archivos_borrar {
    $proceso_estado = "archivos_borrar";
}

sub resultados_archivos_borrar_callback {
    my $arg = shift;
    if ( defined $archivos_seleccionados{ $arg } ) {
        delete $archivos_seleccionados{ $arg };
    }
}
#..........................................................................
sub resultados_archivos_todos {
    $proceso_estado = "archivos_todos";
}

sub resultados_archivos_ingresar_todos {
    for my $archivo ( keys %archivos ) {
        $archivos_seleccionados{ $archivo } = $archivos{ $archivo };
    }
}

sub resultados_archivos_borrar_todos {
    for my $archivo ( keys %archivos_seleccionados ) {
        delete $archivos_seleccionados{ $archivo };
    }
}
#..........................................................................
#..........................................................................
#..........................................................................
sub globales_welcome {
    my $indent = " "x( 2 ) ;
    print $indent."Totales de Hallazgos.\n";
    print $indent."Elija una opcion.\n";
}
#..........................................................................
sub globales_salir {
    exit 0;
}
#..........................................................................
sub globales_ver_patrones {
    $proceso_estado = "globales_patrones_ver";
}

sub globales_patrones_disponibles_y_elegidos {
    my $indent = " "x(2);
    print $indent."Patrones Disponibles:\n";
    for my $pat_id ( keys %patrones ) {
        my $pat_exp = $patrones{ $pat_id }{pat_exp};
        print $indent.$indent."$pat_id: $pat_exp \n";
    }
    print $indent."Patrones Seleccionados:\n";
    for my $pat_id ( keys %patrones_seleccionados ) {
        my $pat_exp = $patrones_seleccionados{ $pat_id }{pat_exp};
        print $indent.$indent."$pat_id: $pat_exp \n";
    }
}
#..........................................................................
sub globales_patrones_ingresar {
    $proceso_estado = "globales_patrones_ingresar";
}

sub globales_patrones_ingresar_callback {
    my $arg = shift;
    if ( defined $patrones{ $arg } ) {
        $patrones_seleccionados{ $arg } = $patrones{ $arg };
    }
}
#..........................................................................
sub globales_patrones_borrar {
    $proceso_estado = "globales_patrones_borrar";
}

sub globales_patrones_borrar_callback {
    my $arg = shift;
    if ( defined $patrones_seleccionados{ $arg } ) {
        delete $patrones_seleccionados{ $arg };
    }
}
#..........................................................................
sub globales_patrones_todos {
    $proceso_estado = "globales_patrones_todos";
}

sub globales_patrones_ingresar_todos {
    for my $pat_id ( keys %patrones ) {
        $patrones_seleccionados{ $pat_id } = $patrones{ $pat_id };
    }
}

sub globales_patrones_borrar_todos {
    for my $pat_id ( keys %patrones_seleccionados ) {
        delete $patrones_seleccionados{ $pat_id };
    }
}
#..........................................................................
sub globales_ver_ciclos {
    $proceso_estado = "globales_ciclos_ver";
}

sub globales_ciclos_disponibles_y_elegidos {
    my $indent = " "x(2);
    print $indent."Ciclos Disponibles:\n";
    for my $ciclo ( keys %ciclos_globales ) {
        print $indent.$indent."$ciclo \n";
    }
    print $indent."Ciclos Seleccionados:\n";
    for my $ciclo ( keys %ciclos_seleccionados_globales ) {
        print $indent.$indent."$ciclo \n";
    }
}
#..........................................................................
sub globales_ciclos_ingresar {
    $proceso_estado = "globales_ciclos_ingresar";
}

sub globales_ciclos_ingresar_callback {
    my $arg = shift;
    if ( defined $ciclos_globales{ $arg } ) {
        $ciclos_seleccionados_globales{ $arg } = $ciclos_globales{ $arg };
    }
}
#..........................................................................
sub globales_ciclos_borrar {
    $proceso_estado = "globales_ciclos_borrar";
}

sub globales_ciclos_borrar_callback {
    my $arg = shift;
    if ( defined $ciclos_seleccionados_globales{ $arg } ) {
        delete $ciclos_seleccionados_globales{ $arg };
    }
}
#..........................................................................
sub globales_ciclos_todos {
    $proceso_estado = "globales_ciclos_todos";
}

sub globales_ciclos_ingresar_todos {
    for my $ciclo ( keys %ciclos_globales ) {
        $ciclos_seleccionados_globales{ $ciclo } = $ciclos_globales{ $ciclo };
    }
}

sub globales_ciclos_borrar_todos {
    for my $ciclo ( keys %ciclos_seleccionados_globales ) {
        delete $ciclos_seleccionados_globales{ $ciclo };
    }
}

#..........................................................................
sub globales_ver_sistemas {
    $proceso_estado = "globales_sistemas_ver";
}

sub globales_sistemas_disponibles_y_elegidos {
    my $indent = " "x(2);
    print $indent."Sistemas Disponibles:\n";
    for my $sistema ( keys %sistemas ) {
        print $indent.$indent."$sistema \n";
    }
    print $indent."Sistemas Seleccionados:\n";
    for my $sistema ( keys %sistemas_seleccionados ) {
        print $indent.$indent."$sistema \n";
    }
}
#..........................................................................
sub globales_sistemas_ingresar {
    $proceso_estado = "globales_sistemas_ingresar";
}

sub globales_sistemas_ingresar_callback {
    my $arg = shift;
    if ( defined $sistemas{ $arg } ) {
        $sistemas_seleccionados{ $arg } = $sistemas{ $arg };
    }
}
#..........................................................................
sub globales_sistemas_borrar {
    $proceso_estado = "globales_sistemas_borrar";
}

sub globales_sistemas_borrar_callback {
    my $arg = shift;
    if ( defined $sistemas_seleccionados{ $arg } ) {
        delete $sistemas_seleccionados{ $arg };
    }
}
#..........................................................................
sub globales_sistemas_todos {
    $proceso_estado = "globales_sistemas_todos";
}

sub globales_sistemas_ingresar_todos {
    for my $sistema ( keys %sistemas ) {
        $sistemas_seleccionados{ $sistema } = $sistemas{ $sistema };
    }
}

sub globales_sistemas_borrar_todos {
    for my $sistema ( keys %sistemas_seleccionados ) {
        delete $sistemas_seleccionados{ $sistema };
    }
}
#..........................................................................

sub globales_ver_archivos {
    $proceso_estado = "globales_archivos_ver";
}

sub globales_archivos_disponibles_y_elegidos {
    my $indent = " "x(2);
    print $indent."Archivos Disponibles:\n";
    for my $archivo ( keys %archivos_globales ) {
        print $indent.$indent."$archivo \n";
    }
    print $indent."Archivos Seleccionados:\n";
    for my $archivo ( keys %archivos_seleccionados_globales ) {
        print $indent.$indent."$archivo \n";
    }
}
#..........................................................................
sub globales_archivos_ingresar {
    $proceso_estado = "globales_archivos_ingresar";
}

sub globales_archivos_ingresar_callback {
    my $arg = shift;
    if ( defined $archivos_globales{ $arg } ) {
        $archivos_seleccionados_globales{ $arg } = $archivos_globales{ $arg };
    }
}
#..........................................................................
sub globales_archivos_borrar {
    $proceso_estado = "globales_archivos_borrar";
}

sub globales_archivos_borrar_callback {
    my $arg = shift;
    if ( defined $archivos_seleccionados_globales{ $arg } ) {
        delete $archivos_seleccionados_globales{ $arg };
    }
}
#..........................................................................
sub globales_archivos_todos {
    $proceso_estado = "globales_archivos_todos";
}

sub globales_archivos_ingresar_todos {
    for my $archivo ( keys %archivos_globales ) {
        $archivos_seleccionados_globales{ $archivo } = $archivos_globales{ $archivo };
    }
}

sub globales_archivos_borrar_todos {
    for my $archivo ( keys %archivos_seleccionados_globales ) {
        delete $archivos_seleccionados_globales{ $archivo };
    }
}
#..........................................................................
#..........................................................................

my %estado = (
    inicio => {
        titulo => "Resultados",
        accion => \&resultados_welcome,
        anterior => "inicio",
        opciones => {
               'q' => {
                   descripcion => "Salir",
                   accion => \&resultados_salir,
                       },
               'p' => {
                   descripcion => "Elegir Patron",
                   accion => \&resultados_ver_patrones,
                       },
               'c' => {
                   descripcion => "Elegir Ciclos",
                   accion => \&resultados_ver_ciclos,
                       },
               'f' => {
                   descripcion => "Elegir Archivos",
                   accion => \&resultados_ver_archivos,
                       },
               'r' => {
                   descripcion => "Generar Reportes",
                   accion => \&resultados_generar_reporte,
                       },
        },
    },
    "patrones_ver" => {
        titulo => "Patrones",
        accion => \&resultados_patrones_disponibles_y_elegidos,
        anterior => "inicio",
        opciones => {
               'q' => { 
                   descripcion => "Salir",
                   accion => \&resultados_salir,
                       },
               'a' => {
                   descripcion => "Anterior",
                   accion => \&resultados_anterior,
                       },
               'i' => {
                   descripcion => "Ingresar Nuevo",
                   accion => \&resultados_patrones_ingresar,
                       },
               'd' => {
                   descripcion => "Borrar Ingresado",
                   accion => \&resultados_patrones_borrar,
                       },
               't' => {
                   descripcion => "Editar Todos",
                   accion => \&resultados_patrones_todos,
                       },
        },
    },
    "patrones_ingresar" => {
        titulo => "Ingresar Patrones",
        accion => \&resultados_patrones_disponibles_y_elegidos,
        callback => \&resultados_patrones_ingresar_callback,
        anterior => "patrones_ver",
        opciones => {
               'q' => {
                   descripcion => "Salir",
                   accion => \&resultados_salir,
                       }, 
               'd' => {
                   descripcion => "Borrar Ingresado",
                   accion => \&resultados_patrones_borrar,
                       },
               'a' => {
                   descripcion => "Anterior",
                   accion => \&resultados_anterior,
                       },
        },
    },
    "patrones_borrar" => {
        titulo => "Borrar Patrones",
        accion => \&resultados_patrones_disponibles_y_elegidos,
        callback => \&resultados_patrones_borrar_callback,
        anterior => "patrones_ver",
        opciones => {
               'q' => {
                   descripcion => "Salir",
                   accion => \&resultados_salir,
                       },
               'a' => {
                   descripcion => "Anterior",
                   accion => \&resultados_anterior,
                       },
               'i' => {
                   descripcion => "Ingresar Nuevo",
                   accion => \&resultados_patrones_ingresar,
                       },
        },
    },
    "patrones_todos" => {
        titulo => "Edicion Masiva de Patrones",
        accion => \&resultados_patrones_disponibles_y_elegidos,
        anterior => "patrones_ver",
        opciones => {
               'q' => {
                   descripcion => "Salir",
                   accion => \&resultados_salir,
                       }, 
               'a' => {
                   descripcion => "Anterior",
                   accion => \&resultados_anterior,
                       },
               'aa' => {
                   descripcion => "Agregar Todos",
                   accion => \&resultados_patrones_ingresar_todos,
                       },
               'da' => {
                   descripcion => "Borrar Todos",
                   accion => \&resultados_patrones_borrar_todos,
                       },
        },
    },
    "ciclos_ver" => {
        titulo => "Ciclos",
        accion => \&resultados_ciclos_disponibles_y_elegidos,
        anterior => "inicio",
        opciones => {
               'q' => { 
                   descripcion => "Salir",
                   accion => \&resultados_salir,
                       },
               'a' => {
                   descripcion => "Anterior",
                   accion => \&resultados_anterior,
                       },
               'i' => {
                   descripcion => "Ingresar Nuevo",
                   accion => \&resultados_ciclos_ingresar,
                       },
               'd' => {
                   descripcion => "Borrar Ingresado",
                   accion => \&resultados_ciclos_borrar,
                       },
               't' => {
                   descripcion => "Editar Todos",
                   accion => \&resultados_ciclos_todos,
                       },
        },
    },
    "ciclos_ingresar" => {
        titulo => "Ingresar Ciclos",
        accion => \&resultados_ciclos_disponibles_y_elegidos,
        callback => \&resultados_ciclos_ingresar_callback,
        anterior => "ciclos_ver",
        opciones => {
               'q' => {
                   descripcion => "Salir",
                   accion => \&resultados_salir,
                       }, 
               'd' => {
                   descripcion => "Borrar Ingresado",
                   accion => \&resultados_ciclos_borrar,
                       },
               'a' => {
                   descripcion => "Anterior",
                   accion => \&resultados_anterior,
                       },
        },
    },
    "ciclos_borrar" => {
        titulo => "Borrar Ciclos",
        accion => \&resultados_ciclos_disponibles_y_elegidos,
        callback => \&resultados_ciclos_borrar_callback,
        anterior => "ciclos_ver",
        opciones => {
               'q' => {
                   descripcion => "Salir",
                   accion => \&resultados_salir,
                       },
               'a' => {
                   descripcion => "Anterior",
                   accion => \&resultados_anterior,
                       },
               'i' => {
                   descripcion => "Ingresar Nuevo",
                   accion => \&resultados_ciclos_ingresar,
                       },
        },
    },
    "ciclos_todos" => {
        titulo => "Edicion Masiva de Ciclos",
        accion => \&resultados_ciclos_disponibles_y_elegidos,
        anterior => "ciclos_ver",
        opciones => {
               'q' => {
                   descripcion => "Salir",
                   accion => \&resultados_salir,
                       }, 
               'a' => {
                   descripcion => "Anterior",
                   accion => \&resultados_anterior,
                       },
               'aa' => {
                   descripcion => "Agregar Todos",
                   accion => \&resultados_ciclos_ingresar_todos,
                       },
               'da' => {
                   descripcion => "Borrar Todos",
                   accion => \&resultados_ciclos_borrar_todos,
                       },
        },
    },
    "archivos_ver" => {
        titulo => "Archivos",
        accion => \&resultados_archivos_disponibles_y_elegidos,
        anterior => "inicio",
        opciones => {
               'q' => { 
                   descripcion => "Salir",
                   accion => \&resultados_salir,
                       },
               'a' => {
                   descripcion => "Anterior",
                   accion => \&resultados_anterior,
                       },
               'i' => {
                   descripcion => "Ingresar Nuevo",
                   accion => \&resultados_archivos_ingresar,
                       },
               'd' => {
                   descripcion => "Borrar Ingresado",
                   accion => \&resultados_archivos_borrar,
                       },
               't' => {
                   descripcion => "Editar Todos",
                   accion => \&resultados_archivos_todos,
                       },
        },
    },
    "archivos_ingresar" => {
        titulo => "Ingresar Archivos",
        accion => \&resultados_archivos_disponibles_y_elegidos,
        callback => \&resultados_archivos_ingresar_callback,
        anterior => "archivos_ver",
        opciones => {
               'q' => {
                   descripcion => "Salir",
                   accion => \&resultados_salir,
                       }, 
               'd' => {
                   descripcion => "Borrar Ingresado",
                   accion => \&resultados_archivos_borrar,
                       },
               'a' => {
                   descripcion => "Anterior",
                   accion => \&resultados_anterior,
                       },
        },
    },
    "archivos_borrar" => {
        titulo => "Borrar Archivos",
        accion => \&resultados_archivos_disponibles_y_elegidos,
        callback => \&resultados_archivos_borrar_callback,
        anterior => "archivos_ver",
        opciones => {
               'q' => {
                   descripcion => "Salir",
                   accion => \&resultados_salir,
                       },
               'a' => {
                   descripcion => "Anterior",
                   accion => \&resultados_anterior,
                       },
               'i' => {
                   descripcion => "Ingresar Nuevo",
                   accion => \&resultados_archivos_ingresar,
                       },
        },
    },
    "archivos_todos" => {
        titulo => "Edicion Masiva de Archivos",
        accion => \&resultados_archivos_disponibles_y_elegidos,
        anterior => "archivos_ver",
        opciones => {
               'q' => {
                   descripcion => "Salir",
                   accion => \&resultados_salir,
                       }, 
               'a' => {
                   descripcion => "Anterior",
                   accion => \&resultados_anterior,
                       },
               'aa' => {
                   descripcion => "Agregar Todos",
                   accion => \&resultados_archivos_ingresar_todos,
                       },
               'da' => {
                   descripcion => "Borrar Todos",
                   accion => \&resultados_archivos_borrar_todos,
                       },
        },
    },


    inicio_globales => {
        titulo => "Globales",
        accion => \&globales_welcome,
        anterior => "inicio_globales",
        opciones => {
               'q' => {
                   descripcion => "Salir",
                   accion => \&globales_salir,
                       },
               'p' => {
                   descripcion => "Elegir Patrones",
                   accion => \&globales_ver_patrones,
                       },
               'c' => {
                   descripcion => "Elegir Ciclos",
                   accion => \&globales_ver_ciclos,
                       },
               's' => {
                   descripcion => "Elegir Sistemas",
                   accion => \&globales_ver_sistemas,
                       },
               'f' => {
                   descripcion => "Elegir Archivos",
                   accion => \&globales_ver_archivos,
                       },
               'r' => {
                   descripcion => "Generar Reportes",
                   accion => \&globales_generar_reporte,
                       },
        },
    },
    "globales_patrones_ver" => {
        titulo => "Patrones",
        accion => \&globales_patrones_disponibles_y_elegidos,
        anterior => "inicio_globales",
        opciones => {
               'q' => { 
                   descripcion => "Salir",
                   accion => \&globales_salir,
                       },
               'a' => {
                   descripcion => "Anterior",
                   accion => \&globales_anterior,
                       },
               'i' => {
                   descripcion => "Ingresar Nuevo",
                   accion => \&globales_patrones_ingresar,
                       },
               'd' => {
                   descripcion => "Borrar Ingresado",
                   accion => \&globales_patrones_borrar,
                       },
               't' => {
                   descripcion => "Editar Todos",
                   accion => \&globales_patrones_todos,
                       },
        },
    },
    "globales_patrones_ingresar" => {
        titulo => "Ingresar Patrones",
        accion => \&globales_patrones_disponibles_y_elegidos,
        callback => \&globales_patrones_ingresar_callback,
        anterior => "globales_patrones_ver",
        opciones => {
               'q' => {
                   descripcion => "Salir",
                   accion => \&globales_salir,
                       }, 
               'd' => {
                   descripcion => "Borrar Ingresado",
                   accion => \&globales_patrones_borrar,
                       },
               'a' => {
                   descripcion => "Anterior",
                   accion => \&globales_anterior,
                       },
        },
    },
    "globales_patrones_borrar" => {
        titulo => "Borrar Patrones",
        accion => \&globales_patrones_disponibles_y_elegidos,
        callback => \&globales_patrones_borrar_callback,
        anterior => "globales_patrones_ver",
        opciones => {
               'q' => {
                   descripcion => "Salir",
                   accion => \&globales_salir,
                       },
               'a' => {
                   descripcion => "Anterior",
                   accion => \&globales_anterior,
                       },
               'i' => {
                   descripcion => "Ingresar Nuevo",
                   accion => \&globales_patrones_ingresar,
                       },
        },
    },
    "globales_patrones_todos" => {
        titulo => "Edicion Masiva de Patrones",
        accion => \&globales_patrones_disponibles_y_elegidos,
        anterior => "globales_patrones_ver",
        opciones => {
               'q' => {
                   descripcion => "Salir",
                   accion => \&globales_salir,
                       }, 
               'a' => {
                   descripcion => "Anterior",
                   accion => \&globales_anterior,
                       },
               'aa' => {
                   descripcion => "Agregar Todos",
                   accion => \&globales_patrones_ingresar_todos,
                       },
               'da' => {
                   descripcion => "Borrar Todos",
                   accion => \&globales_patrones_borrar_todos,
                       },
        },
    },



    "globales_ciclos_ver" => {
        titulo => "Ciclos",
        accion => \&globales_ciclos_disponibles_y_elegidos,
        anterior => "inicio_globales",
        opciones => {
               'q' => { 
                   descripcion => "Salir",
                   accion => \&globales_salir,
                       },
               'a' => {
                   descripcion => "Anterior",
                   accion => \&globales_anterior,
                       },
               'i' => {
                   descripcion => "Ingresar Nuevo",
                   accion => \&globales_ciclos_ingresar,
                       },
               'd' => {
                   descripcion => "Borrar Ingresado",
                   accion => \&globales_ciclos_borrar,
                       },
               't' => {
                   descripcion => "Editar Todos",
                   accion => \&globales_ciclos_todos,
                       },
        },
    },
    "globales_ciclos_ingresar" => {
        titulo => "Ingresar Ciclos",
        accion => \&globales_ciclos_disponibles_y_elegidos,
        callback => \&globales_ciclos_ingresar_callback,
        anterior => "globales_ciclos_ver",
        opciones => {
               'q' => {
                   descripcion => "Salir",
                   accion => \&globales_salir,
                       }, 
               'd' => {
                   descripcion => "Borrar Ingresado",
                   accion => \&globales_ciclos_borrar,
                       },
               'a' => {
                   descripcion => "Anterior",
                   accion => \&globales_anterior,
                       },
        },
    },
    "globales_ciclos_borrar" => {
        titulo => "Borrar Ciclos",
        accion => \&globales_ciclos_disponibles_y_elegidos,
        callback => \&globales_ciclos_borrar_callback,
        anterior => "globales_ciclos_ver",
        opciones => {
               'q' => {
                   descripcion => "Salir",
                   accion => \&globales_salir,
                       },
               'a' => {
                   descripcion => "Anterior",
                   accion => \&globales_anterior,
                       },
               'i' => {
                   descripcion => "Ingresar Nuevo",
                   accion => \&globales_ciclos_ingresar,
                       },
        },
    },
    "globales_ciclos_todos" => {
        titulo => "Edicion Masiva de Ciclos",
        accion => \&globales_ciclos_disponibles_y_elegidos,
        anterior => "globales_ciclos_ver",
        opciones => {
               'q' => {
                   descripcion => "Salir",
                   accion => \&globales_salir,
                       }, 
               'a' => {
                   descripcion => "Anterior",
                   accion => \&globales_anterior,
                       },
               'aa' => {
                   descripcion => "Agregar Todos",
                   accion => \&globales_ciclos_ingresar_todos,
                       },
               'da' => {
                   descripcion => "Borrar Todos",
                   accion => \&globales_ciclos_borrar_todos,
                       },
        },
    },

    "globales_archivos_ver" => {
        titulo => "Archivos",
        accion => \&globales_archivos_disponibles_y_elegidos,
        anterior => "inicio_globales",
        opciones => {
               'q' => { 
                   descripcion => "Salir",
                   accion => \&globales_salir,
                       },
               'a' => {
                   descripcion => "Anterior",
                   accion => \&globales_anterior,
                       },
               'i' => {
                   descripcion => "Ingresar Nuevo",
                   accion => \&globales_archivos_ingresar,
                       },
               'd' => {
                   descripcion => "Borrar Ingresado",
                   accion => \&globales_archivos_borrar,
                       },
               't' => {
                   descripcion => "Editar Todos",
                   accion => \&globales_archivos_todos,
                       },
        },
    },
    "globales_archivos_ingresar" => {
        titulo => "Ingresar Archivos",
        accion => \&globales_archivos_disponibles_y_elegidos,
        callback => \&globales_archivos_ingresar_callback,
        anterior => "globales_archivos_ver",
        opciones => {
               'q' => {
                   descripcion => "Salir",
                   accion => \&globales_salir,
                       }, 
               'd' => {
                   descripcion => "Borrar Ingresado",
                   accion => \&globales_archivos_borrar,
                       },
               'a' => {
                   descripcion => "Anterior",
                   accion => \&globales_anterior,
                       },
        },
    },
    "globales_archivos_borrar" => {
        titulo => "Borrar Archivos",
        accion => \&globales_archivos_disponibles_y_elegidos,
        callback => \&globales_archivos_borrar_callback,
        anterior => "globales_archivos_ver",
        opciones => {
               'q' => {
                   descripcion => "Salir",
                   accion => \&globales_salir,
                       },
               'a' => {
                   descripcion => "Anterior",
                   accion => \&globales_anterior,
                       },
               'i' => {
                   descripcion => "Ingresar Nuevo",
                   accion => \&globales_archivos_ingresar,
                       },
        },
    },
    "globales_archivos_todos" => {
        titulo => "Edicion Masiva de Archivos",
        accion => \&globales_archivos_disponibles_y_elegidos,
        anterior => "globales_archivos_ver",
        opciones => {
               'q' => {
                   descripcion => "Salir",
                   accion => \&globales_salir,
                       }, 
               'a' => {
                   descripcion => "Anterior",
                   accion => \&globales_anterior,
                       },
               'aa' => {
                   descripcion => "Agregar Todos",
                   accion => \&globales_archivos_ingresar_todos,
                       },
               'da' => {
                   descripcion => "Borrar Todos",
                   accion => \&globales_archivos_borrar_todos,
                       },
        },
    },

    "globales_sistemas_ver" => {
        titulo => "Sistemas",
        accion => \&globales_sistemas_disponibles_y_elegidos,
        anterior => "inicio_globales",
        opciones => {
               'q' => { 
                   descripcion => "Salir",
                   accion => \&globales_salir,
                       },
               'a' => {
                   descripcion => "Anterior",
                   accion => \&globales_anterior,
                       },
               'i' => {
                   descripcion => "Ingresar Nuevo",
                   accion => \&globales_sistemas_ingresar,
                       },
               'd' => {
                   descripcion => "Borrar Ingresado",
                   accion => \&globales_sistemas_borrar,
                       },
               't' => {
                   descripcion => "Editar Todos",
                   accion => \&globales_sistemas_todos,
                       },
        },
    },
    "globales_sistemas_ingresar" => {
        titulo => "Ingresar Sistemas",
        accion => \&globales_sistemas_disponibles_y_elegidos,
        callback => \&globales_sistemas_ingresar_callback,
        anterior => "globales_sistemas_ver",
        opciones => {
               'q' => {
                   descripcion => "Salir",
                   accion => \&globales_salir,
                       }, 
               'd' => {
                   descripcion => "Borrar Ingresado",
                   accion => \&globales_sistemas_borrar,
                       },
               'a' => {
                   descripcion => "Anterior",
                   accion => \&globales_anterior,
                       },
        },
    },
    "globales_sistemas_borrar" => {
        titulo => "Borrar Sistemas",
        accion => \&globales_sistemas_disponibles_y_elegidos,
        callback => \&globales_sistemas_borrar_callback,
        anterior => "globales_sistemas_ver",
        opciones => {
               'q' => {
                   descripcion => "Salir",
                   accion => \&globales_salir,
                       },
               'a' => {
                   descripcion => "Anterior",
                   accion => \&globales_anterior,
                       },
               'i' => {
                   descripcion => "Ingresar Nuevo",
                   accion => \&globales_sistemas_ingresar,
                       },
        },
    },
    "globales_sistemas_todos" => {
        titulo => "Edicion Masiva de Sistemas",
        accion => \&globales_sistemas_disponibles_y_elegidos,
        anterior => "globales_sistemas_ver",
        opciones => {
               'q' => {
                   descripcion => "Salir",
                   accion => \&globales_salir,
                       }, 
               'a' => {
                   descripcion => "Anterior",
                   accion => \&globales_anterior,
                       },
               'aa' => {
                   descripcion => "Agregar Todos",
                   accion => \&globales_sistemas_ingresar_todos,
                       },
               'da' => {
                   descripcion => "Borrar Todos",
                   accion => \&globales_sistemas_borrar_todos,
                       },
        },
    },

);

sub resultados_anterior {
    $proceso_estado = $estado{ $proceso_estado }{anterior};
}

sub globales_anterior {
    $proceso_estado = $estado{ $proceso_estado }{anterior};
}

sub procesar_estado {
    while ( ! $proceso_listo ) {

        print "ListarW5: $estado{ $proceso_estado }{titulo}\n\n";

        if ( defined $estado{ $proceso_estado }{accion} ) {
            $estado{ $proceso_estado }{accion}->();
        }

        print "\n";

        for my $accion ( keys %{$estado{ $proceso_estado }{opciones}} ) { 
            my $desc=$estado{$proceso_estado}{opciones}{$accion}{descripcion};
            print "$accion => $desc\n";
        }

        print "Seleccion: ";
        my $q = <STDIN>; chomp( $q );

        if ( defined $estado{ $proceso_estado }{opciones}{ $q } ) {
            $estado{ $proceso_estado }{opciones}{ $q }{accion}->( $q );
        } else {
            if ( defined $estado{ $proceso_estado }{callback} ) {
            $estado{ $proceso_estado }{callback}->( $q );
        } else {
                print "Accion no disponible.\n";
            }
        }
        print "\n$linea_separadora\n";
    }

}





sub resultados_generar_reporte {
    my $reporte = "";
    $reporte .= "ListarW5:\nReporte opcion -r\n\nFiltos:\n";
    $reporte .= "  Patrones:\n";
    for my $patron ( keys %patrones_seleccionados ) {
        $reporte .= "    $patron\n";
    }

    $reporte .= "\n";
    $reporte .= "  Ciclos:\n";
    for my $ciclo ( keys %ciclos_seleccionados ) {
        $reporte .= "    $ciclo\n";
    }

    $reporte .= "\n";
    $reporte .= "  Archivos:\n";
    for my $archivo ( keys %archivos_seleccionados ) {
        $reporte .= "    $archivo\n";
    }


    $reporte .= "\n";
    $reporte .= "Resultados:\n";


    for my $pat_id ( keys %resultados ) {
        for my $linea ( keys %{$resultados{ $pat_id }} ){
            my $ciclo     = $resultados{ $pat_id }{ $linea }{ ciclo     };
            my $nombre    = $resultados{ $pat_id }{ $linea }{ nombre    };
            my $registro  = $resultados{ $pat_id }{ $linea }{ registro  };
            my $resultado = $resultados{ $pat_id }{ $linea }{ resultado };

            if ( defined $patrones_seleccionados{ $pat_id } ) {
                if ( defined $ciclos_seleccionados{ $ciclo } ) {
                    if ( defined $archivos_seleccionados{ $nombre } ) {
                        $reporte .= "  Patron:   $pat_id\n";
                        $reporte .= "  Ciclo:    $ciclo\n";
                        $reporte .= "  Archivo:  $nombre\n";
                        $reporte .= "  Registro: $registro\n";
                        $reporte .= "\n";
                    }
                }
            }
        }
    }

    print $reporte;
    
    if ( $grabar_reporte_en ) {
        
        open  (MYFILE, '>>'.$grabar_reporte_en );
        print MYFILE $reporte;
        close (MYFILE); 

    }

    $proceso_listo = 1;
}

sub globales_generar_reporte {
    my $reporte = "";
    $reporte .= "ListarW5:\nReporte opcion -g\n\nFiltos:\n";

    $reporte .= "\n";

    $reporte .= "  Sistemas:\n";
    for my $sistema ( keys %sistemas_seleccionados ) {
        $reporte .= "    $sistema\n";
    }
    $reporte .= "\n";

    $reporte .= "  Patrones:\n";
    for my $patron ( keys %patrones_seleccionados ) {
        $reporte .= "    $patron\n";
    }

    $reporte .= "\n";
    $reporte .= "  Ciclos:\n";
    for my $ciclo ( keys %ciclos_seleccionados_globales ) {
        $reporte .= "    $ciclo\n";
    }

    $reporte .= "\n";
    $reporte .= "  Archivos:\n";
    for my $archivo ( keys %archivos_seleccionados_globales ) {
        $reporte .= "    $archivo\n";
    }

    $reporte .= "\n";
    $reporte .= "Resultados:\n";

    my %stats_sistema = ();
    my %stats_regexp = ();
    for my $pat_id ( keys %rglobales ) {
        my $sis_id = $patrones{ $pat_id }{ sis_id };
        my $pat_exp = $patrones{ $pat_id }{ pat_exp };
        for my $linea ( keys %{$rglobales{ $pat_id }} ){
            my $ciclo     = $rglobales{ $pat_id }{ $linea }{ ciclo     };
            my $nombre    = $rglobales{ $pat_id }{ $linea }{ nombre    };
            my $cantidad  = $rglobales{ $pat_id }{ $linea }{ cantidad  };
            my $contexto  = $rglobales{ $pat_id }{ $linea }{ contexto  };
            my $desde     = $rglobales{ $pat_id }{ $linea }{ desde     };
            my $hasta     = $rglobales{ $pat_id }{ $linea }{ hasta     };
            if ( defined $patrones_seleccionados{ $pat_id } ) {
                if ( defined $ciclos_seleccionados_globales{ $ciclo } ) {
                    if ( defined $archivos_seleccionados_globales{ $nombre } ) {

                        if ( defined $stats_sistema{ $sis_id } ) {
			   $stats_sistema{ $sis_id }+=1;
			} else {
			   $stats_sistema{ $sis_id }=1;
                        }
                        if ( defined $stats_regexp{ $pat_exp } ) {
			   $stats_regexp{ $pat_exp }+=1;
			} else {
			   $stats_regexp{ $pat_exp }=1;
                        }
                        $reporte .= "  Patron:   $pat_id\n";
                        $reporte .= "  Sistema:  $sis_id\n";
                        $reporte .= "  Regexp:   $pat_exp\n";
                        $reporte .= "  Ciclo:    $ciclo\n";
                        $reporte .= "  Archivo:  $nombre\n";
                        $reporte .= "  Cantidad: $cantidad\n";
                        $reporte .= "  Contexto: $contexto\n";
                        $reporte .= "  Desde:    $desde\n";
                        $reporte .= "  Hasta:    $hasta\n";
                        $reporte .= "\n";
                    }
                }
            }
        }
    }

    $reporte .= "\nEstadisticas:\n";
    $reporte .= "  Expresiones Regulares:\n    cantidad: expresion\n";
    for my $linea ( keys %stats_regexp ){
        $reporte .= "    $stats_regexp{$linea}: $linea\n";
    }
    $reporte .= "\n  Sistemas:\n    cantidad: expresion\n";
    for my $linea ( keys %stats_sistema ){
        $reporte .= "    $stats_sistema{$linea}: $linea\n";
    }



    print $reporte;
    
    if ( $grabar_reporte_en ) {
        
        open  (MYFILE, '>>'.$grabar_reporte_en );
        print MYFILE $reporte;
        close (MYFILE); 

    }

    $proceso_listo = 1;
}
# Comienzo del programa principal

my %opciones=();
getopts("hgrx", \%opciones);

# Opciones
# Opción –h

#$proceso_estado = "inicio_globales";
#procesar_estado();
#exit 0;

if ( defined $opciones{h} ) {
    # muestra la ayuda del comando y sale
    mensaje_ayuda();
    exit 0;
}

if ( defined $opciones{x} ) {
    if ( exists( $ENV{"REPODIR"} ) ) {
        $grabar_reporte_en = &get_proximo_nombre_reporte();
    } else {
        print "Error: ";
        print "(ListarW5) Variable de Ambiente REPODIR no seteada.\n";
        exit 1;
    }
}

if ( defined $opciones{g} && defined $opciones{r} ) {
    print "ListarW5 Error. opciones -g y -r mutuamente excluyentes.\n\n";
    mensaje_ayuda();
    exit 1;
}

if ( ( ! defined $opciones{g} ) && ( ! defined $opciones{r} ) ) {
    print "ListarW5 Error. Ninguna opcion elegida.\n\n";
    mensaje_ayuda();
    exit 1;
}

if ( defined $opciones{g} ) {
    $proceso_estado = "inicio_globales";
    procesar_estado();
}

if ( defined $opciones{r} ) {
    $proceso_estado = "inicio";
    procesar_estado();
}

