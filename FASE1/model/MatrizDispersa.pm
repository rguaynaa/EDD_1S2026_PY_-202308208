package MatrizDispersa;
use strict;
use warnings;

# Matriz Dispersa: Laboratorio (filas) x Medicamento (columnas)
#
# Solo se almacenan las celdas con valor != 0
# Cada celda guarda: precio, cantidad, principio activo
#
# Estructura interna:
#   cabeceras_fila  : hashref { laboratorio => NodoCabecera }
#   cabeceras_col   : hashref { nombre_med  => NodoCabecera }
#
# Cada NodoCabecera tiene una lista de NodosValor enlazados
# Un NodoValor tiene: fila_key, col_key, datos, sig_fila, sig_col

# ---- NodoValor ----
package NodoValor;
sub new {
    my ($class, $fila, $col, $datos) = @_;
    return bless {
        fila    => $fila,
        col     => $col,
        datos   => $datos,   # hashref: { precio, cantidad, principio }
        sig_fila => undef,   # siguiente en la misma fila
        sig_col  => undef,   # siguiente en la misma columna
    }, $class;
}
sub get_fila     { $_[0]->{fila}     }
sub get_col      { $_[0]->{col}      }
sub get_datos    { $_[0]->{datos}    }
sub get_sig_fila { $_[0]->{sig_fila} }
sub get_sig_col  { $_[0]->{sig_col}  }
sub set_sig_fila { $_[0]->{sig_fila} = $_[1] }
sub set_sig_col  { $_[0]->{sig_col}  = $_[1] }

# ---- MatrizDispersa ----
package MatrizDispersa;

sub new {
    my ($class) = @_;
    my $self = {
        filas => {},   # { laboratorio => primer NodoValor de esa fila }
        cols  => {},   # { nombre_med  => primer NodoValor de esa col  }
    };
    bless $self, $class;
    return $self;
}

# ---------------------------------------------------------------
# INSERTAR o ACTUALIZAR una celda
# ---------------------------------------------------------------
sub insertar {
    my ($self, $laboratorio, $nombre_med, $datos) = @_;
    # $datos = { precio, cantidad, principio }

    # Buscar si ya existe esa celda
    my $existente = $self->_buscar_nodo($laboratorio, $nombre_med);

    if ($existente) {
        # Actualizar datos existentes
        $existente->{datos} = $datos;
        return;
    }

    # Crear nuevo nodo
    my $nuevo = NodoValor->new($laboratorio, $nombre_med, $datos);

    # Enlazar en la lista de la fila
    if (!exists $self->{filas}{$laboratorio}) {
        $self->{filas}{$laboratorio} = $nuevo;
    } else {
        # Agregar al final de la lista de esa fila
        my $actual = $self->{filas}{$laboratorio};
        while (defined $actual->get_sig_fila()) {
            $actual = $actual->get_sig_fila();
        }
        $actual->set_sig_fila($nuevo);
    }

    # Enlazar en la lista de la columna
    if (!exists $self->{cols}{$nombre_med}) {
        $self->{cols}{$nombre_med} = $nuevo;
    } else {
        my $actual = $self->{cols}{$nombre_med};
        while (defined $actual->get_sig_col()) {
            $actual = $actual->get_sig_col();
        }
        $actual->set_sig_col($nuevo);
    }
}

# ---------------------------------------------------------------
# CONSULTAR por medicamento: muestra todos los labs que lo fabrican
# ---------------------------------------------------------------
sub consultar_por_medicamento {
    my ($self, $nombre_med) = @_;

    unless (exists $self->{cols}{$nombre_med}) {
        print "No hay datos para el medicamento: $nombre_med\n";
        return;
    }

    print "\n--- Comparacion de precios: $nombre_med ---\n";
    printf "%-20s %-15s %-10s %-20s\n", "Laboratorio", "Precio (Q)", "Cantidad", "Principio Activo";
    print "-" x 70 . "\n";

    my $actual = $self->{cols}{$nombre_med};
    while (defined $actual) {
        my $d = $actual->get_datos();
        printf "%-20s %-15.2f %-10d %-20s\n",
            $actual->get_fila(),
            $d->{precio},
            $d->{cantidad},
            $d->{principio};
        $actual = $actual->get_sig_col();
    }
}

