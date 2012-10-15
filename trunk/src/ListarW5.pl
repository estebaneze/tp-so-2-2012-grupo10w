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
    print "mensaje de ayuda";
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
        $maestro_patrones = $ENV{"MAEDIR"}."patrones";
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
        $patrones{ $valores_patron[0] } = $valores_patron[1];
    }

    return %patrones;
}

my $grabar_reporte_en = "";




#opcion -r

my $linea_separadora = "-"x79;
my %resultados = cargar_resultados(); 

my %patrones = cargar_patrones();
my %patrones_seleccionados = ();

my %ciclos = get_ciclos();
my %ciclos_seleccionados = ();

my %archivos = get_archivos();
my %archivos_seleccionados = ();

resultados_patrones_ingresar_todos();
resultados_archivos_ingresar_todos();
resultados_ciclos_ingresar_todos();


sub get_ciclos {
    my %ciclos = ();

    for my $pat_id ( keys %resultados ) {
        for my $linea ( keys $resultados{ $pat_id } ){
            my $ciclo = $resultados{ $pat_id }{ $linea }{ ciclo };
            $ciclos{ $ciclo } = 1;
        }
    }
    return %ciclos;
}

sub get_archivos {
    my %archivos = ();
    for my $pat_id ( keys %resultados ) {
        for my $linea ( keys $resultados{ $pat_id } ){
            my $archivo = $resultados{ $pat_id }{ $linea }{ nombre };
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

#my $proceso_estado = 0;
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
        my $pat_exp = $patrones{ $pat_id };
        print $indent.$indent."$pat_id: $pat_exp \n";
    }
    print $indent."Patrones Seleccionados:\n";
    for my $pat_id ( keys %patrones_seleccionados ) {
        my $pat_exp = $patrones_seleccionados{ $pat_id };
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

);

sub resultados_anterior {
    $proceso_estado = $estado{ $proceso_estado }{anterior};
}

sub procesar_estado {
    while ( ! $proceso_listo ) {

        print "ListarW5: $estado{ $proceso_estado }{titulo}\n\n";

        if ( defined $estado{ $proceso_estado }{accion} ) {
            $estado{ $proceso_estado }{accion}->();
        }

        print "\n";

        for my $accion ( keys $estado{ $proceso_estado }{opciones} ) { 
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
        for my $linea ( keys $resultados{ $pat_id } ){
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
                        $reporte .= "  Registro: $resultado\n";
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

# Comienzo del programa principal

my %opciones=();
getopts("hgrx", \%opciones);

# Opciones
# Opción –h

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

}

if ( defined $opciones{r} ) {
    procesar_estado();
}
