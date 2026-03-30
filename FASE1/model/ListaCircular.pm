package ListaCircular;
use strict;
use warnings;
use Nodo;

# Lista circular simple de Proveedores
# Cada nodo contiene un objeto Proveedor
# El ultimo nodo apunta al primero
#
#  ┌────────────────────────────┐
#  ↓                            │
# [P1] -> [P2] -> [P3] -> [P4]─┘

sub new {
    my ($class) = @_;
    my $self = {
        primero => undef,
        ultimo  => undef,
        tamanio => 0,
    };
    bless $self, $class;
    return $self;
}

sub get_tamanio { $_[0]->{tamanio} }
sub esta_vacia  { !defined $_[0]->{primero} }

# ---------------------------------------------------------------
# AGREGAR proveedor (si no existe ya por NIT)
# ---------------------------------------------------------------
sub agregar {
    my ($self, $proveedor) = @_;

    # Evitar duplicados por NIT
    if ($self->buscar_por_nit($proveedor->get_nit())) {
        return 0;  # ya existe
    }

    my $nuevo = Nodo->new($proveedor);

    if ($self->esta_vacia()) {
        $nuevo->set_siguiente($nuevo);   # apunta a si mismo
        $self->{primero} = $nuevo;
        $self->{ultimo}  = $nuevo;
    } else {
        $nuevo->set_siguiente($self->{primero});  # el nuevo apunta al primero
        $self->{ultimo}->set_siguiente($nuevo);   # el anterior ultimo apunta al nuevo
        $self->{ultimo} = $nuevo;
    }

    $self->{tamanio}++;
    return 1;
}

# ---------------------------------------------------------------
# BUSCAR proveedor por NIT (retorna el objeto Proveedor o undef)
# ---------------------------------------------------------------
sub buscar_por_nit {
    my ($self, $nit) = @_;
    return undef if $self->esta_vacia();

    my $actual = $self->{primero};
    do {
        return $actual->get_dato() if $actual->get_dato()->get_nit() eq $nit;
        $actual = $actual->get_siguiente();
    } while ($actual != $self->{primero});

    return undef;
}

# ---------------------------------------------------------------
# LISTAR todos los proveedores con sus entregas
# ---------------------------------------------------------------
sub listar {
    my ($self) = @_;

    if ($self->esta_vacia()) {
        print "No hay proveedores registrados.\n";
        return;
    }

    my $actual = $self->{primero};
    my $i      = 1;

    do {
        my $p = $actual->get_dato();
        print "\n$i. " . $p->to_string() . "\n";

        my @entregas = @{ $p->get_entregas() };
        if (@entregas) {
            print "   Historial de entregas:\n";
            for my $e (@entregas) {
                print "   - Fecha: $e->{fecha} | Factura: $e->{factura} | Med: $e->{codigo_med} | Cant: $e->{cantidad}\n";
            }
        } else {
            print "   Sin entregas registradas.\n";
        }

        $actual = $actual->get_siguiente();
        $i++;
    } while ($actual != $self->{primero});
}

# ---------------------------------------------------------------
# GENERAR DOT para Graphviz
# ---------------------------------------------------------------
sub generar_dot {
    my ($self, $archivo) = @_;
    $archivo //= "reporte_proveedores.dot";

    open my $fh, ">", $archivo or do {
        print "No se pudo crear el archivo DOT.\n";
        return;
    };

    print $fh "digraph ListaCircular {\n";
    print $fh "  rankdir=LR;\n";
    print $fh "  node [fontname=Arial];\n\n";

    if ($self->esta_vacia()) {
        print $fh "  vacio [label=\"Sin proveedores\" shape=plaintext];\n";
        print $fh "}\n";
        close $fh;
        return;
    }

    my $actual = $self->{primero};
    my @nits;

    # Primero declarar los nodos de proveedores
    do {
        my $p   = $actual->get_dato();
        my $nit = $p->get_nit();
        my $nom = $p->get_nombre();
        $nom =~ s/"/\\"/g;

        my $n_entregas = scalar @{ $p->get_entregas() };
        print $fh "  \"$nit\" [label=\"$nom\\nNIT: $nit\" shape=rectangle style=filled fillcolor=lightblue];\n";

        # Nodos de entregas (lista vertical)
        my @entregas = @{ $p->get_entregas() };
        for my $j (0 .. $#entregas) {
            my $e   = $entregas[$j];
            my $eid = "${nit}_e$j";
            print $fh "  \"$eid\" [label=\"$e->{fecha}\\n$e->{codigo_med}\\nCant: $e->{cantidad}\" shape=rectangle style=filled fillcolor=lightyellow];\n";
        }

        push @nits, $nit;
        $actual = $actual->get_siguiente();
    } while ($actual != $self->{primero});

    # Flechas entre proveedores (circular)
    print $fh "\n  // lista circular de proveedores\n";
    my $n = scalar @nits;
    for my $i (0 .. $n - 1) {
        my $sig = ($i + 1) % $n;
        print $fh "  \"$nits[$i]\" -> \"$nits[$sig]\";\n";
    }

    # Flechas de proveedor a sus entregas (lista vertical)
    print $fh "\n  // listas de entregas\n";
    $actual = $self->{primero};
    do {
        my $p   = $actual->get_dato();
        my $nit = $p->get_nit();
        my @entregas = @{ $p->get_entregas() };

        if (@entregas) {
            print $fh "  \"$nit\" -> \"${nit}_e0\" [style=dashed];\n";
            for my $j (0 .. $#entregas - 1) {
                print $fh "  \"${nit}_e$j\" -> \"${nit}_e" . ($j+1) . "\";\n";
            }
        }

        $actual = $actual->get_siguiente();
    } while ($actual != $self->{primero});

    print $fh "}\n";
    close $fh;

    my $png = $archivo;
    $png =~ s/\.dot$/.png/;
    system("dot -Tpng $archivo -o $png");
    print "Reporte generado: $png\n";
}

1;