# ---------------------------------------------------------------
# LISTAR toda la matriz
# ---------------------------------------------------------------
sub listar {
    my ($self) = @_;

    if (!%{ $self->{filas} }) {
        print "La matriz esta vacia.\n";
        return;
    }

    print "\n--- Matriz Dispersa (Laboratorio x Medicamento) ---\n";

    for my $lab (sort keys %{ $self->{filas} }) {
        print "\nLaboratorio: $lab\n";
        my $actual = $self->{filas}{$lab};
        while (defined $actual) {
            my $d = $actual->get_datos();
            printf "  %-25s | Q%-8.2f | Cant: %-6d | PA: %s\n",
                $actual->get_col(),
                $d->{precio},
                $d->{cantidad},
                $d->{principio};
            $actual = $actual->get_sig_fila();
        }
    }
}

# ---------------------------------------------------------------
# GENERAR DOT para Graphviz
# ---------------------------------------------------------------
sub generar_dot {
    my ($self, $archivo) = @_;
    $archivo //= "reporte_matriz.dot";

    open my $fh, ">", $archivo or do {
        print "No se pudo crear el archivo DOT.\n";
        return;
    };

    print $fh "digraph MatrizDispersa {\n";
    print $fh "  rankdir=LR;\n";
    print $fh "  node [fontname=Arial];\n\n";

    if (!%{ $self->{filas} }) {
        print $fh "  vacio [label=\"Matriz vacia\" shape=plaintext];\n";
        print $fh "}\n";
        close $fh;
        return;
    }

    # Cabeceras de columna (medicamentos)
    print $fh "  // cabeceras de columna (medicamentos)\n";
    for my $med (sort keys %{ $self->{cols} }) {
        my $id = _id($med);
        print $fh "  col_$id [label=\"$med\" shape=rectangle style=filled fillcolor=lightblue];\n";
    }

    # Cabeceras de fila (laboratorios) y sus nodos de valor
    print $fh "\n  // cabeceras de fila (laboratorios) y valores\n";
    for my $lab (sort keys %{ $self->{filas} }) {
        my $lid = _id($lab);
        print $fh "  row_$lid [label=\"$lab\" shape=rectangle style=filled fillcolor=lightyellow];\n";

        my $actual = $self->{filas}{$lab};
        while (defined $actual) {
            my $med = $actual->get_col();
            my $mid = _id($med);
            my $d   = $actual->get_datos();
            my $vid = "v_${lid}_${mid}";

            print $fh "  $vid [label=\"Q$d->{precio}\\nCant:$d->{cantidad}\\n$d->{principio}\" shape=ellipse style=filled fillcolor=lightgreen];\n";

            # Flecha fila -> valor
            print $fh "  row_$lid -> $vid;\n";
            # Flecha valor -> cabecera columna
            print $fh "  $vid -> col_$mid;\n";

            $actual = $actual->get_sig_fila();
        }
    }

    print $fh "}\n";
    close $fh;

    my $png = $archivo;
    $png =~ s/\.dot$/.png/;
    system("dot -Tpng $archivo -o $png");
    print "Reporte generado: $png\n";
}

# ---------------------------------------------------------------
# PRIVADO: buscar un nodo especifico en la matriz
# ---------------------------------------------------------------
sub _buscar_nodo {
    my ($self, $lab, $med) = @_;
    return undef unless exists $self->{filas}{$lab};

    my $actual = $self->{filas}{$lab};
    while (defined $actual) {
        return $actual if $actual->get_col() eq $med;
        $actual = $actual->get_sig_fila();
    }
    return undef;
}

# Convierte un string a ID valido para DOT (sin espacios ni caracteres raros)
sub _id {
    my ($s) = @_;
    $s =~ s/[^a-zA-Z0-9]/_/g;
    return $s;
}

1;
