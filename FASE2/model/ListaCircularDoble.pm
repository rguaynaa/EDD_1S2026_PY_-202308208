package ListaCircularDoble;
use strict;
use warnings;
use Nodo;

# Lista Circular Doblemente Enlazada de Proveedores (FASE2)
# El ultimo nodo apunta al primero (circular)
# Cada nodo tiene anterior y siguiente

sub new {
    my ($class) = @_;
    return bless { primero => undef, tamanio => 0 }, $class;
}

sub get_tamanio { $_[0]->{tamanio} }
sub esta_vacia  { !defined $_[0]->{primero} }

# ---------------------------------------------------------------
# AGREGAR proveedor (sin duplicados por NIT)
# ---------------------------------------------------------------
sub agregar {
    my ($self, $proveedor) = @_;
    return 0 if $self->buscar_por_nit($proveedor->get_nit());

    my $nuevo = Nodo->new($proveedor);

    if ($self->esta_vacia()) {
        $nuevo->set_siguiente($nuevo);
        $nuevo->set_anterior($nuevo);
        $self->{primero} = $nuevo;
    } else {
        my $ultimo = $self->{primero}->get_anterior();
        $ultimo->set_siguiente($nuevo);
        $nuevo->set_anterior($ultimo);
        $nuevo->set_siguiente($self->{primero});
        $self->{primero}->set_anterior($nuevo);
    }

    $self->{tamanio}++;
    return 1;
}

# ---------------------------------------------------------------
# BUSCAR por NIT
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
# LISTAR todos los proveedores
# ---------------------------------------------------------------
sub listar {
    my ($self) = @_;
    if ($self->esta_vacia()) {
        print "No hay proveedores registrados.\n";
        return;
    }
    my $actual = $self->{primero};
    my $i = 1;
    do {
        my $p = $actual->get_dato();
        print "$i. " . $p->to_string() . "\n";
        my @ent = @{ $p->get_entregas() };
        for my $e (@ent) {
            if (ref $e->{items} eq 'ARRAY') {
                print "   Entrega " . $e->{factura} . " (" . $e->{fecha} . "): " . scalar(@{$e->{items}}) . " items\n";
            }
        }
        $actual = $actual->get_siguiente();
        $i++;
    } while ($actual != $self->{primero});
}

# Retorna array de todos los proveedores
sub todos {
    my ($self) = @_;
    return () if $self->esta_vacia();
    my @lista;
    my $actual = $self->{primero};
    do {
        push @lista, $actual->get_dato();
        $actual = $actual->get_siguiente();
    } while ($actual != $self->{primero});
    return @lista;
}

# ---------------------------------------------------------------
# GENERAR DOT para Graphviz
# ---------------------------------------------------------------
sub generar_dot {
    my ($self, $archivo) = @_;
    $archivo //= "reports/reporte_proveedores.dot";

    open my $fh, '>', $archivo or do {
        print "No se pudo crear $archivo\n"; return;
    };

    print $fh "digraph ListaCircularDoble {\n";
    print $fh "  rankdir=LR;\n";
    print $fh "  node [fontname=Arial fontsize=9];\n\n";

    if ($self->esta_vacia()) {
        print $fh "  vacio [label=\"Sin proveedores\" shape=plaintext];\n";
        print $fh "}\n";
        close $fh;
        return;
    }

    my @provs = $self->todos();
    my @ids;

    for my $p (@provs) {
        my $nit = $p->get_nit();
        my $nom = $p->get_nombre(); $nom =~ s/"/\\"/g;
        my $id  = "prov_" . _esc($nit);
        push @ids, $id;

        print $fh "  $id [label=\"$nom\\nNIT: $nit\" shape=rectangle style=filled fillcolor=lightblue];\n";

        # Nodos de entregas
        my @ent = @{ $p->get_entregas() };
        for my $j (0..$#ent) {
            my $e   = $ent[$j];
            my $eid = "${id}_e$j";
            my $items = ref $e->{items} ? scalar(@{ $e->{items} }) : 0;
            print $fh "  $eid [label=\"$e->{fecha}\\nFac: $e->{factura}\\nItems: $items\" shape=rectangle style=filled fillcolor=lightyellow];\n";
        }
    }

    # Flechas circulares dobles entre proveedores
    print $fh "\n  // lista circular doble\n";
    my $n = scalar @ids;
    for my $i (0..$n-1) {
        my $sig = ($i+1) % $n;
        print $fh "  $ids[$i] -> $ids[$sig];\n";
        print $fh "  $ids[$sig] -> $ids[$i] [style=dashed color=gray];\n";
    }

    # Flechas a entregas
    print $fh "\n  // entregas\n";
    for my $p (@provs) {
        my $id  = "prov_" . _esc($p->get_nit());
        my @ent = @{ $p->get_entregas() };
        if (@ent) {
            print $fh "  $id -> ${id}_e0 [style=dashed color=navy];\n";
            for my $j (0..$#ent-1) {
                print $fh "  ${id}_e$j -> ${id}_e" . ($j+1) . ";\n";
            }
        }
    }

    print $fh "}\n";
    close $fh;

    (my $png = $archivo) =~ s/\.dot$/.png/;
    system("dot -Tpng \"$archivo\" -o \"$png\" 2>/dev/null");
    print "Reporte proveedores generado: $png\n";
    return $png;
}

sub _esc { my $s = $_[0]; $s =~ s/[^a-zA-Z0-9]/_/g; return $s }

1;
