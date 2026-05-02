package NodoValor;
use strict;
use warnings;

sub new {
    my ($class, $fila, $col, $datos) = @_;
    return bless {
        fila     => $fila,
        col      => $col,
        datos    => $datos,   # { cantidad => N }
        sig_fila => undef,
        sig_col  => undef,
    }, $class;
}
sub get_fila     { $_[0]->{fila}     }
sub get_col      { $_[0]->{col}      }
sub get_datos    { $_[0]->{datos}    }
sub get_sig_fila { $_[0]->{sig_fila} }
sub get_sig_col  { $_[0]->{sig_col}  }
sub set_sig_fila { $_[0]->{sig_fila} = $_[1] }
sub set_sig_col  { $_[0]->{sig_col}  = $_[1] }

# ============================================================
package MatrizDispersa;
use strict;
use warnings;

# Matriz Dispersa: Proveedor (filas) x Fabricante (columnas)
# Celda: cantidad total de productos entregados por ese proveedor
# provenientes de ese fabricante

sub new {
    my ($class) = @_;
    return bless {
        filas => {},   # { proveedor_nombre => primer NodoValor }
        cols  => {},   # { fabricante       => primer NodoValor }
    }, $class;
}

# ---------------------------------------------------------------
# INSERTAR o ACUMULAR cantidad
# ---------------------------------------------------------------
sub insertar {
    my ($self, $proveedor, $fabricante, $cantidad) = @_;
    return unless $proveedor && $fabricante;

    my $existente = $self->_buscar_nodo($proveedor, $fabricante);
    if ($existente) {
        $existente->{datos}{cantidad} += $cantidad;
        return;
    }

    my $nuevo = NodoValor->new($proveedor, $fabricante, { cantidad => $cantidad });

    # Enlazar en lista de fila (proveedor)
    if (!exists $self->{filas}{$proveedor}) {
        $self->{filas}{$proveedor} = $nuevo;
    } else {
        my $actual = $self->{filas}{$proveedor};
        $actual = $actual->get_sig_fila() while defined $actual->get_sig_fila();
        $actual->set_sig_fila($nuevo);
    }

    # Enlazar en lista de columna (fabricante)
    if (!exists $self->{cols}{$fabricante}) {
        $self->{cols}{$fabricante} = $nuevo;
    } else {
        my $actual = $self->{cols}{$fabricante};
        $actual = $actual->get_sig_col() while defined $actual->get_sig_col();
        $actual->set_sig_col($nuevo);
    }
}

# ---------------------------------------------------------------
# CONSULTAR todos los fabricantes de un proveedor
# ---------------------------------------------------------------
sub consultar_por_proveedor {
    my ($self, $proveedor) = @_;
    unless (exists $self->{filas}{$proveedor}) {
        print "No hay datos para el proveedor: $proveedor\n";
        return;
    }
    print "\n--- Fabricantes asociados a: $proveedor ---\n";
    printf "%-25s %-10s\n", "Fabricante", "Cantidad Total";
    print "-" x 40 . "\n";

    my $actual = $self->{filas}{$proveedor};
    while (defined $actual) {
        printf "%-25s %-10d\n", $actual->get_col(), $actual->get_datos()->{cantidad};
        $actual = $actual->get_sig_fila();
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
    print "\n--- Matriz Dispersa (Proveedor x Fabricante) ---\n";
    for my $prov (sort keys %{ $self->{filas} }) {
        print "\nProveedor: $prov\n";
        my $actual = $self->{filas}{$prov};
        while (defined $actual) {
            printf "  Fabricante: %-20s | Cantidad total: %d\n",
                $actual->get_col(), $actual->get_datos()->{cantidad};
            $actual = $actual->get_sig_fila();
        }
    }
}

# Retorna lista de [proveedor, fabricante, cantidad] para la tabla GTK
sub todos_como_lista {
    my ($self) = @_;
    my @filas;
    for my $prov (sort keys %{ $self->{filas} }) {
        my $actual = $self->{filas}{$prov};
        while (defined $actual) {
            push @filas, [$prov, $actual->get_col(), $actual->get_datos()->{cantidad}];
            $actual = $actual->get_sig_fila();
        }
    }
    return @filas;
}

# ---------------------------------------------------------------
# GENERAR DOT para Graphviz
# ---------------------------------------------------------------
sub generar_dot {
    my ($self, $archivo) = @_;
    $archivo //= "reports/reporte_matriz.dot";

    open my $fh, '>', $archivo or do {
        print "No se pudo crear $archivo\n"; return;
    };

    print $fh "digraph MatrizDispersa {\n";
    print $fh "  rankdir=LR;\n";
    print $fh "  node [fontname=Arial fontsize=9];\n\n";

    if (!%{ $self->{filas} }) {
        print $fh "  vacio [label=\"Matriz vacia\" shape=plaintext];\n";
        print $fh "}\n";
        close $fh;
        return;
    }

    # Cabeceras columna (fabricantes)
    print $fh "  // fabricantes (columnas)\n";
    for my $fab (sort keys %{ $self->{cols} }) {
        my $id = "col_" . _esc($fab);
        print $fh "  $id [label=\"$fab\" shape=rectangle style=filled fillcolor=lightblue];\n";
    }

    # Cabeceras fila (proveedores) y nodos valor
    print $fh "\n  // proveedores (filas) y valores\n";
    for my $prov (sort keys %{ $self->{filas} }) {
        my $pid = "row_" . _esc($prov);
        print $fh "  $pid [label=\"$prov\" shape=rectangle style=filled fillcolor=lightyellow];\n";

        my $actual = $self->{filas}{$prov};
        while (defined $actual) {
            my $fab  = $actual->get_col();
            my $cant = $actual->get_datos()->{cantidad};
            my $vid  = "v_" . _esc($prov) . "_" . _esc($fab);
            my $fid  = "col_" . _esc($fab);

            print $fh "  $vid [label=\"Cant:\\n$cant\" shape=ellipse style=filled fillcolor=lightgreen];\n";
            print $fh "  $pid -> $vid;\n";
            print $fh "  $vid -> $fid;\n";

            $actual = $actual->get_sig_fila();
        }
    }

    print $fh "}\n";
    close $fh;

    (my $png = $archivo) =~ s/\.dot$/.png/;
    system("dot -Tpng \"$archivo\" -o \"$png\" 2>/dev/null");
    print "Reporte Matriz generado: $png\n";
    return $png;
}

sub _buscar_nodo {
    my ($self, $prov, $fab) = @_;
    return undef unless exists $self->{filas}{$prov};
    my $actual = $self->{filas}{$prov};
    while (defined $actual) {
        return $actual if $actual->get_col() eq $fab;
        $actual = $actual->get_sig_fila();
    }
    return undef;
}

sub _esc { my $s = $_[0]; $s =~ s/[^a-zA-Z0-9]/_/g; return $s }

1;
