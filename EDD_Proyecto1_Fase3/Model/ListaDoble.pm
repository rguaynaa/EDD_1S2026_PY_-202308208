package ListaDoble;
use strict;
use warnings;
use Nodo;

# Lista doblemente enlazada ordenada por codigo de medicamento
# NULL <- [ant|dato|sig] <-> [ant|dato|sig] <-> [ant|dato|sig] -> NULL

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
# INSERTAR ordenado por codigo
# ---------------------------------------------------------------
sub insertar {
    my ($self, $medicamento) = @_;
    my $nuevo = Nodo->new($medicamento);

    # Lista vacia
    if ($self->esta_vacia()) {
        $self->{primero} = $nuevo;
        $self->{ultimo}  = $nuevo;
        $self->{tamanio}++;
        return;
    }

    my $actual = $self->{primero};

    while ($actual) {
        my $codigo_actual = $actual->get_dato()->get_codigo();
        my $codigo_nuevo  = $medicamento->get_codigo();

        # Codigo ya existe -> no insertar duplicado
        if ($codigo_nuevo eq $codigo_actual) {
            print "Advertencia: ya existe medicamento con codigo $codigo_nuevo\n";
            return;
        }

        # Encontramos donde insertar (antes de actual)
        if ($codigo_nuevo lt $codigo_actual) {

            # Insertar al inicio
            if (!defined $actual->get_anterior()) {
                $nuevo->set_siguiente($actual);
                $actual->set_anterior($nuevo);
                $self->{primero} = $nuevo;

            # Insertar en medio
            } else {
                my $anterior = $actual->get_anterior();
                $anterior->set_siguiente($nuevo);
                $nuevo->set_anterior($anterior);
                $nuevo->set_siguiente($actual);
                $actual->set_anterior($nuevo);
            }

            $self->{tamanio}++;
            return;
        }

        $actual = $actual->get_siguiente();
    }

    # Insertar al final
    $self->{ultimo}->set_siguiente($nuevo);
    $nuevo->set_anterior($self->{ultimo});
    $self->{ultimo} = $nuevo;
    $self->{tamanio}++;
}

# ---------------------------------------------------------------
# BUSCAR por codigo  (retorna el objeto Medicamento o undef)
# ---------------------------------------------------------------
sub buscar {
    my ($self, $codigo) = @_;
    my $actual = $self->{primero};

    while ($actual) {
        my $cod = $actual->get_dato()->get_codigo();

        return $actual->get_dato() if $cod eq $codigo;

        # Como esta ordenado, si ya pasamos el codigo no existe
        last if $cod gt $codigo;

        $actual = $actual->get_siguiente();
    }
    return undef;
}

# ---------------------------------------------------------------
# BUSCAR por nombre  (busqueda lineal, sin orden por nombre)
# ---------------------------------------------------------------
sub buscar_por_nombre {
    my ($self, $nombre) = @_;
    my $actual = $self->{primero};

    while ($actual) {
        my $m = $actual->get_dato();
        return $m if lc($m->get_nombre()) eq lc($nombre);
        $actual = $actual->get_siguiente();
    }
    return undef;
}

# ---------------------------------------------------------------
# LISTAR todo el inventario
# ---------------------------------------------------------------
sub listar {
    my ($self) = @_;

    if ($self->esta_vacia()) {
        print "El inventario esta vacio.\n";
        return;
    }

    my $actual = $self->{primero};
    my $i = 1;

    while ($actual) {
        print "$i. " . $actual->get_dato()->to_string() . "\n";
        $actual = $actual->get_siguiente();
        $i++;
    }
    print "Total: " . $self->{tamanio} . " medicamentos.\n";
}

# ---------------------------------------------------------------
# LISTAR por laboratorio
# ---------------------------------------------------------------
sub listar_por_laboratorio {
    my ($self, $laboratorio) = @_;
    my $actual    = $self->{primero};
    my $encontrado = 0;

    while ($actual) {
        my $m = $actual->get_dato();
        if (lc($m->get_laboratorio()) eq lc($laboratorio)) {
            print $m->to_string() . "\n";
            $encontrado = 1;
        }
        $actual = $actual->get_siguiente();
    }

    print "No hay medicamentos de ese laboratorio.\n" unless $encontrado;
}

# ---------------------------------------------------------------
# GENERAR DOT para Graphviz
# ---------------------------------------------------------------
sub generar_dot {
    my ($self, $archivo) = @_;
    $archivo //= "reporte_inventario.dot";

    open my $fh, ">", $archivo or do {
        print "No se pudo crear el archivo DOT.\n";
        return;
    };

    print $fh "digraph ListaDoble {\n";
    print $fh "  rankdir=LR;\n";
    print $fh "  node [shape=record fontname=Arial];\n";
    print $fh "  edge [arrowhead=vee];\n\n";

    if ($self->esta_vacia()) {
        print $fh "  vacio [label=\"Lista vacia\" shape=plaintext];\n";
        print $fh "}\n";
        close $fh;
        return;
    }

    # Nodo HEAD
    print $fh "  HEAD [label=\"HEAD\" shape=plaintext];\n";

    my $actual = $self->{primero};
    my @nodos;

    while ($actual) {
        my $m     = $actual->get_dato();
        my $cod   = $m->get_codigo();
        my $nombre = $m->get_nombre();
        my $cant  = $m->get_cantidad();
        my $fecha = $m->get_fechaVencimiento();

        # Color segun stock
        my $color = $m->bajo_stock() ? "salmon" : "lightgreen";

        # Escapar caracteres especiales para DOT
        $nombre =~ s/"/\\"/g;

        print $fh "  \"$cod\" [label=\"{$cod | $nombre | Cant: $cant | Vence: $fecha}\" style=filled fillcolor=$color];\n";
        push @nodos, $cod;

        $actual = $actual->get_siguiente();
    }

    # Flechas hacia adelante
    print $fh "\n  // flechas adelante\n";
    print $fh "  HEAD -> \"$nodos[0]\";\n";
    for my $i (0 .. $#nodos - 1) {
        print $fh "  \"$nodos[$i]\" -> \"$nodos[$i+1]\";\n";
    }

    # Flechas hacia atras
    print $fh "\n  // flechas atras\n";
    for my $i (1 .. $#nodos) {
        print $fh "  \"$nodos[$i]\" -> \"$nodos[$i-1]\" [style=dashed color=gray];\n";
    }

    print $fh "}\n";
    close $fh;

    # Generar PNG con Graphviz
    my $png = $archivo;
    $png =~ s/\.dot$/.png/;
    system("dot -Tpng \"$archivo\" -o \"$png\" 2>/dev/null");
    print "Reporte generado: $png\n";

    return $png;
}

1;
