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


#opcion -r

my $linea_separadora = "-"x79;

my %patrones = cargar_patrones();
my %patrones_seleccionados = ();


my $proceso_listo = 0;

sub resultados_salir {
    exit 0;
}

my $proceso_estado = 0;


#..................
sub resultados_welcome {
    my $indent = " "x($proceso_estado * 2);
    print $indent."Opcion de Listado de Resultados.\n";
    print $indent."Elija una opcion.\n";
}

#..................
sub resultados_ver_patrones {
    #print "Patrones disponibles:\n";
    $proceso_estado = 1;
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

#..................
sub resultados_patrones_ingresar {
    $proceso_estado = 2;
}

sub resultados_patrones_ingresar_callback {
    my $arg = shift;
    if ( defined $patrones{ $arg } ) {
        $patrones_seleccionados{ $arg } = $patrones{ $arg };
    }
}

#..................

sub resultados_patrones_borrar {
    $proceso_estado = 3;
}

sub resultados_patrones_borrar_callback {
    my $arg = shift;
    if ( defined $patrones_seleccionados{ $arg } ) {
        delete $patrones_seleccionados{ $arg };
    }
}


my %estado = (
        0 => {
           titulo => "Resultados",
           accion => \&resultados_welcome,
           anterior => 0,
           navegacion => {
                   'q' => \&resultados_salir,
                   'p' => \&resultados_ver_patrones,
                          },
           descripcion => {
                   'q' => "Salir",
                   'p' => "Elegir Patron",
                           }
          },
        1 => {
           titulo => "Patrones",
           accion => \&resultados_patrones_disponibles_y_elegidos,
           anterior => 0,
           navegacion => {
                   'q' => \&resultados_salir,
                   'a' => \&resultados_anterior,
                   'i' => \&resultados_patrones_ingresar,
                   'd' => \&resultados_patrones_borrar,
                          },
           descripcion => {
                   'q' => "Salir",
                   'a' => "Anterior",
                   'i' => "Ingresar Nuevo",
                   'd' => "Borrar Ingresado"
                           }
              },
        2 => {
           titulo => "Ingresar Patrones",
           accion => \&resultados_patrones_disponibles_y_elegidos,
           callback => \&resultados_patrones_ingresar_callback,
           anterior => 1,
           navegacion => {
                   'q' => \&resultados_salir,
                   'a' => \&resultados_anterior,
                   'd' => \&resultados_patrones_borrar,
                          },
           descripcion => {
                   'q' => "Salir",
                   'a' => "Anterior",
                   'd' => "Borrar Ingresado"
                           }
              },
        3 => {
           titulo => "Borrar Patrones",
           accion => \&resultados_patrones_disponibles_y_elegidos,
           callback => \&resultados_patrones_borrar_callback,
           anterior => 1,
           navegacion => {
                   'q' => \&resultados_salir,
                   'a' => \&resultados_anterior,
                   'i' => \&resultados_patrones_ingresar,
                          },
           descripcion => {
                   'i' => "Ingresar Nuevo",
                   'i' => "Ingresar Nuevo",
                   'q' => "Salir",
                   'a' => "Anterior",
                           }
              }
);

sub resultados_anterior {
    $proceso_estado = $estado{ $proceso_estado }{anterior};
#   my $param = shift;
#   if ( $proceso_estado > 0 ) {
#       $proceso_estado -= 1;
#   }
}

while ( ! $proceso_listo ) {

    print "ListarW5: $estado{ $proceso_estado }{titulo}\n\n";

    if ( defined $estado{ $proceso_estado }{accion} ) {
        $estado{ $proceso_estado }{accion}->();
    }

    print "\n";
    for my $accion ( keys $estado{ $proceso_estado }{descripcion} ) { 
       my $descripcion = $estado{ $proceso_estado }{descripcion}{ $accion };
       print "$accion => $descripcion\n";
    }

    print "Seleccion: ";
    my $q = <STDIN>; chomp( $q );

    if ( defined $estado{ $proceso_estado }{navegacion}{ $q } ) {
        $estado{ $proceso_estado }{navegacion}{ $q }->( $q );
    } else {
        if ( defined $estado{ $proceso_estado }{callback} ) {
            $estado{ $proceso_estado }{callback}->( $q );
        } else {
            print "Accion no disponible.\n";
        }
    }

    print "\n$linea_separadora\n";
}




exit 0;
my $grabar_reporte_en = "";

if ( defined $opciones{x} ) {
    if ( exists( $ENV{"REPODIR"} ) ) {
        $grabar_reporte_en = &get_proximo_nombre_reporte();
    } else {
        print "Error: ";
        print "(ListarW5) Variable de Ambiente REPODIR no seteada.\n";
        exit 1;
    }
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
}

if ( defined $opciones{r} ) {
#           2.3. Opción –r
#               • La consulta listará resultados extraídos de los
#                 archivos RESULTADOS.PAT_ID
}

